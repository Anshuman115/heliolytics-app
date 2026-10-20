import 'package:heliolytics/models/activity_metric.dart';
import 'package:heliolytics/models/day_metric.dart';
import 'package:heliolytics/models/sleep_stage.dart';

/// Everything the selected day shows, from three C3 endpoints.
class DayBundle {
  const DayBundle({this.day, this.sleep, this.activities = const []});

  /// Null when the server has no supported metrics for the day.
  final DayMetric? day;
  final SleepDay? sleep;
  final List<ActivityMetric> activities;

  bool get hasData =>
      day != null || (sleep?.hasAnySession ?? false) || activities.isNotEmpty;

  SleepSession? get mainSleep => sleep?.main;

  List<SleepSession> get naps => sleep?.naps ?? const [];

  Map<String, dynamic> toJson() => {
    'day': day?.toJson(),
    'sleep': sleep?.toJson(),
    'activities': activities.map((a) => a.toJson()).toList(),
  };

  factory DayBundle.fromJson(Map<String, dynamic> j) {
    final rawDay = j['day'];
    final rawSleep = j['sleep'];
    final rawActivities = j['activities'];
    return DayBundle(
      day: rawDay is Map
          ? DayMetric.fromJson(Map<String, dynamic>.from(rawDay))
          : null,
      sleep: rawSleep is Map
          ? SleepDay.fromJson(Map<String, dynamic>.from(rawSleep))
          : null,
      activities: rawActivities is List
          ? rawActivities
                .map(
                  (e) => ActivityMetric.fromJson(
                    Map<String, dynamic>.from(e as Map),
                  ),
                )
                .toList()
          : const [],
    );
  }
}
