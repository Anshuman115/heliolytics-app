import 'package:heliolytics/features/ble_discovery/domain/models/session.dart';
import 'package:heliolytics/features/ble_discovery/domain/models/session_catalog.dart';
import 'package:heliolytics/features/ble_discovery/domain/models/session_mode.dart';

abstract class SyncSessionPort {
  Future<String> createSession({
    required String? deviceMac,
    required int fetchWindowHours,
    required int listenDurationSec,
    required SessionMode mode,
  });

  Future<Session> readSessionJson(String sessionId);

  Future<void> writeSessionJson(Session session);

  Future<void> writeCatalogJson(SessionCatalog catalog);

  Future<String?> latestSessionId();
}
