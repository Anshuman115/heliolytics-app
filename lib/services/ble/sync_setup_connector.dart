import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:heliolytics/models/band_session_state.dart';
import 'package:heliolytics/models/session_state.dart';
import 'package:heliolytics/providers/band_session_provider.dart';
import 'package:heliolytics/providers/strap_health_config_provider.dart';
import 'package:heliolytics/services/ble/zepp/health_config_service.dart';
import 'package:heliolytics/services/ble/sync_session_log.dart';

Future<void> connectForInitialSetup({
  required Ref ref,
  required SessionSnapshot Function() readState,
  required SyncSessionLog sessionLog,
  required void Function(SessionSnapshot) emit,
}) async {
  final state = readState();
  if (state.state != SessionState.idle &&
      state.state != SessionState.error &&
      state.state != SessionState.connected) {
    return;
  }

  emit(
    state.copyWith(
      state: SessionState.connecting,
      error: SessionError.none,
      logs: sessionLog.logs,
    ),
  );
  sessionLog.log('Connecting for initial setup');

  final band = ref.read(bandSessionProvider.notifier);
  if (!await band.ensureConnected()) {
    final message =
        ref.read(bandSessionProvider).errorMessage ?? 'Connect or auth failed';
    sessionLog.log('Initial setup connection failed: $message');
    emit(
      readState().copyWith(
        state: SessionState.error,
        error: SessionError.authRejected,
        lastErrorMessage: message,
        logs: sessionLog.logs,
      ),
    );
    return;
  }
  sessionLog.log('Initial setup connection authenticated');
  final configBlocked = band.tryAcquire(BandSessionOp.strapConfig);
  if (configBlocked != null) {
    sessionLog.log('Health settings read skipped: $configBlocked');
  } else {
    try {
      final link = band.session.link;
      if (link != null) {
        await ref
            .read(strapHealthConfigProvider.notifier)
            .reconcileWithinSession(link);
      }
    } on HealthConfigError catch (error) {
      sessionLog.log('Health settings read failed: ${error.message}');
      if (error.requiresReconnect) {
        emit(
          readState().copyWith(
            state: SessionState.error,
            error: SessionError.bleDisconnected,
            lastErrorMessage: error.message,
            logs: sessionLog.logs,
          ),
        );
        return;
      }
    } finally {
      band.release(BandSessionOp.strapConfig);
    }
  }
  if (!band.session.isReady) {
    emit(
      readState().copyWith(
        state: SessionState.error,
        error: SessionError.bleDisconnected,
        lastErrorMessage: 'Strap disconnected during setup.',
        logs: sessionLog.logs,
      ),
    );
    return;
  }
  sessionLog.log('Initial setup health settings reconciled');

  emit(
    readState().copyWith(
      state: SessionState.connected,
      error: SessionError.none,
      logs: sessionLog.logs,
    ),
  );
}
