import 'package:heliolytics/models/activity_detail_payload.dart';
import 'package:heliolytics/models/activity_metric.dart';
import 'package:heliolytics/utils/sport_labels.dart';

/// Feed row for either activity kind.
class ActivityFeedItem {
  const ActivityFeedItem(this.activity);

  final ActivityMetric activity;

  String get title => activity.sportName.isEmpty
      ? sportLabel(activity.sportType)
      : activity.sportName;
  DateTime get startedAt => activity.startedAt;
  int get durationSec => activity.durationSec;
  int get sportType => activity.sportType;
  bool get isWorkout => activity.isWorkout;
  ActivityDetailPayload get payload => ActivityDetailPayload(activity);

  String get kindLabel => isWorkout ? 'WORKOUT' : 'AUTO DETECTED';
}
