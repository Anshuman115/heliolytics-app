import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:heliolytics/core/ble/auth/auth_key_storage.dart';
import 'package:heliolytics/core/ble/ble_devices.dart';
import 'package:heliolytics/core/ble/connector.dart';
import 'package:heliolytics/core/ble/session_state.dart';
import 'package:heliolytics/core/ble/encrypted_endpoint.dart';
import 'package:heliolytics/core/ble/device_handshake.dart';
import 'package:heliolytics/core/constants.dart';
import 'package:heliolytics/core/utils/huami_time.dart';
import 'package:heliolytics/features/ble_discovery/data/data_requester.dart';
import 'package:heliolytics/features/ble_discovery/data/session_store.dart';
import 'package:heliolytics/features/ble_discovery/domain/models/models.dart';

class SyncOrchestrator extends Notifier<SessionSnapshot> {
  late AuthKeyStorage _authStorage;
  late BleConnector _connector;
  SessionStore? _store;
  bool _connecting = false;
  final List<String> _logs = [];
  final List<TypeCodeResult> _results = [];

  StrapGattConnection? _gatt;
  EncryptedEndpoint? _comms;
  StreamSubscription<List<int>>? _controlSub;
  StreamSubscription<List<int>>? _dataSub;

  @override
  SessionSnapshot build() {
    _authStorage = AuthKeyStorage(store: ref.read(authKeyStoreProvider));
    _connector = ref.read(bleConnectorProvider);
    _initAsync();
    return SessionSnapshot.initial;
  }

  void _log(String msg) {
    final ts = DateTime.now();
    final tsStr =
        '${ts.hour.toString().padLeft(2, '0')}:'
        '${ts.minute.toString().padLeft(2, '0')}:'
        '${ts.second.toString().padLeft(2, '0')}';
    _logs.add('[$tsStr] $msg');
    // ignore: avoid_print
    print(msg);
    state = state.copyWith(logs: List.unmodifiable(_logs));
  }

  void _handlePayload(int endpoint, Uint8List payload) {
    final hex = payload
        .map((b) => b.toRadixString(16).padLeft(2, '0'))
        .join();
    _log('[COMMS] endpoint 0x${endpoint.toRadixString(16).padLeft(4, '0')} '
        '(${payload.length}B): $hex');

    if (endpoint == 0x0000 && payload.length >= 3 && payload[0] == 0x04) {
      final bd = ByteData.sublistView(Uint8List.fromList(payload));
      final n = bd.getUint16(1, Endian.little);
      final services = <String>[];
      var has4b = false;
      var off = 3;
      for (var i = 0; i < n && off + 3 <= payload.length; i++) {
        final ep = bd.getUint16(off, Endian.little);
        final enc = payload[off + 2] != 0;
        if (ep == 0x004b) has4b = true;
        services.add('0x${ep.toRadixString(16).padLeft(4, '0')}${enc ? '*' : ''}');
        off += 3;
      }
      _log('[COMMS] SERVICES ($n) [*=encrypted]: ${services.join(' ')}');
      _log('[COMMS] activity-fetch service 0x004b: $has4b');
    }

    if (endpoint == 0x0016 && payload.length >= 15 &&
        payload[0] == 0x04 && payload[1] == 0x01) {
      final bd = ByteData.sublistView(Uint8List.fromList(payload));
      final a = bd.getUint32(3, Endian.little);
      final b = bd.getUint32(7, Endian.little);
      final c = bd.getUint32(11, Endian.little);
      _log('[COMMS] RECORD COUNTS: $a / $b / $c records pending');
    }
  }

  Future<void> _initAsync() async {
    _store = await ref.read(sessionStoreProvider.future);
    final hasKey = await _authStorage.hasKey();
    state = state.copyWith(
      state: hasKey ? SessionState.idle : SessionState.noAuthKey,
    );
    _log('App initialized. Auth key: ${hasKey ? "present" : "missing"}');
  }

  Future<void> saveAuthKey(String key) async {
    await _authStorage.save(key);
    state = state.copyWith(state: SessionState.idle);
    _log('Auth key saved (${key.length} chars)');
  }

  Future<void> clearAuthKey() async {
    await _authStorage.clear();
    _logs.clear();
    _results.clear();
    state = state.copyWith(
      state: SessionState.noAuthKey,
      logs: [],
      typeResults: [],
    );
  }

  Future<void> connect() async {
    if (state.state != SessionState.idle &&
        state.state != SessionState.error) return;
    if (_connecting) return;
    _connecting = true;
    if (state.state == SessionState.error) {
      state = state.copyWith(
        state: SessionState.idle,
        error: SessionError.none,
      );
    }

    final mac = await _authStorage.readMac();
    if (mac == null || mac.isEmpty) {
      _log('ERROR: No MAC address saved. Please scan for device first.');
      state = state.copyWith(
        state: SessionState.error,
        error: SessionError.scanFailed,
        lastErrorMessage: 'No strap MAC saved. Go back and scan.',
      );
      _connecting = false;
      return;
    }

    _log('Connecting to MAC $mac ...');
    await _connectAndAuth(mac);
    _connecting = false;
  }

