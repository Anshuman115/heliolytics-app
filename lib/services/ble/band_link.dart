import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:heliolytics/services/ble/band_link_port.dart';
import 'package:heliolytics/services/ble/type_sync_engine.dart';
import 'package:heliolytics/services/ble/sync_page_anchor.dart';
import 'package:heliolytics/services/ble/encrypted_endpoint.dart';
import 'package:heliolytics/services/ble/device_handshake.dart';
import 'package:heliolytics/services/ble/live_hr_stream.dart';

/// BLE connect, ZeppOS auth, and activity-fetch for the Helio Strap.
/// The caller provides a [log] callback and sets [onUpdate] to react to data.
class BandLink implements BandLinkPort {
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
  BluetoothCharacteristic? _hrChar;

  DeviceHandshake? auth;
  EncryptedEndpoint? comms;
  TypeSyncEngine? fetcher;
  LiveHrStream? _liveHr;
  @override
  int? batteryPercent;

  void Function(Uint8List)? _notifyHandler;
  StreamSubscription<List<int>>? _notifySub;
  StreamSubscription<List<int>>? _controlSub;
  StreamSubscription<List<int>>? _dataSub;
  StreamSubscription<BluetoothConnectionState>? _connSub;

  @override
  Future<bool> connectAndAuth({
    required String mac,
    required Uint8List authKey,
    bool commsOnly = false,
  }) async {
    final done = Completer<bool>();
    _device = BluetoothDevice.fromId(mac);

    var physicallyConnected = false;
    _connSub = _device!.connectionState.listen((s) {
      log('• connection: ${s.name}');
      if (s == BluetoothConnectionState.connected) physicallyConnected = true;
      if (s == BluetoothConnectionState.disconnected &&
          physicallyConnected &&
          !done.isCompleted) {
        log('• disconnected before auth completed');
        done.complete(false);
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
    await _readBattery(services);
    for (final s in services) {
      for (final c in s.characteristics) {
        final u = c.uuid.str.toLowerCase();
        if (u == writeUuid)   _write   = c;
        if (u == notifyUuid)  _notify  = c;
        if (u == controlUuid) _control = c;
        if (u == dataUuid)    _data    = c;
        if (u.contains('2a37')) _hrChar = c;
      }
    }
    if (_write == null || _notify == null) {
      log('✗ chunked chars not found');
      return false;
    }
    log('char resolution: write=${_write != null}, notify=${_notify != null}, control=${_control != null}, data=${_data != null}, hrChar=${_hrChar != null}');
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
    if (!authed) {
      await disconnect();
      return false;
    }

    await _postAuth(commsOnly: commsOnly);
    return true;
  }

  Future<void> _postAuth({bool commsOnly = false}) async {
    comms = EncryptedEndpoint(
      sessionKey: auth!.sessionKey,
      sequence: auth!.sequence ?? 0,
      log: log,
      writeChunk: (c) => _write!.write(c, withoutResponse: true),
      writeAck:   (c) => _notify!.write(c, withoutResponse: true),
      onPayload: _handlePayload,
    );
    _notifyHandler = (v) => comms!.onNotify(v);

    if (commsOnly) {
      log('✓ post-auth comms ready');
      onUpdate?.call();
      return;
    }

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

    _liveHr = LiveHrStream(comms: comms!, hrChar: _hrChar, log: log);
    if (_hrChar != null) {
      log('✓ live HR char found');
    } else {
      log('• live HR char not found — streaming unavailable');
    }

    log('✓ post-auth setup complete — ready to fetch');
    onUpdate?.call();
  }

  /// Fetch one type code, returns raw bytes.
  /// Probes first — if expected packets > [maxExpected], skips the download
  /// and returns the packet count as a 4-byte LE integer (for logging).
  /// This prevents 0x07 GPS / other huge types from hanging the scan.
  @override
  Future<TypeFetchResult> fetchCode(
    int code,
    DateTime since,
  ) async {
    final f = fetcher;
    if (f == null) {
      return (
        raw: Uint8List(0),
        expected: -1,
        skipped: false,
        roundStart: null,
        roundSegments: <SyncPageAnchor>[],
      );
    }

    final isWorkout = code == 0x05;
    await f.fetchType(
      code,
      since,
      probeOnly: false,
      maxRounds: isWorkout ? 100 : 400,
      timeout: isWorkout
          ? const Duration(seconds: 150)
          : const Duration(days: 7),
    );
    final expected = f.lastExpected;
    final roundStart = f.firstRoundStart;
    final roundSegments = List<SyncPageAnchor>.from(f.roundSegments);

    if (expected < 0) {
      return (
        raw: Uint8List(0),
        expected: expected,
        skipped: false,
        roundStart: null,
        roundSegments: roundSegments,
      );
    }
    // expected==0 on the last page is normal; lastRaw still holds all rounds.
    return (
      raw: f.lastRaw,
      expected: expected,
      skipped: false,
      roundStart: roundStart,
      roundSegments: roundSegments,
    );
  }

  /// Fetch a single type code for the raw dump diagnostic.
  /// Unlike [fetchCode] (used by normal sync), this method:
  ///   - Accepts a per-code [timeout] (default 15s) to handle silent codes
  ///   - Uses the engine's internal timeout which sends ACK on expiry
  ///   - Has no round limit to allow full data download
  ///   - Does NOT affect normal sync behavior
  Future<TypeFetchResult> dumpCode(
    int code,
    DateTime since, {
    Duration timeout = const Duration(seconds: 15),
  }) async {
    final f = fetcher;
    if (f == null) {
      return (
        raw: Uint8List(0),
        expected: -1,
        skipped: false,
        roundStart: null,
        roundSegments: <SyncPageAnchor>[],
      );
    }

    await f.fetchType(
      code,
      since,
      probeOnly: false,
      maxRounds: 9999,
      timeout: timeout,
    );
    final expected = f.lastExpected;
    final roundStart = f.firstRoundStart;
    final roundSegments = List<SyncPageAnchor>.from(f.roundSegments);

    if (expected < 0) {
      return (
        raw: Uint8List(0),
        expected: expected,
        skipped: false,
        roundStart: null,
        roundSegments: roundSegments,
      );
    }
    return (
      raw: f.lastRaw,
      expected: expected,
      skipped: false,
      roundStart: roundStart,
      roundSegments: roundSegments,
    );
  }

  @override
  Future<void> startLiveHeartRate() => _liveHr?.start() ?? Future.value();

  @override
  Future<void> stopLiveHeartRate() => _liveHr?.stop() ?? Future.value();

  @override
  Stream<int>? get liveBpmStream => _liveHr?.bpmStream;

  @override
  bool get isLiveHeartRateActive => _liveHr?.isRunning ?? false;

  /// True when post-auth encrypted comms are ready on an active GATT link.
  bool get isCommsReady => comms != null && (_device?.isConnected ?? false);

  /// Send a payload on a ZeppOS chunked endpoint (post-auth).
  Future<bool> sendEndpointPayload(
    int endpoint,
    List<int> payload, {
    bool encrypt = false,
  }) async {
    final c = comms;
    if (c == null) {
      log('✗ comms not ready');
      return false;
    }
    await c.send(endpoint, Uint8List.fromList(payload), encrypt: encrypt);
    return true;
  }

  void _handlePayload(int endpoint, Uint8List payload) {
    _liveHr?.onEndpointPayload(endpoint, payload);
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

  Future<void> _readBattery(List<BluetoothService> services) async {
    // Use substring match — the strap exposes 0x2A19 under a vendor service
    // UUID, not the standard 0x180F, so an exact service-level match fails.
    BluetoothCharacteristic? batteryChar;
    for (final s in services) {
      for (final c in s.characteristics) {
        if (c.uuid.str.toLowerCase().contains('2a19')) {
          batteryChar = c;
          break;
        }
      }
      if (batteryChar != null) break;
    }

    if (batteryChar == null) {
      log('• battery char (2A19) not found in any service');
      return;
    }

    try {
      final v = await batteryChar.read();
      if (v.isNotEmpty && v[0] >= 0 && v[0] <= 100) {
        batteryPercent = v[0];
        log('• battery $batteryPercent%');
      }
    } catch (e) {
      log('• battery read failed: $e');
    }
  }

  @override
  Future<void> disconnect() async {
    await _liveHr?.stop();
    _liveHr?.dispose();
    _liveHr = null;
    await _notifySub?.cancel();
    await _controlSub?.cancel();
    await _dataSub?.cancel();
    await _connSub?.cancel();
    try { await _device?.disconnect(); } catch (_) {}
  }
}
