import 'package:flutter_test/flutter_test.dart';
import 'package:heliolytics/models/daily_health_scores.dart';
import 'package:heliolytics/models/day_bundle.dart';
import 'package:heliolytics/models/day_metric.dart';
import 'package:heliolytics/utils/health_monitor_readings.dart';

void main() {
  const day = DayMetric(dayKey: '2026-07-26', steps: 1000);
  final shorterHigherScore = SleepMetric(
    dayKey: day.dayKey,
    startedAt: DateTime.utc(2026, 7, 25, 21),
    score: 90,
    totalMins: 400,
    deepMins: 80,
    remMins: 90,
    lightMins: 230,
    wakeMins: 40,
  );
  final longerLowerScore = SleepMetric(
    dayKey: day.dayKey,
    startedAt: DateTime.utc(2026, 7, 25, 20),
    score: 70,
    totalMins: 430,
    deepMins: 70,
    remMins: 80,
    lightMins: 280,
  );

  test('main sleep matches the backend highest-score rule', () {
    final bundle = DayBundle(
      day: day,
      sleep: [longerLowerScore, shorterHigherScore],
    );
    expect(bundle.mainSleep, same(shorterHigherScore));
  });

  test('home readings only expose metrics backed by data', () {
    final bundle = DayBundle(day: day, sleep: [shorterHigherScore]);
    final readings = buildHomeHealthReadings(
      bundle: bundle,
      scores: const DailyHealthScores(
        dayKey: '2026-07-26',
        calories: 350,
        avgHeartRate: 72,
      ),
      allDays: const [],
    );
    final byLabel = {for (final reading in readings) reading.label: reading};

    expect(byLabel.keys, isNot(contains('VO2 MAX')));
    expect(byLabel.keys, isNot(contains('SLEEP NEEDED')));
    expect(byLabel.keys, isNot(contains('SLEEP DEBT')));
    expect(byLabel.keys, isNot(contains('SLEEP CONSISTENCY')));
    expect(byLabel['SLEEP EFFICIENCY']?.value, '91');
  });
}
