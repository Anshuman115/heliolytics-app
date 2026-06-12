import 'package:heliolytics/features/cloud_sync/domain/models/sync_payload.dart';

abstract class CloudSyncRepository {
  Future<void> uploadPayload(SyncPayload payload);
}
