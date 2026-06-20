import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:heliolytics/services/ble/auth/auth_key_storage.dart';
import 'package:heliolytics/services/ble/auto_strap_service.dart';
import 'package:heliolytics/models/session_state.dart';
import 'package:heliolytics/services/ble/sync_committer.dart';
import 'package:heliolytics/services/ble/sync_orchestrator_refetch.dart';
import 'package:heliolytics/services/ble/sync_session_log.dart';
import 'package:heliolytics/constants/constants.dart';
import 'package:heliolytics/services/session_store.dart';
import 'package:heliolytics/models/sync_payload.dart';
import 'package:heliolytics/providers/cloud_sync_provider.dart';

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

Future<void> orchestratorTryAutoConnect({
  required Ref ref,
  required AuthKeyStorage auth,
  required bool connecting,
  required SessionSnapshot state,
  required SyncSessionLog sessionLog,
  required void Function(SessionSnapshot) emit,
  required Future<void> Function() connect,
  required AutoStrapService autoStrap,
  required void Function(bool) setAutoConnectPending,
}) async {
  if (!await auth.hasKey()) return;

  if (!await ref.read(apiConfiguredProvider.future)) {
    sessionLog.log('Auto-sync skipped: configure Cloud API in Settings first');
    emit(state.copyWith(logs: sessionLog.logs));
    return;
  }

  if (state.state != SessionState.idle || connecting) {
    setAutoConnectPending(true);
    return;
  }

  setAutoConnectPending(false);

  var mac = await auth.readMac();
  if (mac == null || mac.isEmpty) {
    sessionLog.log('Auto-scan: no MAC saved, scanning…');
    emit(state.copyWith(state: SessionState.scanning, logs: sessionLog.logs));
    mac = await autoStrap.scanAndPair();
    emit(state.copyWith(state: SessionState.idle, logs: sessionLog.logs));
    if (mac == null || mac.isEmpty) {
      sessionLog.log('Auto-scan: no Helio strap found');
      emit(state.copyWith(logs: sessionLog.logs));
      return;
    }
    await auth.saveMac(mac);
    sessionLog.log('Auto-scan: paired $mac');
    emit(state.copyWith(logs: sessionLog.logs));
  }

  sessionLog.log('Auto-sync: connecting to strap');
  emit(state.copyWith(logs: sessionLog.logs));
  await connect();
}

Future<void> orchestratorAutoConnect({
  required Ref ref,
  required AuthKeyStorage auth,
  required Future<bool> Function() hasSavedMac,
  required bool autoConnectPending,
  required void Function(bool) setAutoConnectPending,
  required bool connecting,
  required SessionSnapshot state,
  required SyncSessionLog sessionLog,
  required void Function(SessionSnapshot) emit,
  required Future<void> Function() connect,
  required AutoStrapService autoStrap,
}) =>
    orchestratorTryAutoConnect(
      ref: ref,
      auth: auth,
      connecting: connecting,
      state: state,
      sessionLog: sessionLog,
      emit: emit,
      connect: connect,
      autoStrap: autoStrap,
      setAutoConnectPending: setAutoConnectPending,
    );
