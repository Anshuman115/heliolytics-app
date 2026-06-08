import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:heliolytics/core/ble/fetch/type_sync_engine.dart';
import 'package:heliolytics/core/ble/protocol/encrypted_endpoint.dart';
import 'package:heliolytics/core/ble/auth/device_handshake.dart';

// ─── Strap Client ─────────────────────────────────────────────────────────
// Top-level BLE client for the Helio strap. Owns the BluetoothDevice,
// drives the auth handshake, wires up all GATT subscriptions, and exposes
// fetchCode() for the session controller to call per type code.
//
// Pure Dart — no Riverpod, no UI state. The caller provides a [log] callback
// and reacts to data via [onUpdate].
class BandLink {
  // GATT characteristic UUIDs
  static const String writeUuid   = '00000016-0000-3512-2118-0009af100700';
  static const String notifyUuid  = '00000017-0000-3512-2118-0009af100700';
  static const String controlUuid = '00000004-0000-3512-2118-0009af100700';
  static const String dataUuid    = '00000005-0000-3512-2118-0009af100700';
  static const String batteryUuid = '00000006-0000-3512-2118-0009af100700';

  final void Function(String) log;
  void Function()? onUpdate;
  BandLink(this.log);

  BluetoothDevice? _device;
  BluetoothCharacteristic? _write;
  BluetoothCharacteristic? _notify;
  BluetoothCharacteristic? _control;
  BluetoothCharacteristic? _data;
  BluetoothCharacteristic? _battery;

  DeviceHandshake? auth;
  EncryptedEndpoint? comms;
  TypeSyncEngine? fetcher;

  void Function(Uint8List)? _notifyHandler;
  StreamSubscription<List<int>>? _notifySub;
  StreamSubscription<List<int>>? _controlSub;
  StreamSubscription<List<int>>? _dataSub;
  StreamSubscription<BluetoothConnectionState>? _connSub;
  StreamSubscription<List<int>>? _batterySub;

  // ─── Connect + Auth ──────────────────────────────────────────────────────

  Future<bool> connectAndAuth({
    required String mac,
    required Uint8List authKey,
  }) async {
    final done = Completer<bool>();
    _device = BluetoothDevice.fromId(mac);

    _connSub = _device!.connectionState.listen((s) {
      log('• connection: ${s.name}');
      if (s == BluetoothConnectionState.disconnected && !done.isCompleted) {
        log('• disconnected before auth completed');
      }
    });

    log('→ connecting to $mac');
    try {
      await _device!.connect(
        timeout: const Duration(seconds: 20),
        autoConnect: false,
      );
    } catch (e) {
      log('✗ connect failed: $e');
      return false;
    }
    log('✓ connected');

    try {
      // 247 = max BLE 4.2 ATT payload. Larger MTU = fewer chunks per message = faster transfer.
      final mtu = await _device!.requestMtu(247);
      log('• MTU = $mtu');
    } catch (e) {
      log('• MTU request skipped: $e');
    }

    log('→ discovering services');
    final services = await _device!.discoverServices();
    for (final s in services) {
      for (final c in s.characteristics) {
        final u = c.uuid.str.toLowerCase();
        if (u == writeUuid)   _write   = c;
        if (u == notifyUuid)  _notify  = c;
        if (u == controlUuid) _control = c;
        if (u == dataUuid)    _data    = c;
        if (u == batteryUuid) {
          _battery = c;
          log('🔋 Battery char: read=${c.properties.read} notify=${c.properties.notify}');
        }
      }
    }
    if (_write == null || _notify == null) {
      log('✗ chunked chars not found');
      return false;
    }
    log('✓ found chunked chars');

    auth = DeviceHandshake(
      authKey: authKey,
      log: log,
      writeChunk: (chunk) async {
        await _write!.write(chunk, withoutResponse: true);
      },
      onSuccess: () {
        if (!done.isCompleted) done.complete(true);
      },
      onFailure: (r) {
        if (!done.isCompleted) done.complete(false);
      },
    );

    // Route char 0x0017 notifications through _notifyHandler.
    // During auth it points to DeviceHandshake.onNotify (handles the handshake).
    // After auth (_postAuth) it is swapped to EncryptedEndpoint.onNotify (handles
    // all post-auth encrypted frames). The indirection means we never need to
    // re-subscribe to the characteristic — just swap the handler.
    _notifyHandler = auth!.onNotify;
    await _notify!.setNotifyValue(true);
    _notifySub = _notify!.onValueReceived.listen((v) {
      _notifyHandler?.call(Uint8List.fromList(v));
    });

    log('→ starting handshake');
    await auth!.start();

    final authed = await done.future.timeout(
      const Duration(seconds: 15),
      onTimeout: () {
        log('✗ handshake timed out');
        return false;
      },
    );
    if (!authed) return false;

    await _postAuth();
    return true;
  }

