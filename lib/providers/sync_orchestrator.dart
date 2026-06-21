import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:heliolytics/services/ble/auth/auth_key_storage.dart';
import 'package:heliolytics/models/session_state.dart';
import 'package:heliolytics/services/ble/sync_orchestrator_actions.dart';
import 'package:heliolytics/services/ble/sync_orchestrator_run.dart';
import 'package:heliolytics/services/ble/sync_session_log.dart';
import 'package:heliolytics/services/session_store.dart';
import 'package:heliolytics/models/sync_payload.dart';

class SyncOrchestrator extends Notifier<SessionSnapshot> {
  late AuthKeyStorage _authStorage;
  SessionStore? _store;
  bool _connecting = false;
  final _sessionLog = SyncSessionLog();
  final _results = <TypeCodeResult>[];
  SyncPayload? _lastPayload;

  bool get connecting => _connecting;

  @override
  SessionSnapshot build() {
    ref.keepAlive();
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

  Future<void> connect() async {
    _connecting = true;
    try {
      await orchestratorConnect(
        ref: ref,
        auth: _authStorage,
        store: _store,
        sessionLog: _sessionLog,
        results: _results,
        state: state,
        emit: _emit,
        setPayload: (p) => _lastPayload = p,
        runSync: _run,
      );
    } finally {
      _connecting = false;
    }
  }

  Future<void> saveMac(String mac) async {
    await _authStorage.saveMac(mac);
    _sessionLog.log('Strap MAC saved: $mac');
    _emit(state.copyWith(logs: _sessionLog.logs));
  }

  Future<void> saveMacAndConnect(String mac) async {
    await saveMac(mac);
    await connect();
  }

  Future<bool> hasSavedMac() => _authStorage.hasMac();

  Future<void> scheduleAutoConnect() => orchestratorAutoConnect(
        ref: ref,
        auth: _authStorage,
        hasSavedMac: hasSavedMac,
        isConnecting: () => _connecting,
        readState: () => state,
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
      auth: _authStorage,
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
