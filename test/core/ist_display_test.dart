import 'package:flutter_test/flutter_test.dart';

import 'package:heliolytics/models/activity_metric.dart';
import 'package:heliolytics/models/user_profile.dart';
import 'package:heliolytics/utils/formatters.dart';

void main() {
  group('measurement times render on the IST wall clock', () {
    test('an instant before IST midnight keeps its clock time', () {
      expect(formatChartTime(DateTime.utc(2026, 10, 20, 18, 29)), '23:59');
    });

    test('an instant after IST midnight shows the new day clock', () {
      expect(formatChartTime(DateTime.utc(2026, 10, 19, 18, 35)), '00:05');
    });

    test('a UTC+9 device instant is shown in IST', () {
      final deviceInstant = DateTime.parse('2026-10-20T19:00:00+09:00');
      expect(formatChartTime(deviceInstant), '15:30');
    });

    test('a workout span is shown in IST, not device time', () {
      final label = formatWorkoutTime(DateTime.utc(2026, 10, 20, 0, 0));
      expect(label, contains('Oct 20'));
      expect(label, contains('5:30'));
    });
  });

  group('date-only values never shift', () {
    test('a day key label keeps its calendar date', () {
      expect(formatSleepComparisonDay('1990-05-04'), 'Fri, May 4');
    });

    test('a birth date survives a parse and format round trip', () {
      expect(formatDateOnly(parseDateOnly('1990-05-04')), '1990-05-04');
    });

    test('a future birth date is rejected', () {
      expect(birthDateError('2999-01-01'), isNotNull);
    });
  });

  test('activity wire instants stay absolute UTC', () {
    final activity = ActivityMetric.fromJson({
      'kind': 'workout',
      'dayKey': '2026-10-20',
      'startedAt': '2026-10-19T18:35:00Z',
      'endedAt': '2026-10-19T19:05:00Z',
      'durationSec': 1800,
      'sportType': 1,
      'sportName': 'Run',
      'hasDetail': false,
    });
    expect(activity.startedAt.toUtc(), DateTime.utc(2026, 10, 19, 18, 35));
    expect(activity.toJson()['startedAt'], '2026-10-19T18:35:00.000Z');
  });
}