  Future<void> _postAuth() async {
    comms = EncryptedEndpoint(
      sessionKey: auth!.sessionKey,
      sequence: auth!.sequence ?? 0,
      log: log,
      writeChunk: (c) => _write!.write(c, withoutResponse: true),
      writeAck:   (c) => _notify!.write(c, withoutResponse: true),
      onPayload: _handlePayload,
    );
    _notifyHandler = (v) => comms!.onNotify(v);

    if (_control == null || _data == null) {
      log('✗ activity chars not found');
      return;
    }

    fetcher = TypeSyncEngine(
      (cmd) => _control!.write(cmd, withoutResponse: true),
      log: log,
    );
    await _control!.setNotifyValue(true);
    _controlSub = _control!.onValueReceived.listen((v) {
      fetcher!.onControl(Uint8List.fromList(v));
    });
    await _data!.setNotifyValue(true);
    _dataSub = _data!.onValueReceived.listen((v) {
      fetcher!.onData(Uint8List.fromList(v));
    });

    log('✓ post-auth setup complete — ready to fetch');
    await _readBattery();
    onUpdate?.call();
  }

  Future<void> _readBattery() async {
    if (_battery == null) {
      log('🔋 Battery char (0006) not found');
      return;
    }
    if (_battery!.properties.notify) {
      try {
        await _batterySub?.cancel();
        await _battery!.setNotifyValue(true);
        _batterySub = _battery!.onValueReceived.listen((v) {
          final val = Uint8List.fromList(v);
          if (val.length >= 3) {
            final level = val[1];
            final status = val[2] == 1 ? 'charging' : 'normal';
            log('🔋 Battery: $level% ($status)');
          }
        });
        log('🔋 Subscribed to battery notifications');
      } catch (e) {
        log('🔋 Failed to subscribe to battery: $e');
      }
    }
    if (_battery!.properties.read) {
      try {
        final val = await _battery!.read();
        if (val.length >= 3) {
          final level = val[1];
          final status = val[2] == 1 ? 'charging' : 'normal';
          log('🔋 Battery (read): $level% ($status)');
        }
      } catch (e) {
        log('🔋 Failed to read battery: $e');
      }
    }
  }

  // ─── Fetch ───────────────────────────────────────────────────────────────

  /// Fetch one type code over [since] and return all raw bytes.
  /// Every code gets maxRounds=400. No timeout — device always replies.
  Future<({Uint8List raw, int expected, bool skipped})> fetchCode(
    int code,
    DateTime since,
  ) async {
    final f = fetcher;
    if (f == null) return (raw: Uint8List(0), expected: -1, skipped: false);

    await f.fetchType(code, since,
        probeOnly: false,
        maxRounds: 400);
    final expected = f.lastExpected;

    // expected < 0  → device rejected the request (unsupported code or bad status)
    // expected == 0 → device accepted but has no records in the window
    // expected > 0  → data transferred; f.lastRaw holds the raw bytes
    if (expected < 0) return (raw: Uint8List(0), expected: expected, skipped: false);
    if (expected == 0) return (raw: Uint8List(0), expected: 0, skipped: false);
    return (raw: f.lastRaw, expected: expected, skipped: false);
  }

  // ─── Unsolicited payload handler ─────────────────────────────────────────

  void _handlePayload(int endpoint, Uint8List payload) {
    final hex = payload.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    log('← endpoint 0x${endpoint.toRadixString(16).padLeft(4, '0')} '
        '(${payload.length}B): $hex');

    // Record count reply (endpoint 0x0016, cmd 0x04 0x01)
    if (endpoint == 0x0016 && payload.length >= 15 &&
        payload[0] == 0x04 && payload[1] == 0x01) {
      final bd = ByteData.sublistView(payload);
      final a = bd.getUint32(3, Endian.little);
      final b = bd.getUint32(7, Endian.little);
      final c = bd.getUint32(11, Endian.little);
      log('✓ RECORD COUNTS — $a / $b / $c records pending');
    }
    // Service list reply (endpoint 0x0000, cmd 0x04).
    // Each entry is 3 bytes: 2-byte LE endpoint ID + 1-byte encryption flag.
    // 0x004b = "Fetch History" endpoint — must be present for activity fetch to work.
    if (endpoint == 0x0000 && payload.length >= 3 && payload[0] == 0x04) {
      final bd = ByteData.sublistView(payload);
      final n = bd.getUint16(1, Endian.little);
      var off = 3;
      final services = <String>[];
      var has4b = false;
      for (var i = 0; i < n && off + 3 <= payload.length; i++) {
        final ep = bd.getUint16(off, Endian.little);
        final enc = payload[off + 2] != 0;
        if (ep == 0x004b) has4b = true;
        services.add('0x${ep.toRadixString(16).padLeft(4, '0')}${enc ? '*' : ''}');
        off += 3;
      }
      log('✓ SERVICES ($n): ${services.join(' ')}');
      log('  0x004b supported: $has4b');
    }
  }

  // ─── Disconnect ──────────────────────────────────────────────────────────

  Future<void> disconnect() async {
    await _notifySub?.cancel();
    await _controlSub?.cancel();
    await _dataSub?.cancel();
    await _connSub?.cancel();
    await _batterySub?.cancel();
    try { await _device?.disconnect(); } catch (_) {}
  }
}
