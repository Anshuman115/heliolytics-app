import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:heliolytics/core/ble/auth/auth_key_storage.dart';
import 'package:heliolytics/core/ble/ble_devices.dart';
import 'package:heliolytics/core/ble/connector.dart';
import 'package:heliolytics/core/ble/session_state.dart';
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

  @override
  SessionSnapshot build() {
    _authStorage = AuthKeyStorage(store: ref.read(authKeyStoreProvider));
    _connector = ref.read(bleConnectorProvider);
    _initAsync();
    return SessionSnapshot.initial;
  }

  Future<void> _initAsync() async {
    _store = await ref.read(sessionStoreProvider.future);
    final hasKey = await _authStorage.hasKey();
    state = state.copyWith(
      state: hasKey ? SessionState.idle : SessionState.noAuthKey,
    );
  }

  Future<void> saveAuthKey(String key) async {
    await _authStorage.save(key); // throws FormatException on invalid
    state = state.copyWith(state: SessionState.idle);
  }

  Future<void> clearAuthKey() async {
    await _authStorage.clear();
    state = state.copyWith(state: SessionState.noAuthKey);
  }

  /// Connect directly by MAC address — no scanning needed.
  /// The strap MAC is saved during setup alongside the auth key.
  Future<void> connect() async {
    if (state.state != SessionState.idle && state.state != SessionState.error) return;
    if (state.state == SessionState.error) {
      state = state.copyWith(state: SessionState.idle, error: SessionError.none);
    }

    final mac = await _authStorage.readMac();
    if (mac == null || mac.isEmpty) {
      state = state.copyWith(
        state: SessionState.error,
        error: SessionError.scanFailed,
        lastErrorMessage: 'No strap MAC address saved. Go back and enter it.',
      );
      return;
    }

    // ignore: avoid_print
    print('[SESSION] connecting directly to MAC $mac');
    await _connectAndAuth(mac);
  }

  /// Save both auth key and MAC address together (called from setup screen).
  Future<void> saveAuthKeyAndMac(String key, String mac) async {
    await _authStorage.save(key);
    await _authStorage.saveMac(mac);
    state = state.copyWith(state: SessionState.idle);
  }

  /// Store MAC picked from scan screen, then connect immediately.
  Future<void> saveMacAndConnect(String mac) async {
    await _authStorage.saveMac(mac);
    await connect();
  }

  Future<bool> hasSavedMac() => _authStorage.hasMac();

  Future<void> _connectAndAuth(String remoteId) async {
    state = state.copyWith(state: SessionState.connecting);
    try {
      // ignore: avoid_print
      print('[SESSION] GATT connecting to $remoteId');
      _gatt = await _connector.connect(remoteId);
      // ignore: avoid_print
      print('[SESSION] GATT connected');
    } catch (e) {
      // ignore: avoid_print
      print('[SESSION] GATT failed: $e');
      state = state.copyWith(
        state: SessionState.error,
        error: SessionError.gattFailed,
        lastErrorMessage: 'Connect failed: $e',
      );
      return;
    }
    state = state.copyWith(state: SessionState.authenticating);
    try {
      // ignore: avoid_print
      print('[SESSION] starting ECDH auth');
      await _runEcdhAuth();
      // ignore: avoid_print
      print('[SESSION] auth SUCCESS');
      state = state.copyWith(state: SessionState.connected);
    } catch (e) {
      // ignore: avoid_print
      print('[SESSION] auth FAILED: $e');
      state = state.copyWith(
        state: SessionState.error,
        error: SessionError.authRejected,
        lastErrorMessage: 'Auth failed: $e',
      );
      return;
    }

    // Auth succeeded — auto-fetch data immediately.
    startFetch(
      typeCodes: [...knownTypeCodes, '0x26'],
      fetchWindowHours: defaultFetchWindowHours,
      listenDurationSec: defaultListenDurationSec,
    );
  }

  /// ZeppOS ECDH auth handshake over char 0x0016/0x0017.
  Future<void> _runEcdhAuth() async {
    final authKey = await _authStorage.readBytes();
    if (authKey == null) throw StateError('No auth key stored');

    final gatt = _gatt;
    if (gatt is! StrapGattConnection) {
      // In tests, _FakeGatt is used — skip real auth in that case.
      throw StateError(
          'GattConnection is not a StrapGattConnection; cannot run real auth');
    }

    final done = Completer<bool>();
    final auth = DeviceHandshake(
      authKey: authKey,
      writeChunk: gatt.writeChunked,
      log: (_) {/* could wire to a logger */},
      onSuccess: () {
        if (!done.isCompleted) done.complete(true);
      },
      onFailure: (r) {
        if (!done.isCompleted) done.complete(false);
      },
    );

    final sub = gatt.incoming.listen(auth.onNotify);
    await auth.start();
    final ok = await done.future.timeout(
      const Duration(seconds: 15),
      onTimeout: () => false,
    );
    await sub.cancel();
    if (!ok) throw StateError('Auth handshake failed or timed out');
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

    final sessionId = await store.createSession(
      deviceMac: null,
      fetchWindowHours: fetchWindowHours,
      listenDurationSec: listenDurationSec,
      mode: SessionMode.fetchAndListen,
    );

    final since = DateTime.now().toUtc().subtract(Duration(hours: fetchWindowHours));
    final requester = DataRequester(gatt);
    final entries = <DumpEntry>[];

    for (final code in typeCodes) {
      state = state.copyWith(currentTypeCode: code);
      try {
        final typeInt = int.parse(
          code.startsWith('0x') ? code.substring(2) : code,
          radix: 16,
        );
        final result = await requester.fetchType(typeInt, since);
        if (result.rawBytes.isNotEmpty) {
          await store.appendBytes(sessionId, code, result.rawBytes);
        }
        entries.add(result.entry);
      } catch (_) {
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

    state = state.copyWith(
      state: SessionState.idle,
      currentTypeCode: null,
      lastSession: await store.readSessionJson(sessionId),
    );
  }
}

final syncOrchestratorProvider =
    NotifierProvider<SyncOrchestrator, SessionSnapshot>(SyncOrchestrator.new);
