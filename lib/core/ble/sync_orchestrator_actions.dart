import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:heliolytics/core/ble/auth/auth_key_storage.dart';
import 'package:heliolytics/core/ble/session_state.dart';
import 'package:heliolytics/core/ble/sync_committer.dart';
import 'package:heliolytics/core/ble/sync_orchestrator_refetch.dart';
import 'package:heliolytics/core/ble/sync_session_log.dart';
import 'package:heliolytics/core/constants.dart';
import 'package:heliolytics/features/ble_discovery/data/session_store.dart';
import 'package:heliolytics/features/cloud_sync/domain/models/sync_payload.dart';
import 'package:heliolytics/features/cloud_sync/presentation/providers/cloud_sync_provider.dart';

Future<void> orchestratorConnect({
  required Ref ref,
  required AuthKeyStorage auth,
  required SessionStore? store,
  required SyncSessionLog sessionLog,
  required List<TypeCodeResult> results,
  required SessionSnapshot state,
  required void Function(SessionSnapshot) emit,
  required void Function(SyncPayload?) setPayload,
  required Future<void> Function(String mac) runSync,
  required void Function(bool) setConnecting,
}) async {
  if (state.state != SessionState.idle && state.state != SessionState.error) {
    return;
  }
  setConnecting(true);
  if (state.state == SessionState.error) {
    emit(state.copyWith(state: SessionState.idle, error: SessionError.none));
  }
  final mac = await auth.readMac();
  if (mac == null || mac.isEmpty) {
    sessionLog.log('ERROR: No MAC saved. Please scan first.');
    emit(state.copyWith(
      state: SessionState.error,
      error: SessionError.scanFailed,
      lastErrorMessage: 'No strap MAC saved.',
      logs: sessionLog.logs,
    ));
    setConnecting(false);
    return;
  }
  if (!await ref.read(apiConfiguredProvider.future)) {
    sessionLog.log('Connect skipped: configure Cloud API in Settings first');
    emit(state.copyWith(
      state: SessionState.error,
      lastErrorMessage: cloudApiRequiredBeforeSyncMessage,
      logs: sessionLog.logs,
    ));
    setConnecting(false);
    return;
  }
  await runSync(mac);
  setConnecting(false);
}

Future<void> orchestratorRefetch({
  required Ref ref,
  required AuthKeyStorage auth,
  required SessionStore store,
  required SyncSessionLog sessionLog,
  required bool connecting,
  required SessionSnapshot Function() readState,
  required SyncPayload? lastPayload,
  required void Function(SessionSnapshot) emit,
  required void Function(SyncPayload?) setPayload,
  required void Function(bool) setConnecting,
  required String codeStr,
}) async {
  var state = readState();
  if (connecting ||
      state.state == SessionState.fetching ||
      state.state == SessionState.connecting) {
    return;
  }
  if (!await ref.read(apiConfiguredProvider.future)) {
    sessionLog.log('Refetch skipped: configure Cloud API in Settings first');
    emit(state.copyWith(
      state: SessionState.error,
      lastErrorMessage: cloudApiRequiredBeforeSyncMessage,
      logs: sessionLog.logs,
    ));
    return;
  }
  setConnecting(true);
  try {
    await runRefetch(
      ref: ref,
      auth: auth,
      store: store,
      sessionLog: sessionLog,
      codeStr: codeStr,
      lastPayload: lastPayload,
      setPayload: setPayload,
      emit: emit,
    );
  } finally {
    state = readState();
    emit(state.copyWith(
      state: SessionState.idle,
      currentTypeCode: null,
      logs: sessionLog.logs,
    ));
    setConnecting(false);
  }
}

Future<void> orchestratorRetryUpload({
  required Ref ref,
  required SyncSessionLog sessionLog,
  required SyncPayload? lastPayload,
  required SessionSnapshot state,
  required void Function(SessionSnapshot) emit,
}) async {
  final p = lastPayload;
  if (p == null) throw StateError('No session in memory — sync first');
  try {
    await SyncCommitter.fromRef(ref, sessionLog.log).commit(p);
  } catch (e) {
    emit(state.copyWith(
      state: SessionState.error,
      lastErrorMessage: 'Cloud upload failed: $e',
      logs: sessionLog.logs,
    ));
    rethrow;
  }
  emit(state.copyWith(logs: sessionLog.logs));
}

Future<void> orchestratorAutoConnect({
  required Ref ref,
  required AuthKeyStorage auth,
  required Future<bool> Function() hasSavedMac,
  required bool autoConnectScheduled,
  required void Function(bool) setAutoConnectScheduled,
  required bool connecting,
  required SessionSnapshot state,
  required SyncSessionLog sessionLog,
  required void Function(SessionSnapshot) emit,
  required Future<void> Function() connect,
}) async {
  if (autoConnectScheduled) return;
  setAutoConnectScheduled(true);
  if (!await auth.hasKey()) return;
  if (!await hasSavedMac()) return;
  if (state.state != SessionState.idle || connecting) return;
  if (!await ref.read(apiConfiguredProvider.future)) {
    sessionLog.log('Auto-sync skipped: configure Cloud API in Settings first');
    emit(state.copyWith(logs: sessionLog.logs));
    return;
  }
  sessionLog.log('Auto-sync: connecting to saved strap');
  emit(state.copyWith(logs: sessionLog.logs));
  await connect();
}
