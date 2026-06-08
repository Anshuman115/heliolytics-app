/// Phase 3 — push parsed sessions to Heliolytics backend (TimescaleDB ETL).
abstract class CloudSyncRepository {
  Future<void> uploadSession(String sessionId);
  Future<void> uploadPending();
}
