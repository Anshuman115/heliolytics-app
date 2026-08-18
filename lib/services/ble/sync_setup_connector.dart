import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:heliolytics/models/session_state.dart';
import 'package:heliolytics/providers/band_session_provider.dart';
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
  emit(
    readState().copyWith(
      state: SessionState.connected,
      error: SessionError.none,
      logs: sessionLog.logs,
    ),
  );
}
