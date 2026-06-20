import 'package:heliolytics/models/sync_payload.dart';

abstract class CloudSyncRepository {
  Future<void> uploadPayload(SyncPayload payload);
}