  Future<void> saveAuthKeyAndMac(String key, String mac) async {
    await _authStorage.save(key);
    await _authStorage.saveMac(mac);
    state = state.copyWith(state: SessionState.idle);
    _log('Auth key + MAC saved');
  }

  Future<void> saveMacAndConnect(String mac) async {
    await _authStorage.saveMac(mac);
    _log('MAC stored: $mac');
    await connect();
  }

  Future<bool> hasSavedMac() => _authStorage.hasMac();

  Future<void> _connectAndAuth(String remoteId) async {
    state = state.copyWith(state: SessionState.connecting);

    // --- connect ---
    try {
      _gatt = (await _connector.connect(remoteId)) as StrapGattConnection;
    } catch (e) {
      _log('connect failed: $e');
      state = state.copyWith(
        state: SessionState.error,
        error: SessionError.gattFailed,
        lastErrorMessage: 'Connect failed: $e',
      );
      return;
    }

    final gatt = _gatt!;
    state = state.copyWith(state: SessionState.authenticating);

    // --- auth ---
    final authKey = await _authStorage.readBytes();
    if (authKey == null) {
      _log('No auth key stored');
      return;
    }

    final done = Completer<bool>();
    final auth = DeviceHandshake(
      authKey: authKey,
      log: (msg) => _log('[AUTH] $msg'),
      writeChunk: (chunk) async {
        await gatt.writeChunked(chunk);
      },
      onSuccess: () {
        if (!done.isCompleted) done.complete(true);
      },
      onFailure: (r) {
        if (!done.isCompleted) done.complete(false);
      },
    );

    // Route 0x0017 notifications to auth handler
    gatt.setNotifyHandler(auth.onNotify);

    await auth.start();
    final authed = await done.future.timeout(
      const Duration(seconds: 15),
      onTimeout: () {
        _log('auth timed out');
        return false;
      },
    );
    if (!authed) {
      _log('Auth FAILED');
      state = state.copyWith(
        state: SessionState.error,
        error: SessionError.authRejected,
        lastErrorMessage: 'Auth failed',
      );
      return;
    }

    _log('Auth SUCCESS');

    // --- post-auth: comms ---
    try {
      _comms = EncryptedEndpoint(
        sessionKey: auth.sessionKey,
        sequence: auth.sequence ?? 0,
        log: (msg) => _log('[COMMS] $msg'),
        writeChunk: (c) => gatt.writeChunked(c),
        writeAck: (c) => gatt.writeNotify(c),
        onPayload: _handlePayload,
      );
      _log('EncryptedEndpoint created');
    } catch (e) {
      _log('EncryptedEndpoint FAILED: $e');
      return;
    }

    // Switch 0x0017 from auth to comms
    gatt.setNotifyHandler(_comms!.onNotify);
    _log('0x0017 handler switched to comms');

    // --- post-auth: activity fetch chars ---
    try {
      await gatt.resubscribeNotifications();
      _log('0x0004/0x0005 re-subscribed');
    } catch (e) {
      _log('resubscribe FAILED: $e');
      return;
    }

    // Wait for strap services list
    _log('Waiting for services list (2s)...');
    await Future.delayed(const Duration(seconds: 2));

    state = state.copyWith(state: SessionState.connected);
    _log('Connected — starting fetch');

    // --- fetch all types ---
    await _fetchAllTypes();
  }

