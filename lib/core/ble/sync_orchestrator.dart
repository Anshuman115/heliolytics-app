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
import 'package:heliolytics/features/ble_discovery/data/data_requester.dart';
import 'package:heliolytics/features/ble_discovery/data/session_store.dart';
import 'package:heliolytics/features/ble_discovery/domain/models/models.dart';

class SyncOrchestrator extends Notifier<SessionSnapshot> {
  late AuthKeyStorage _authStorage;
  late BleConnector _connector;
  SessionStore? _store;
  GattConnection? _gatt;
  EncryptedEndpoint? _huamiComms;
  bool _connecting = false;
  final List<String> _logs = [];
  final List<TypeCodeResult> _results = [];

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

    // Services list reply: [0x04, count(u16 LE), (endpoint u16 LE, encrypted u8)×N]
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

    // Record-counts reply
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
    final done = Completer<bool>();

    state = state.copyWith(state: SessionState.connecting);
    try {
      _gatt = await _connector.connect(remoteId);
    } catch (e) {
      _log('connect failed: $e');
      state = state.copyWith(
        state: SessionState.error,
        error: SessionError.gattFailed,
        lastErrorMessage: 'Connect failed: $e',
      );
      return;
    }

    final gatt = _gatt as StrapGattConnection;
    state = state.copyWith(state: SessionState.authenticating);

    final authKey = await _authStorage.readBytes();
    if (authKey == null) {
      _log('No auth key stored');
      return;
    }

    final auth = DeviceHandshake(
      authKey: authKey,
      log: (msg) => _log(msg),
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
      _log('auth failed');
      state = state.copyWith(
        state: SessionState.error,
        error: SessionError.authRejected,
        lastErrorMessage: 'Auth failed',
      );
      return;
    }

    _log('Auth SUCCESS — strap is authenticated');

    // ---- post-auth: comms + activity fetch (matches Huami protocol _postAuth) ----
    _huamiComms = EncryptedEndpoint(
      sessionKey: auth.sessionKey,
      sequence: auth.sequence ?? 0,
      log: (msg) => _log(msg),
      writeChunk: (c) => gatt.writeChunked(c),
      writeAck: (c) => gatt.writeNotify(c),
      onPayload: _handlePayload,
    );

    gatt.setNotifyHandler(_huamiComms!.onNotify);

    // Re-subscribe 0x0004/0x0005 after auth
    await gatt.resubscribeNotifications();

    // Wait for services list from strap
    _log('Waiting for services list ...');
    await Future.delayed(const Duration(seconds: 2));

    state = state.copyWith(state: SessionState.connected);

    _log('Auto-fetching all data types ...');
    await startFetch(
      typeCodes: allTypeCodes,
      fetchWindowHours: defaultFetchWindowHours,
      listenDurationSec: defaultListenDurationSec,
    );
  }

  Future<void> startFetch({
    required List<String> typeCodes,
    required int fetchWindowHours,
    required int listenDurationSec,
  }) async {
    if (state.state != SessionState.connected) return;
    final store = _store;
    if (store == null) return;

    final gatt = _gatt;
    if (gatt is! StrapGattConnection) return;

    state = state.copyWith(state: SessionState.fetching);
    _results.clear();

    final sessionId = await store.createSession(
      deviceMac: await _authStorage.readMac(),
      fetchWindowHours: fetchWindowHours,
      listenDurationSec: listenDurationSec,
      mode: SessionMode.fetchAndListen,
    );

    final since =
        DateTime.now().toUtc().subtract(Duration(hours: fetchWindowHours));
    _log('Fetch window: last ${fetchWindowHours}h since ${since.toIso8601String()}');

    final requester = DataRequester(gatt);
    final entries = <DumpEntry>[];

    for (final code in typeCodes) {
      final label = typeCodeLabels[code] ?? code;
      state = state.copyWith(currentTypeCode: code);
      _log('Fetching $code ($label) ...');

      try {
        final typeInt = int.parse(
          code.startsWith('0x') ? code.substring(2) : code,
          radix: 16,
        );
        final result = await requester.fetchType(typeInt, since);
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
