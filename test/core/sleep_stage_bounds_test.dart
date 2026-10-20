import 'package:flutter_test/flutter_test.dart';

import 'package:heliolytics/models/sleep_stage.dart';
import 'package:heliolytics/utils/sleep_stage_bounds.dart';

void main() {
  test('returns the exclusive end without padding a minute', () {
    final start = DateTime.utc(2026, 7, 25, 20, 53);
    final bounds = sleepStageBounds([
      SleepStagePoint(
        start: start.add(const Duration(minutes: 20)),
        end: start.add(const Duration(minutes: 29)),
        type: 5,
      ),
      SleepStagePoint(
        start: start,
        end: start.add(const Duration(minutes: 20)),
        type: 4,
      ),
    ]);

    expect(bounds?.start, start);
    expect(bounds?.end, start.add(const Duration(minutes: 29)));
  });

  test('adjacent half-open stages do not overlap or add a minute', () {
    final start = DateTime.utc(2026, 7, 25, 1);
    final bounds = sleepStageBounds([
      SleepStagePoint(
        start: start,
        end: start.add(const Duration(minutes: 5)),
        type: 4,
      ),
      SleepStagePoint(
        start: start.add(const Duration(minutes: 5)),
        end: start.add(const Duration(minutes: 8)),
        type: 5,
      ),
    ]);
    final resolved = bounds!;

    expect(resolved.end.difference(resolved.start), const Duration(minutes: 8));
  });

  test('empty stages have no bounds', () {
    expect(sleepStageBounds(const []), isNull);
  });
}
