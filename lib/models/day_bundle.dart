import 'package:heliolytics/models/day_metric.dart';
import 'package:heliolytics/utils/day_key.dart';

class DayBundle {
  final DayMetric day;
  final List<SleepMetric> sleep;
  final List<WorkoutMetric> workouts;
  final List<ActivitySessionMetric> activitySessions;

  const DayBundle({
    required this.day,
    this.sleep = const [],
    this.workouts = const [],
    this.activitySessions = const [],
  });

  bool get isFinal => isFinalDayKey(day.dayKey);

  /// The main overnight sleep for the day (not a nap), if any.
  SleepMetric? get mainSleep {
    SleepMetric? best;
    for (final s in sleep) {
      if (s.isNap) continue;
      if (best == null || s.score > best.score) best = s;
    }
    return best;
  }

  List<SleepMetric> get naps => sleep.where((s) => s.isNap).toList();

  Map<String, dynamic> toJson() => {
    'day': day.toJson(),
    'sleep': sleep.map((s) => s.toJson()).toList(),
    'workouts': workouts.map((w) => w.toJson()).toList(),
    'activitySessions': activitySessions.map((a) => a.toJson()).toList(),
  };

  factory DayBundle.fromJson(Map<String, dynamic> j) => DayBundle(
    day: DayMetric.fromJson(Map<String, dynamic>.from(j['day'] as Map)),
    sleep: (j['sleep'] as List<dynamic>? ?? [])
        .map((e) => SleepMetric.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList(),
    workouts: (j['workouts'] as List<dynamic>? ?? [])
        .map((e) => WorkoutMetric.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList(),
    activitySessions: (j['activitySessions'] as List<dynamic>? ?? [])
        .map(
          (e) => ActivitySessionMetric.fromJson(
            Map<String, dynamic>.from(e as Map),
          ),
        )
        .toList(),
  );
}
