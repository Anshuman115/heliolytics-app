import 'package:heliolytics/features/cloud_sync/domain/repositories/cloud_sync_repository.dart';

/// Phase 3 stub — wire to Go API when backend is ready.
class CloudSyncRepositoryImpl implements CloudSyncRepository {
  @override
  Future<void> uploadSession(String sessionId) async {
    throw UnimplementedError('Phase 3: connect to Heliolytics API');
  }

  @override
  Future<void> uploadPending() async {
    throw UnimplementedError('Phase 3: offline queue + retry');
  }
}
