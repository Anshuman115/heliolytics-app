import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:heliolytics/models/band_session_state.dart';
import 'package:heliolytics/providers/band_session_provider.dart';
import 'package:heliolytics/services/ble/auth/auth_key_storage.dart';
import 'package:heliolytics/services/ble/sync_fetcher.dart';
import 'package:heliolytics/services/ble/sync_orchestrator_helpers.dart';
import 'package:heliolytics/services/ble/sync_session_log.dart';
import 'package:heliolytics/services/ble/sync_session_port.dart';
import 'package:heliolytics/services/ble/sync_window_resolver.dart';
import 'package:heliolytics/models/session_state.dart';
import 'package:heliolytics/models/sync_payload.dart';

Future<void> runFullSync({
  required Ref ref,
  required AuthKeyStorage auth,
  required SyncSessionPort store,
  required SyncSessionLog sessionLog,
  required String mac,
  required Uint8List authKey,
  required List<TypeCodeResult> results,
  required void Function(SyncPayload?) setPayload,
  required StateSink emit,
}) async {
  final band = ref.read(bandSessionProvider.notifier);
  final blocked = band.tryAcquire(BandSessionOp.sync);
  if (blocked != null) {
    sessionLog.log('✗ $blocked');
    emit(syncSnap(
      SessionState.error,
      sessionLog,
      results,
      lastErrorMessage: blocked,
    ));
    return;
  }

  try {
    emit(syncSnap(SessionState.connecting, sessionLog, results));
    sessionLog.log('→ connecting to $mac');

    if (!await band.ensureConnected()) {
      sessionLog.log('✗ connect/auth failed');
      emit(syncSnap(
        SessionState.error,
        sessionLog,
        results,
        error: SessionError.authRejected,
        lastErrorMessage: ref.read(bandSessionProvider).errorMessage ??
            'Connect or auth failed',
      ));
      return;
    }

    final link = band.session.link;
    if (link == null) {
      sessionLog.log('✗ no shared link after connect');
      emit(syncSnap(
        SessionState.error,
        sessionLog,
        results,
        error: SessionError.authRejected,
        lastErrorMessage: 'Connect or auth failed',
      ));
      return;
    }

    final plan = await resolveSyncWindow(ref);
    for (final line in plan.logLines) {
      sessionLog.log(line);
    }
    if (plan.backendDataThrough != null) {
      final gap = DateTime.now().difference(plan.backendDataThrough!);
      sessionLog.log('Gap to fill: ${gap.inHours}h ${gap.inMinutes.remainder(60)}m');
    }

    results.clear();
    emit(syncSnap(SessionState.fetching, sessionLog, results));
    final outcome = await SyncFetcher(log: sessionLog.log, store: store, auth: auth).run(
      mac: mac,
      authKey: authKey,
      plan: plan,
      client: link,
      disconnectAfter: false,
      onTypeStart: (code) => emit(syncSnap(
        SessionState.fetching,
        sessionLog,
        results,
        currentTypeCode: code,
      )),
      onTypeProgress: (code, result) {
        results.add(result);
        emit(syncSnap(
          SessionState.fetching,
          sessionLog,
          results,
          currentTypeCode: code,
        ));
      },
    );

    if (outcome == null) {
      sessionLog.log('✗ fetch failed');
      emit(syncSnap(
        SessionState.error,
        sessionLog,
        results,
        error: SessionError.authRejected,
        lastErrorMessage: 'Sync fetch failed',
      ));
      return;
    }

    sessionLog.log('✓ fetch done — strap stays connected');
    setPayload(outcome.payload);
    logFetchSummary(sessionLog, results);
    emit(syncSnap(
      SessionState.connected,
      sessionLog,
      results,
      lastSession: outcome.payload.session,
    ));
    await commitPayload(ref, sessionLog, outcome.payload, emit, results);
  } finally {
    band.release(BandSessionOp.sync);
  }
}
