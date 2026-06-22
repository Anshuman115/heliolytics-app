import 'package:heliolytics/models/day_metric.dart';
import 'package:heliolytics/models/sync_coverage.dart';

/// Core daily snapshot for Home/Sleep/Activity. Heavy per-minute datasets
/// (series, continuous HR, temperature) live in DetailMetrics, loaded lazily.
class CloudMetricsSnapshot {
  final List<DayMetric> days;
  final List<SleepMetric> sleep;
  final List<WorkoutMetric> workouts;
  final List<ActivitySessionMetric> activitySessions;
  final DateTime? lastSyncedAt;
  final int? batteryPercent;
  final SyncCoverage? coverage;

  const CloudMetricsSnapshot({
    required this.days,
    this.sleep = const [],
    this.workouts = const [],
    this.activitySessions = const [],
    this.lastSyncedAt,
    this.batteryPercent,
    this.coverage,
  });

  int get totalSteps => days.fold<int>(0, (s, d) => s + d.steps);

  SleepMetric? sleepFor(String dayKey) => mainSleepFor(dayKey);

  SleepMetric? mainSleepFor(String dayKey) {
    SleepMetric? best;
    for (final s in sleep) {
      if (s.dayKey != dayKey || s.isNap) continue;
      if (best == null || s.totalMins > best.totalMins) best = s;
    }
    return best;
  }

  List<SleepMetric> napsFor(String dayKey) =>
      sleep.where((s) => s.dayKey == dayKey && s.isNap).toList();

  int caloriesFor(String dayKey) {
    var total = 0;
    for (final w in workoutsFor(dayKey)) {
      total += w.calories ?? 0;
    }
    for (final s in activitySessionsFor(dayKey)) {
      total += s.calories ?? 0;
    }
    return total;
  }

  List<WorkoutMetric> workoutsFor(String dayKey) =>
      workouts.where((w) => w.dayKey == dayKey).toList();

  List<ActivitySessionMetric> activitySessionsFor(String dayKey) =>
      activitySessions.where((s) => s.dayKey == dayKey).toList();
}
