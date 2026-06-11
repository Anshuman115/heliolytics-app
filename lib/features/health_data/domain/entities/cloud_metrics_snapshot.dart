import 'package:heliolytics/features/health_data/domain/entities/day_metric.dart';
import 'package:heliolytics/features/health_data/domain/entities/health_sample.dart';
import 'package:heliolytics/features/health_data/domain/entities/temp_sample.dart';

class CloudMetricsSnapshot {
  final List<DayMetric> days;
  final List<SleepMetric> sleep;
  final List<WorkoutMetric> workouts;
  final List<ActivitySessionMetric> activitySessions;
  final List<TempSample> temperature;
  final List<HealthSample> series;
  final DateTime? lastSyncedAt;
  final int? batteryPercent;

  const CloudMetricsSnapshot({
    required this.days,
    this.sleep = const [],
    this.workouts = const [],
    this.activitySessions = const [],
    this.temperature = const [],
    this.series = const [],
    this.lastSyncedAt,
    this.batteryPercent,
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

  List<TempSample> tempFor(String dayKey) =>
      temperature.where((t) => t.dayKey == dayKey).toList();

  Map<String, List<HealthSample>> seriesByMetric(String dayKey) {
    final out = <String, List<HealthSample>>{};
    for (final s in series.where((e) => e.dayKey == dayKey)) {
      out.putIfAbsent(s.metric, () => []).add(s);
    }
    return out;
  }
}
