import 'package:heliolytics/models/session_catalog.dart';
import 'package:heliolytics/models/strap_health_config.dart';

/// Creates a frozen catalog snapshot. Desired preferences and later reads do
/// not mutate the returned catalog or an already persisted upload.
SessionCatalog catalogWithHealthConfig(
  SessionCatalog base,
  HealthConfigSnapshot? actual,
) {
  final frozen = actual == null
      ? null
      : HealthConfigSnapshot(
          version: actual.version,
          spo2AllDay: actual.spo2AllDay,
          spo2LowAlert: actual.spo2LowAlert,
          sleepBreathing: actual.sleepBreathing,
        );
  return SessionCatalog(
    sessionId: base.sessionId,
    chunked: List.unmodifiable(base.chunked),
    unsolicited: List.unmodifiable(base.unsolicited),
    strapConfig: frozen,
  );
}
