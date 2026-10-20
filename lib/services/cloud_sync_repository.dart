import 'package:heliolytics/models/ingest_result.dart';
import 'package:heliolytics/models/sync_payload.dart';

abstract class CloudSyncRepository {
  /// Uploads one immutable session and returns the typed C2 outcome.
  Future<IngestResult> uploadPayload(SyncPayload payload);
}
