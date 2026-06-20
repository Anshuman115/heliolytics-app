import 'package:heliolytics/models/day_metric.dart';
import 'package:heliolytics/models/health_sample.dart';
import 'package:heliolytics/models/hr_sample.dart';
import 'package:heliolytics/models/sync_coverage.dart';
import 'package:heliolytics/models/temp_sample.dart';

class CloudMetricsSnapshot {
  final List<DayMetric> days;
  final List<SleepMetric> sleep;
  final List<WorkoutMetric> workouts;
  final List<ActivitySessionMetric> activitySessions;
  final List<TempSample> temperature;
  final List<HealthSample> series;
  final List<HeartRateSample> heartRate;
  final DateTime? lastSyncedAt;
  final int? batteryPercent;
  final SyncCoverage? coverage;

  const CloudMetricsSnapshot({
    required this.days,
    this.sleep = const [],
    this.workouts = const [],
    this.activitySessions = const [],
    this.temperature = const [],
    this.series = const [],
    this.heartRate = const [],
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

  List<TempSample> tempFor(String dayKey) =>
      temperature.where((t) => t.dayKey == dayKey).toList();

  List<HeartRateSample> heartRateFor(String dayKey) {
    final list = heartRate.where((h) => h.dayKey == dayKey).toList()
      ..sort((a, b) => a.sampledAt.compareTo(b.sampledAt));
    return list;
  }

  HeartRateSample? latestHeartRateFor(String dayKey) {
    final list = heartRateFor(dayKey);
    return list.isEmpty ? null : list.last;
  }

  Map<String, List<HealthSample>> seriesByMetric(String dayKey) {
    final out = <String, List<HealthSample>>{};
    for (final s in series.where((e) => e.dayKey == dayKey)) {
      out.putIfAbsent(s.metric, () => []).add(s);
    }
    return out;
  }
}
