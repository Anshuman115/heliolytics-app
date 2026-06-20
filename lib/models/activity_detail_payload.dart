import 'package:heliolytics/models/day_metric.dart';

class ActivityDetailPayload {
  const ActivityDetailPayload.workout(this.workout) : session = null;
  const ActivityDetailPayload.session(this.session) : workout = null;

  final WorkoutMetric? workout;
  final ActivitySessionMetric? session;
}
