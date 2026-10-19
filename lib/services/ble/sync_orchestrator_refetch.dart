import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:heliolytics/models/band_session_state.dart';
import 'package:heliolytics/models/session_state.dart';
import 'package:heliolytics/models/strap_health_config.dart';
import 'package:heliolytics/models/sync_payload.dart';
import 'package:heliolytics/providers/band_session_provider.dart';
import 'package:heliolytics/providers/strap_health_config_provider.dart';
import 'package:heliolytics/services/ble/auth/auth_key_storage.dart';
import 'package:heliolytics/services/ble/band_link_port.dart';
import 'package:heliolytics/services/ble/sync_fetcher.dart';
import 'package:heliolytics/services/ble/sync_orchestrator_helpers.dart';
import 'package:heliolytics/services/ble/sync_session_log.dart';
import 'package:heliolytics/services/ble/sync_session_port.dart';
import 'package:heliolytics/services/ble/sync_window_resolver.dart';
import 'package:heliolytics/services/ble/sync_type_catalog.dart';
import 'package:heliolytics/services/ble/zepp/health_config_service.dart';

Future<void> runRefetch({
  required Ref ref,
  required AuthKeyStorage auth,
  required SyncSessionPort store,
  required SyncSessionLog sessionLog,
  required String codeStr,
  required void Function(SyncPayload?) setPayload,
  required StateSink emit,
}) async {
  if (!isProductionFetchType(codeStr)) {
    final message = 'Unsupported production refetch type: $codeStr';
    sessionLog.log(message);
    emit(
      syncSnap(
        SessionState.error,
        sessionLog,
        const [],
        error: SessionError.scanFailed,
        lastErrorMessage: message,
      ),
    );
    return;
  }
  final band = ref.read(bandSessionProvider.notifier);
  final blocked = band.tryAcquire(BandSessionOp.sync);
  if (blocked != null) {
    sessionLog.log('✗ $blocked');
    emit(
      syncSnap(
        SessionState.error,
        sessionLog,
        const [],
        lastErrorMessage: blocked,
      ),
    );
    return;
  }

  try {
    emit(
      syncSnap(
        SessionState.connecting,
        sessionLog,
        const [],
        currentTypeCode: codeStr,
      ),
    );
    sessionLog.log('→ refetch $codeStr only (per-type coverage)');

    if (!await band.ensureConnected()) {
      sessionLog.log('Refetch aborted: connect failed');
      emit(syncSnap(SessionState.error, sessionLog, const []));
      return;
    }

    final link = band.session.link;
    if (link == null) {
      emit(syncSnap(SessionState.error, sessionLog, const []));
      return;
    }

    emit(
      syncSnap(
        SessionState.fetching,
        sessionLog,
        const [],
        currentTypeCode: codeStr,
      ),
    );

    final mac = await auth.readMac();
    final authKey = await auth.readBytes();
    if (mac == null || mac.isEmpty || authKey == null) {
      sessionLog.log('Refetch aborted: missing MAC or auth key');
      emit(syncSnap(SessionState.error, sessionLog, const []));
      return;
    }

    HealthConfigSnapshot? strapConfig;
    try {
      strapConfig = await ref
          .read(strapHealthConfigProvider.notifier)
          .reconcileWithinSession(link);
    } on HealthConfigError catch (error) {
      if (!error.requiresReconnect && link.isCommsReady) {
        strapConfig = error.actual;
        sessionLog.log('• health configuration mismatch: ${error.message}');
      } else {
        sessionLog.log(
          '• refetch health configuration unavailable: ${error.message}',
        );
        emit(
          syncSnap(
            SessionState.error,
            sessionLog,
            const [],
            error: SessionError.bleDisconnected,
            lastErrorMessage: error.message,
          ),
        );
        return;
      }
    }

    final plan = await resolveSyncWindow(ref);
    final results = <TypeCodeResult>[];
    final outcome =
        await SyncFetcher(log: sessionLog.log, store: store, auth: auth).run(
          mac: mac,
          authKey: authKey,
          plan: plan,
          singleTypeCode: codeStr,
          strapConfig: strapConfig,
          client: link,
          disconnectAfter: false,
          onTypeProgress: (_, r) => results.add(r),
        );

    final result = outcome?.typeResults.length == 1
        ? outcome!.typeResults.single
        : null;
    if (outcome == null ||
        result == null ||
        (result.status != 'ok' && result.status != 'empty')) {
      sessionLog.log('✗ refetch $codeStr failed');
      emit(
        syncSnap(
          SessionState.error,
          sessionLog,
          const [],
          error: SessionError.scanFailed,
          lastErrorMessage: 'Refetch $codeStr failed',
        ),
      );
      return;
    }

    setPayload(outcome.payload);
    sessionLog.log('✓ refetch $codeStr: ${result.bytes} bytes');
    final lastSession = outcome.payload.session;
    emit(
      syncSnap(
        SessionState.connected,
        sessionLog,
        results,
        lastSession: lastSession,
      ),
    );
    await commitPayload(ref, sessionLog, outcome.payload, emit, results);
  } on BandLinkDisconnectedException catch (error) {
    sessionLog.log('✗ $error');
    emit(
      syncSnap(
        SessionState.error,
        sessionLog,
        const [],
        error: SessionError.bleDisconnected,
        lastErrorMessage: 'Strap disconnected during refetch.',
      ),
    );
  } finally {
    band.release(BandSessionOp.sync);
  }
}
