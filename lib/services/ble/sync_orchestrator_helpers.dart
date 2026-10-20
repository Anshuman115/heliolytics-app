import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:heliolytics/models/ingest_result.dart';
import 'package:heliolytics/models/session.dart';
import 'package:heliolytics/models/session_state.dart';
import 'package:heliolytics/models/sync_payload.dart';
import 'package:heliolytics/services/ble/sync_committer.dart';
import 'package:heliolytics/services/ble/sync_session_log.dart';
import 'package:heliolytics/utils/error_messages.dart';

typedef StateSink = void Function(SessionSnapshot snapshot);

SessionSnapshot syncSnap(
  SessionState state,
  SyncSessionLog sessionLog,
  List<TypeCodeResult> results, {
  String? currentTypeCode,
  SessionError error = SessionError.none,
  String? lastErrorMessage,
  Session? lastSession,
  IngestResult? lastIngestResult,
}) => SessionSnapshot(
  state: state,
  error: error,
  currentTypeCode: currentTypeCode,
  lastSession: lastSession,
  lastErrorMessage: lastErrorMessage,
  typeResults: List.unmodifiable(results),
  logs: sessionLog.logs,
  lastIngestResult: lastIngestResult,
);

void logFetchSummary(SyncSessionLog sessionLog, List<TypeCodeResult> results) {
  final ok = results.where((r) => r.status == 'ok').length;
  final emp = results.where((r) => r.status == 'empty').length;
  final rej = results.where((r) => r.status == 'rejected').length;
  sessionLog.log('═══ DONE ═══  $ok ok  $emp empty  $rej rejected');
}

/// Uploads the session and emits the typed outcome on success.
Future<IngestResult?> commitPayload(
  Ref ref,
  SyncSessionLog sessionLog,
  SyncPayload payload,
  StateSink emit,
  List<TypeCodeResult> results,
) async {
  try {
    final result = await SyncCommitter.fromRef(
      ref,
      sessionLog.log,
    ).commit(payload);
    if (result != null) {
      emit(
        syncSnap(
          SessionState.connected,
          sessionLog,
          results,
          lastSession: payload.session,
          lastIngestResult: result,
        ),
      );
      if (!result.complete) {
        sessionLog.log('• partial upload: ${result.partialCodes.join(', ')}');
      }
    }
    return result;
  } catch (e) {
    emit(
      syncSnap(
        SessionState.error,
        sessionLog,
        results,
        lastErrorMessage: 'Cloud upload failed: ${friendlyError(e)}',
      ),
    );
    return null;
  }
}
