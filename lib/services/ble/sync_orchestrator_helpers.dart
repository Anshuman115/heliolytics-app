import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:heliolytics/services/ble/sync_committer.dart';
import 'package:heliolytics/services/ble/sync_session_log.dart';
import 'package:heliolytics/models/session_state.dart';
import 'package:heliolytics/models/session.dart';
import 'package:heliolytics/models/sync_payload.dart';

typedef StateSink = void Function(SessionSnapshot snapshot);

SessionSnapshot syncSnap(
  SessionState state,
  SyncSessionLog sessionLog,
  List<TypeCodeResult> results, {
  String? currentTypeCode,
  SessionError error = SessionError.none,
  String? lastErrorMessage,
  Session? lastSession,
}) =>
    SessionSnapshot(
      state: state,
      error: error,
      currentTypeCode: currentTypeCode,
      lastSession: lastSession,
      lastErrorMessage: lastErrorMessage,
      typeResults: List.unmodifiable(results),
      logs: sessionLog.logs,
    );

void logFetchSummary(SyncSessionLog sessionLog, List<TypeCodeResult> results) {
  final ok = results.where((r) => r.status == 'ok').length;
  final emp = results.where((r) => r.status == 'empty').length;
  final rej = results.where((r) => r.status == 'rejected').length;
  sessionLog.log('═══ DONE ═══  $ok ok  $emp empty  $rej rejected');
}

Future<void> commitPayload(
  Ref ref,
  SyncSessionLog sessionLog,
  SyncPayload payload,
  StateSink emit,
  List<TypeCodeResult> results,
) async {
  try {
    await SyncCommitter.fromRef(ref, sessionLog.log).commit(payload);
  } catch (e) {
    emit(syncSnap(
      SessionState.error,
      sessionLog,
      results,
      lastErrorMessage: 'Cloud upload failed: $e',
    ));
  }
}
