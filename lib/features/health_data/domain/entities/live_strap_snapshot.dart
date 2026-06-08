import 'package:heliolytics/core/ble/parsers/hrv.dart';
import 'package:heliolytics/core/ble/parsers/sleep_session.dart';
import 'package:heliolytics/features/health_data/domain/entities/day_health_row.dart';

/// Parsed view of the most recent on-device BLE sync (not laptop dumps).
class LiveStrapSnapshot {
  final String sessionId;
  final DateTime syncedAt;
  final List<DayHealthRow> days;
  final List<SleepSession> sleepSessions;
  final List<HrvSample> hrvSamples;

  const LiveStrapSnapshot({
    required this.sessionId,
    required this.syncedAt,
    required this.days,
    required this.sleepSessions,
    required this.hrvSamples,
  });
}
