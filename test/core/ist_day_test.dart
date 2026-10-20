import 'package:flutter_test/flutter_test.dart';

import 'package:heliolytics/providers/selected_day_provider.dart';
import 'package:heliolytics/utils/day_key.dart';
import 'package:heliolytics/utils/formatters.dart';
import 'package:heliolytics/utils/ist_time.dart';

void main() {
  // IST midnight is 18:30 UTC: 2026-10-21T00:00 IST.
  final beforeMidnight = DateTime.utc(2026, 10, 20, 18, 29, 59);
  final afterMidnight = DateTime.utc(2026, 10, 20, 18, 30);

  group('the IST day turns over at 18:30 UTC', () {
    test('one second before midnight is the earlier day', () {
      expect(todayDayKey(now: beforeMidnight), '2026-10-20');
    });

    test('midnight starts the next IST day', () {
      expect(todayDayKey(now: afterMidnight), '2026-10-21');
    });

    test('the month turns over at IST midnight', () {
      expect(
        todayDayKey(now: DateTime.utc(2026, 10, 31, 18, 30)),
        '2026-11-01',
      );
    });

    test('the year turns over at IST midnight', () {
      expect(
        todayDayKey(now: DateTime.utc(2026, 12, 31, 18, 30)),
        '2027-01-01',
      );
    });

    test('a leap day starts at IST midnight', () {
      expect(todayDayKey(now: DateTime.utc(2028, 2, 28, 18, 30)), '2028-02-29');
    });
  });

  group('finished days follow the IST day', () {
    test('today is never final', () {
      expect(isFinalDayKey('2026-10-20', now: beforeMidnight), isFalse);
    });

    test('a day becomes final at IST midnight', () {
      expect(isFinalDayKey('2026-10-20', now: afterMidnight), isTrue);
    });

    test('a future day is never final', () {
      expect(isFinalDayKey('2026-10-21', now: afterMidnight), isFalse);
    });
  });

  group('day key stepping stays exact', () {
    test('month end', () {
      expect(shiftDayKey('2026-10-31', 1), '2026-11-01');
    });

    test('year end', () {
      expect(shiftDayKey('2027-01-01', -1), '2026-12-31');
    });

    test('leap day', () {
      expect(shiftDayKey('2028-02-28', 1), '2028-02-29');
    });
  });

  group('navigation clamps at IST today', () {
    test('next from yesterday reaches today', () {
      expect(stepDayKey('2026-10-19', 1, now: beforeMidnight), '2026-10-20');
    });

    test('next from today is refused', () {
      expect(stepDayKey('2026-10-20', 1, now: beforeMidnight), isNull);
    });

    test('today opens once the IST day turns', () {
      expect(stepDayKey('2026-10-20', 1, now: afterMidnight), '2026-10-21');
    });

    test('previous always steps back', () {
      expect(stepDayKey('2026-10-20', -1, now: afterMidnight), '2026-10-19');
    });
  });

  group('day labels follow IST today', () {
    test('today', () {
      expect(formatDayLabel('2026-10-20', now: beforeMidnight), 'Today');
      expect(formatNavDayLabel('2026-10-20', now: beforeMidnight), 'TODAY');
    });

    test('yesterday after IST midnight', () {
      expect(formatDayLabel('2026-10-20', now: afterMidnight), 'Yesterday');
      expect(formatNavDayLabel('2026-10-20', now: afterMidnight), 'YESTERDAY');
    });

    test('older days keep their date', () {
      expect(formatDayLabel('2026-10-18', now: afterMidnight), 'Sun, Oct 18');
      expect(
        formatNavDayLabel('2026-10-18', now: afterMidnight),
        'SUN, OCT 18',
      );
    });
  });

  test('clock times render on the IST wall clock', () {
    expect(
      _squash(formatTimeOfDay(DateTime.utc(2026, 10, 20, 0, 0))),
      '5:30 AM',
    );
    expect(
      _squash(formatTimeOfDay(DateTime.utc(2026, 10, 20, 18, 29))),
      '11:59 PM',
    );
  });

  group('IST days ago ignore phone DST shifts', () {
    // Los Angeles springs forward on 2027-03-14 and falls back on 2027-11-07.
    test('spring forward', () {
      final now = DateTime.utc(2027, 3, 15, 0, 0);
      expect(dayKeyFor(istDaysAgo(1, now: now)), '2027-03-14');
      expect(dayKeyFor(istDaysAgo(2, now: now)), '2027-03-13');
    });

    test('fall back', () {
      final now = DateTime.utc(2027, 11, 8, 0, 0);
      expect(dayKeyFor(istDaysAgo(1, now: now)), '2027-11-07');
      expect(dayKeyFor(istDaysAgo(2, now: now)), '2027-11-06');
    });
  });
}

/// Collapses normal, no-break and narrow no-break spaces to one space.
String _squash(String value) =>
    value.replaceAll(RegExp(r'[\s\u00a0\u202f]+'), ' ');
