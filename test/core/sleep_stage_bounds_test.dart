import 'package:flutter_test/flutter_test.dart';
import 'package:heliolytics/models/sleep_stage.dart';
import 'package:heliolytics/utils/sleep_stage_bounds.dart';

void main() {
  test('finds ordered exclusive bounds from unordered inclusive stages', () {
    final start = DateTime.utc(2026, 7, 25, 20, 53);
    final bounds = sleepStageBounds([
      SleepStagePoint(
        start: start.add(const Duration(minutes: 20)),
        end: start.add(const Duration(minutes: 29)),
        type: 5,
      ),
      SleepStagePoint(
        start: start,
        end: start.add(const Duration(minutes: 19)),
        type: 4,
      ),
    ]);

    expect(bounds?.start, start);
    expect(bounds?.end, start.add(const Duration(minutes: 30)));
  });
}
