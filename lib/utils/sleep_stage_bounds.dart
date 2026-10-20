import 'package:heliolytics/models/sleep_stage.dart';

typedef SleepStageBounds = ({DateTime start, DateTime end});

/// Bounds of a stage list. Stage ends are half-open, so the last end is final.
SleepStageBounds? sleepStageBounds(List<SleepStagePoint> stages) {
  if (stages.isEmpty) return null;
  var start = stages.first.start;
  var end = stages.first.end;
  for (final stage in stages.skip(1)) {
    if (stage.start.isBefore(start)) start = stage.start;
    if (stage.end.isAfter(end)) end = stage.end;
  }
  return (start: start, end: end);
}
