import 'package:heliolytics/models/session_state.dart';
import 'package:heliolytics/models/sync_payload.dart';

class SyncFetchOutcome {
  final SyncPayload payload;
  final List<TypeCodeResult> typeResults;

  const SyncFetchOutcome({required this.payload, required this.typeResults});
}
