import 'package:heliolytics/core/ble/session_state.dart';
import 'package:heliolytics/features/cloud_sync/domain/models/sync_payload.dart';

class SyncFetchOutcome {
  final SyncPayload payload;
  final List<TypeCodeResult> typeResults;

  const SyncFetchOutcome({required this.payload, required this.typeResults});
}
