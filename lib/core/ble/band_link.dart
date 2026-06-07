import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:heliolytics/core/ble/type_sync_engine.dart';
import 'package:heliolytics/core/ble/encrypted_endpoint.dart';
import 'package:heliolytics/core/ble/device_handshake.dart';

/// Pure Dart — no Riverpod, no abstractions.
/// The caller provides a [log] callback and sets [onUpdate] to react to data.
class BandLink {
  static const String writeUuid  = '00000016-0000-3512-2118-0009af100700';
  static const String notifyUuid = '00000017-0000-3512-2118-0009af100700';
  static const String controlUuid = '00000004-0000-3512-2118-0009af100700';
  static const String dataUuid   = '00000005-0000-3512-2118-0009af100700';

  final void Function(String) log;
  void Function()? onUpdate;
  BandLink(this.log);

  BluetoothDevice? _device;
  BluetoothCharacteristic? _write;
  BluetoothCharacteristic? _notify;
  BluetoothCharacteristic? _control;
  BluetoothCharacteristic? _data;

  DeviceHandshake? auth;
  EncryptedEndpoint? comms;
  TypeSyncEngine? fetcher;

  void Function(Uint8List)? _notifyHandler;
  StreamSubscription<List<int>>? _notifySub;
  StreamSubscription<List<int>>? _controlSub;
  StreamSubscription<List<int>>? _dataSub;
  StreamSubscription<BluetoothConnectionState>? _connSub;

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
    onUpdate?.call();
  }

  /// Fetch one type code, returns raw bytes.
  /// Probes first — if expected packets > [maxExpected], skips the download
  /// and returns the packet count as a 4-byte LE integer (for logging).
  /// This prevents 0x07 GPS / other huge types from hanging the scan.
  Future<({Uint8List raw, int expected, bool skipped})> fetchCode(
    int code,
    DateTime since,
  ) async {
    final f = fetcher;
    if (f == null) return (raw: Uint8List(0), expected: -1, skipped: false);

    // Only skip permanently-huge known dumps (debug logs / raw PPG) that
    // would take hours and provide no structured health data.
    const skipCodes = {0x07, 0x58}; // debug logs, raw PPG dump
    if (skipCodes.contains(code)) {
      // Probe to get count for logging, then skip
      await f.fetchType(code, since,
          probeOnly: true, timeout: const Duration(milliseconds: 1500));
      final expected = f.lastExpected;
      log('  skipping 0x${code.toRadixString(16)}: $expected pkts (debug/raw dump)');
      return (raw: Uint8List(0), expected: expected, skipped: true);
    }

    // All other codes: go straight to full fetch, no probe, no cap, no timeout.
    // Probe-then-fetch causes double round-trip which confuses the strap stream.
    await f.fetchType(code, since,
        probeOnly: false,
        maxRounds: 9999,
        timeout: const Duration(hours: 24));
    final expected = f.lastExpected;

    if (expected < 0) return (raw: Uint8List(0), expected: expected, skipped: false);
    if (expected == 0) return (raw: Uint8List(0), expected: 0, skipped: false);
    return (raw: f.lastRaw, expected: expected, skipped: false);
  }

  void _handlePayload(int endpoint, Uint8List payload) {
    final hex = payload.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    log('← endpoint 0x${endpoint.toRadixString(16).padLeft(4, '0')} '
        '(${payload.length}B): $hex');

    if (endpoint == 0x0016 && payload.length >= 15 &&
        payload[0] == 0x04 && payload[1] == 0x01) {
      final bd = ByteData.sublistView(payload);
      final a = bd.getUint32(3, Endian.little);
      final b = bd.getUint32(7, Endian.little);
      final c = bd.getUint32(11, Endian.little);
      log('✓ RECORD COUNTS — $a / $b / $c records pending');
    }
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

  Future<void> disconnect() async {
    await _notifySub?.cancel();
    await _controlSub?.cancel();
    await _dataSub?.cancel();
    await _connSub?.cancel();
    try { await _device?.disconnect(); } catch (_) {}
  }
}
