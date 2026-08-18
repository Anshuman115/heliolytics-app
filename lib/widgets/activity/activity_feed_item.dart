import 'package:heliolytics/models/activity_detail_payload.dart';
import 'package:heliolytics/models/day_metric.dart';
import 'package:heliolytics/utils/sport_labels.dart';

class ActivityFeedItem {
  const ActivityFeedItem({
    required this.title,
    required this.startedAt,
    required this.durationSec,
    required this.sportType,
    required this.isWorkout,
    required this.payload,
  });

  factory ActivityFeedItem.workout(WorkoutMetric item) => ActivityFeedItem(
    title: item.sportName.isEmpty ? sportLabel(item.sportType) : item.sportName,
    startedAt: item.startedAt,
    durationSec: item.durationSec,
    sportType: item.sportType,
    isWorkout: true,
    payload: ActivityDetailPayload.workout(item),
  );

  factory ActivityFeedItem.session(ActivitySessionMetric item) =>
      ActivityFeedItem(
        title: item.sportName.isEmpty
            ? sportLabel(item.sportType)
            : item.sportName,
        startedAt: item.startedAt,
        durationSec: item.durationSec,
        sportType: item.sportType,
        isWorkout: false,
        payload: ActivityDetailPayload.session(item),
      );

  final String title;
  final DateTime startedAt;
  final int durationSec;
  final int sportType;
  final bool isWorkout;
  final ActivityDetailPayload payload;
}
