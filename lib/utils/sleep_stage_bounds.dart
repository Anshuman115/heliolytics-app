import 'package:heliolytics/models/sleep_stage.dart';

typedef SleepStageBounds = ({DateTime start, DateTime end});

SleepStageBounds? sleepStageBounds(List<SleepStagePoint> stages) {
  if (stages.isEmpty) return null;
  var start = stages.first.start;
  var inclusiveEnd = stages.first.end;
  for (final stage in stages.skip(1)) {
    if (stage.start.isBefore(start)) start = stage.start;
    if (stage.end.isAfter(inclusiveEnd)) inclusiveEnd = stage.end;
  }
  return (start: start, end: inclusiveEnd.add(const Duration(minutes: 1)));
}
