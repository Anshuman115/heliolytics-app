import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:heliolytics/core/ble/auth/auth_key_storage.dart';
import 'package:heliolytics/core/ble/session_state.dart';
import 'package:heliolytics/core/ble/sync_orchestrator_actions.dart';
import 'package:heliolytics/core/ble/sync_orchestrator_run.dart';
import 'package:heliolytics/core/ble/sync_session_log.dart';
import 'package:heliolytics/features/ble_discovery/data/session_store.dart';
import 'package:heliolytics/features/cloud_sync/domain/models/sync_payload.dart';

class SyncOrchestrator extends Notifier<SessionSnapshot> {
  late AuthKeyStorage _authStorage;
  SessionStore? _store;
  bool _connecting = false;
  bool _autoConnectScheduled = false;
  final _sessionLog = SyncSessionLog();
  final _results = <TypeCodeResult>[];
  SyncPayload? _lastPayload;

  @override
  SessionSnapshot build() {
    _authStorage = AuthKeyStorage(store: ref.read(authKeyStoreProvider));
    _initAsync();
    return SessionSnapshot.initial;
  }

  void _emit(SessionSnapshot snap) => state = snap;

  Future<void> _initAsync() async {
    _store = await ref.read(sessionStoreProvider.future);
    final hasKey = await _authStorage.hasKey();
    state = state.copyWith(state: hasKey ? SessionState.idle : SessionState.noAuthKey);
    _sessionLog.log('App initialized. Auth key: ${hasKey ? "present" : "missing"}');
    _emit(state.copyWith(logs: _sessionLog.logs));
  }

  Future<void> saveAuthKey(String key) async {
    await _authStorage.save(key);
    state = state.copyWith(state: SessionState.idle);
    _sessionLog.log('Auth key saved');
    _emit(state.copyWith(logs: _sessionLog.logs));
  }

  Future<void> clearAuthKey() async {
    await _authStorage.clear();
    _sessionLog.clear();
    _results.clear();
    state = state.copyWith(state: SessionState.noAuthKey, logs: [], typeResults: []);
  }

  Future<void> connect() => orchestratorConnect(
        ref: ref,
        auth: _authStorage,
        store: _store,
        sessionLog: _sessionLog,
        results: _results,
        state: state,
        emit: _emit,
        setPayload: (p) => _lastPayload = p,
        setConnecting: (v) => _connecting = v,
        runSync: _run,
      );

  Future<void> saveAuthKeyAndMac(String key, String mac) async {
    await _authStorage.save(key);
    await _authStorage.saveMac(mac);
    state = state.copyWith(state: SessionState.idle);
  }

  Future<void> saveMacAndConnect(String mac) async {
    await _authStorage.saveMac(mac);
    await connect();
  }

  Future<bool> hasSavedMac() => _authStorage.hasMac();

  Future<void> scheduleAutoConnect() => orchestratorAutoConnect(
        ref: ref,
        auth: _authStorage,
        hasSavedMac: hasSavedMac,
        autoConnectScheduled: _autoConnectScheduled,
        setAutoConnectScheduled: (v) => _autoConnectScheduled = v,
        connecting: _connecting,
        state: state,
        sessionLog: _sessionLog,
        emit: _emit,
        connect: connect,
      );

  SyncPayload? get lastPayload => _lastPayload;

  Future<void> retryLastUpload() => orchestratorRetryUpload(
        ref: ref,
        sessionLog: _sessionLog,
        lastPayload: _lastPayload,
        state: state,
        emit: _emit,
      );

  Future<void> refetchType(String codeStr) async {
    final store = _store;
    if (store == null) return;
    await orchestratorRefetch(
        ref: ref,
        auth: _authStorage,
        store: store,
        sessionLog: _sessionLog,
        connecting: _connecting,
        readState: () => state,
        lastPayload: _lastPayload,
        emit: _emit,
        setPayload: (p) => _lastPayload = p,
        setConnecting: (v) => _connecting = v,
        codeStr: codeStr,
      );
  }

  Future<void> _run(String mac) async {
    final store = _store;
    final authKey = await _authStorage.readBytes();
    if (store == null || authKey == null) {
      _sessionLog.log('No auth key stored');
      _emit(state.copyWith(logs: _sessionLog.logs));
      return;
    }
    await runFullSync(
      ref: ref,
      store: store,
      sessionLog: _sessionLog,
      mac: mac,
      authKey: authKey,
      results: _results,
      setPayload: (p) => _lastPayload = p,
      emit: _emit,
    );
  }
}

final syncOrchestratorProvider =
    NotifierProvider<SyncOrchestrator, SessionSnapshot>(SyncOrchestrator.new);
