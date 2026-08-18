import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:heliolytics/services/ble/auth/auth_key_storage.dart';
import 'package:heliolytics/models/session_state.dart';
import 'package:heliolytics/providers/backfill_days_provider.dart';
import 'package:heliolytics/services/ble/sync_orchestrator_actions.dart';
import 'package:heliolytics/services/ble/sync_orchestrator_run.dart';
import 'package:heliolytics/services/ble/sync_session_log.dart';
import 'package:heliolytics/services/ble/sync_setup_connector.dart';
import 'package:heliolytics/services/session_store.dart';
import 'package:heliolytics/models/sync_payload.dart';

part 'sync_orchestrator_operations.dart';

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
    state = state.copyWith(
      state: hasKey ? SessionState.idle : SessionState.noAuthKey,
    );
    _sessionLog.log(
      'App initialized. Auth key: ${hasKey ? "present" : "missing"}',
    );
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
    state = state.copyWith(
      state: SessionState.noAuthKey,
      logs: [],
      typeResults: [],
    );
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
        runSync: (mac) => runOrchestratedSync(
          ref: ref,
          auth: _authStorage,
          store: _store,
          sessionLog: _sessionLog,
          results: _results,
          setPayload: (payload) => _lastPayload = payload,
          emit: _emit,
          readState: () => state,
          mac: mac,
        ),
      );
    } finally {
      _connecting = false;
    }
  }

  Future<void> connectForSetup() async {
    _connecting = true;
    try {
      await connectForInitialSetup(
        ref: ref,
        readState: () => state,
        sessionLog: _sessionLog,
        emit: _emit,
      );
    } finally {
      _connecting = false;
    }
  }

  Future<void> saveMac(String mac) async {
    await _authStorage.markSetupPending();
    await _authStorage.saveMac(mac);
    _sessionLog.log('Strap MAC saved: $mac');
    _emit(state.copyWith(logs: _sessionLog.logs));
  }

  Future<bool> hasSavedMac() => _authStorage.hasMac();

  Future<void> startSetupSync(int days) async {
    await _authStorage.markSetupPending();
    ref.read(backfillDaysProvider.notifier).state = days;
    await connect();
  }

  Future<void> scheduleAutoConnect() async {
    _store ??= await ref.read(sessionStoreProvider.future);
    await orchestratorAutoConnect(
      ref: ref,
      auth: _authStorage,
      store: _store,
      hasSavedMac: hasSavedMac,
      isSetupPending: _authStorage.isSetupPending,
      isConnecting: () => _connecting,
      readState: () => state,
      sessionLog: _sessionLog,
      emit: _emit,
      connect: connect,
    );
  }

  Future<void> retryLastUpload() => orchestratorRetryUpload(
    ref: ref,
    sessionLog: _sessionLog,
    lastPayload: _lastPayload,
    state: state,
    emit: _emit,
  );
}

final syncOrchestratorProvider =
    NotifierProvider<SyncOrchestrator, SessionSnapshot>(SyncOrchestrator.new);
