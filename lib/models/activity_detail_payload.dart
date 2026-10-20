import 'package:heliolytics/models/activity_metric.dart';

/// One complete activity, used by the activity detail route.
class ActivityDetailPayload {
  const ActivityDetailPayload(this.activity);

  final ActivityMetric activity;
}