  Future<void> _fetchAllTypes() async {
    final gatt = _gatt;
    final store = _store;
    if (gatt == null || store == null) return;

    state = state.copyWith(state: SessionState.fetching);
    _results.clear();

    final sessionId = await store.createSession(
      deviceMac: await _authStorage.readMac(),
      fetchWindowHours: defaultFetchWindowHours,
      listenDurationSec: defaultListenDurationSec,
      mode: SessionMode.fetchAndListen,
    );

    final since =
        DateTime.now().toUtc().subtract(Duration(hours: defaultFetchWindowHours));
    _log('Fetch window: last ${defaultFetchWindowHours}h since ${since.toIso8601String()}');

    final entries = <DumpEntry>[];

    for (final code in allTypeCodes) {
      final label = typeCodeLabels[code] ?? code;
      state = state.copyWith(currentTypeCode: code);
      _log('Fetching $code ($label) ...');

      try {
        final typeInt = int.parse(
          code.startsWith('0x') ? code.substring(2) : code,
          radix: 16,
        );
        final result = await _fetchOneType(gatt, typeInt, since);
        final entry = result.entry;

        String status;
        String? rawHex;
        switch (entry.status) {
          case DumpStatus.ok:
            status = 'ok';
            rawHex = _bytesToHex(result.rawBytes);
            _log('  ✓ $code ($label): ${entry.samples} samples, ${entry.bytes} bytes');
            if (rawHex != null && rawHex.length > 200) {
              _log('  hex preview: ${rawHex.substring(0, 200)}...');
            } else if (rawHex != null) {
              _log('  hex: $rawHex');
            }
            break;
          case DumpStatus.empty:
            status = 'empty';
            _log('  — $code ($label): empty (no data on strap)');
            break;
          case DumpStatus.rejected:
            status = 'rejected';
            _log('  ✗ $code ($label): rejected (${entry.errorByte ?? "unknown"})');
            break;
          case DumpStatus.unknown:
            status = 'unknown';
            rawHex = _bytesToHex(result.rawBytes);
            _log('  ? $code ($label): unknown — ${result.rawBytes.length} bytes saved');
            break;
        }

        _results.add(TypeCodeResult(
          code: code,
          label: label,
          status: status,
          bytes: entry.bytes,
          samples: entry.samples,
          rawHex: rawHex,
          errorMsg: entry.errorByte,
        ));
        state = state.copyWith(typeResults: List.unmodifiable(_results));

        if (result.rawBytes.isNotEmpty) {
          await store.appendBytes(sessionId, code, result.rawBytes);
        }
        entries.add(entry);
      } catch (e) {
        _log('  ✗ $code ($label): ERROR — $e');
        _results.add(TypeCodeResult(
          code: code,
          label: label,
          status: 'error',
          errorMsg: e.toString(),
        ));
        state = state.copyWith(typeResults: List.unmodifiable(_results));
        entries.add(DumpEntry(
          code: code,
          status: DumpStatus.unknown,
          samples: 0,
          bytes: 0,
        ));
      }
    }

    await store.writeCatalogJson(SessionCatalog(
      sessionId: sessionId,
      chunked: entries,
      unsolicited: const [],
    ));

    final withData = _results.where((r) => r.status == 'ok').length;
    final empty = _results.where((r) => r.status == 'empty').length;
    final rejected = _results.where((r) => r.status == 'rejected').length;
    final errors = _results.where((r) => r.status == 'error').length;
    _log('═══ FETCH COMPLETE ═══');
    _log('  $withData with data, $empty empty, $rejected rejected, $errors errors');
    _log('  Session: $sessionId');

    state = state.copyWith(
      state: SessionState.idle,
      currentTypeCode: null,
      lastSession: await store.readSessionJson(sessionId),
    );
  }

  Future<FetchResult> _fetchOneType(
    StrapGattConnection gatt,
    int typeCode,
    DateTime since,
  ) async {
    const response = 0x10;
    const cmdStartDate = 0x01;
    const cmdFetchData = 0x02;
    const cmdAck = 0x03;
    const ackKeep = 0x09;

    final data = BytesBuilder();
    int lastCounter = -1;
    int rounds = 0;
    String status = 'rejected';

    final controlDone = Completer<void>();
    final controlBuf = <Uint8List>[];

    final controlSub = gatt.controlStream.listen((p) {
      controlBuf.add(Uint8List.fromList(p));
    });

    final dataSub = gatt.dataStream.listen((p) {
      if (p.isEmpty) return;
      final counter = p[0];
      lastCounter = counter;
      final payload = p.sublist(1);
      if (payload.isNotEmpty) data.add(payload);
      rounds++;
    });

    // Send start command
    final startCmd = [
      cmdStartDate,
      typeCode,
      ...HuamiTime.fromDateTime(since),
    ];
    await gatt.writeControl(startCmd);

    // Wait for control reply (5s)
    await Future.delayed(const Duration(seconds: 5));

    // Process control replies
    await controlSub.cancel();
    for (final p in controlBuf) {
      if (p.length < 3 || p[0] != response) continue;
      final cmd = p[1];
      final st = p[2];
      if (cmd == cmdStartDate) {
        if (st != 0x01) {
          status = 'rejected';
          break;
        }
        // Parse expected count
        if (p.length >= 7) {
          final expected = ByteData.sublistView(Uint8List.fromList(p), 3, 7)
              .getUint32(0, Endian.little);
          if (expected == 0) {
            status = 'empty';
            await gatt.writeControl([cmdAck, ackKeep]);
            break;
          }
        }
        status = 'ok';
        await gatt.writeControl([cmdFetchData]);
        // Wait for data (15s)
        await Future.delayed(const Duration(seconds: 15));
        await gatt.writeControl([cmdAck, ackKeep]);
      }
    }
    await dataSub.cancel();

    final raw = data.toBytes();
    final hexCode = '0x${typeCode.toRadixString(16).padLeft(2, '0').toUpperCase()}';
    return FetchResult(
      entry: DumpEntry(
        code: hexCode,
        status: _parseDumpStatus(status),
        samples: raw.length ~/ 4,
        bytes: raw.length,
        file: '${hexCode}_raw.bin',
      ),
      rawBytes: raw.toList(),
    );
  }

  DumpStatus _parseDumpStatus(String s) {
    switch (s) {
      case 'ok':
        return DumpStatus.ok;
      case 'empty':
        return DumpStatus.empty;
      default:
        return DumpStatus.rejected;
    }
  }

  String? _bytesToHex(List<int> bytes) {
    if (bytes.isEmpty) return null;
    final buf = StringBuffer();
    for (final b in bytes) {
      buf.write(b.toRadixString(16).padLeft(2, '0'));
    }
    return buf.toString();
  }
}

final syncOrchestratorProvider =
    NotifierProvider<SyncOrchestrator, SessionSnapshot>(SyncOrchestrator.new);
