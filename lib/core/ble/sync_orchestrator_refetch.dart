import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:heliolytics/core/ble/auth/auth_key_storage.dart';
import 'package:heliolytics/core/ble/sync_fetcher.dart';
import 'package:heliolytics/core/ble/sync_orchestrator_helpers.dart';
import 'package:heliolytics/core/ble/sync_payload_builder.dart';
import 'package:heliolytics/core/ble/sync_session_log.dart';
import 'package:heliolytics/core/ble/sync_session_port.dart';
import 'package:heliolytics/core/ble/sync_window_resolver.dart';
import 'package:heliolytics/core/ble/session_state.dart';
import 'package:heliolytics/features/cloud_sync/domain/models/sync_payload.dart';

Future<void> runRefetch({
  required Ref ref,
  required AuthKeyStorage auth,
  required SyncSessionPort store,
  required SyncSessionLog sessionLog,
  required String codeStr,
  required SyncPayload? lastPayload,
  required void Function(SyncPayload?) setPayload,
  required StateSink emit,
}) async {
  emit(syncSnap(
    SessionState.connecting,
    sessionLog,
    const [],
    currentTypeCode: codeStr,
  ));
  sessionLog.log('→ refetch $codeStr only (per-type coverage)');
  emit(syncSnap(SessionState.fetching, sessionLog, const [], currentTypeCode: codeStr));

  final mac = await auth.readMac();
  final authKey = await auth.readBytes();
  if (mac == null || mac.isEmpty || authKey == null) {
    sessionLog.log('Refetch aborted: missing MAC or auth key');
    emit(syncSnap(SessionState.error, sessionLog, const []));
    return;
  }

  final plan = await resolveSyncWindow(ref);
  final base = lastPayload ??
      await payloadFromLastSession(store, await store.latestSessionId());
  if (base == null) {
    sessionLog.log('✗ refetch $codeStr failed: no base session');
    emit(syncSnap(SessionState.error, sessionLog, const []));
    return;
  }

  final results = <TypeCodeResult>[];
  final outcome = await SyncFetcher(log: sessionLog.log, store: store).run(
    mac: mac,
    authKey: authKey,
    plan: plan,
    singleTypeCode: codeStr,
    mergeBase: base,
    disconnectAfter: true,
    onTypeProgress: (_, r) => results.add(r),
  );

  if (outcome == null) {
    sessionLog.log('Refetch aborted: connect/auth failed');
    emit(syncSnap(SessionState.error, sessionLog, const []));
    return;
  }
  if (outcome.payload.rawByCode.isEmpty) {
    sessionLog.log('✗ refetch $codeStr failed');
    emit(syncSnap(
      SessionState.error,
      sessionLog,
      const [],
      error: SessionError.scanFailed,
      lastErrorMessage: 'Refetch $codeStr failed',
    ));
    return;
  }

  setPayload(outcome.payload);
  sessionLog.log(
    '✓ refetch $codeStr: ${outcome.typeResults.single.bytes} bytes',
  );
  final sid = await store.latestSessionId();
  final lastSession = sid != null
      ? await store.readSessionJson(sid)
      : outcome.payload.session;
  emit(syncSnap(
    SessionState.idle,
    sessionLog,
    results,
    lastSession: lastSession,
  ));
  await commitPayload(ref, sessionLog, outcome.payload, emit, results);
}
