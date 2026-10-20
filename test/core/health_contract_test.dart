import 'package:flutter_test/flutter_test.dart';

import 'package:heliolytics/models/activity_metric.dart';
import 'package:heliolytics/models/day_bundle.dart';
import 'package:heliolytics/models/day_metric.dart';
import 'package:heliolytics/models/protocol_exception.dart';
import 'package:heliolytics/models/readiness_components.dart';
import 'package:heliolytics/models/sleep_stage.dart';
import 'package:heliolytics/models/sync_coverage.dart';

Map<String, dynamic> _dayJson() => {
  'dayKey': '2026-07-26',
  'steps': null,
  'avgHr': 61.4,
  'restingHr': 52.7,
  'hrvRmssd': 52.7,
  'respRate': 14.25,
  'spo2Avg': 97.12,
  'spo2Min': 95,
  'spo2SleepAvg': null,
  'spo2SleepMin': null,
  'spo2Samples': 0,
  'stressAvg': 23.6,
  'skinTempNightC': 32.12,
  'skinTempDeviationC': null,
  'sleepScore': null,
  'sleepMins': null,
  'sleepDeepMins': null,
  'sleepRemMins': null,
  'sleepLightMins': null,
  'sleepWakeMins': null,
  'timeInBedMins': null,
  'sleepEfficiencyPct': null,
  'napCount': 0,
  'workoutCount': 0,
  'autoActivityCount': 0,
  'workoutCalories': null,
  'trainingLoad': null,
  'paiScore': null,
  'readiness': null,
  'readinessStatus': null,
  'readinessBand': null,
  'readinessComponents': null,
  'updatedAt': '2026-07-27T03:00:00Z',
};

void main() {
  test('daily metrics keep precision and nulls through a cache round trip', () {
    final day = DayMetric.fromJson(_dayJson());
    expect(day.steps, isNull);
    expect(day.avgHr, 61.4);
    expect(day.hrvRmssd, 52.7);
    expect(day.respRate, 14.25);
    expect(day.stressAvg, 23.6);
    expect(day.skinTempNightC, 32.12);
    expect(day.spo2Samples, 0);
    expect(day.sleepMins, isNull);
    expect(day.hasMeasuredSpo2, isFalse);

    final round = DayMetric.fromJson(day.toJson());
    expect(round.avgHr, 61.4);
    expect(round.respRate, 14.25);
    expect(round.skinTempNightC, 32.12);
    expect(round.steps, isNull);
    expect(round.sleepEfficiencyPct, isNull);
  });

  test('unknown calorie keys never become workout calories', () {
    final json = _dayJson()
      ..['caloriesTotal'] = 2500
      ..['calories'] = 2400;
    final day = DayMetric.fromJson(json);
    expect(day.workoutCalories, isNull);
  });

  test('a daily metric without updatedAt is rejected', () {
    final json = _dayJson()..remove('updatedAt');
    expect(() => DayMetric.fromJson(json), throwsA(isA<FormatException>()));
  });

  test('sleep keeps explicit main and naps, with a null nap score', () {
    final sleep = SleepDay.fromJson({
      'dayKey': '2026-07-26',
      'main': {
        'startedAt': '2026-07-25T20:53:00Z',
        'endedAt': '2026-07-26T04:53:00Z',
        'score': 70,
        'totalMins': 430,
        'deepMins': 70,
        'remMins': 80,
        'lightMins': 280,
        'wakeMins': 0,
        'stagesTruncated': true,
        'stages': [
          {
            'start': '2026-07-25T20:53:00Z',
            'end': '2026-07-25T21:12:00Z',
            'type': 4,
          },
          {
            'start': '2026-07-25T21:12:00Z',
            'end': '2026-07-25T21:21:00Z',
            'type': 5,
          },
        ],
      },
      'naps': [
        {
          'startedAt': '2026-07-26T12:00:00Z',
          'endedAt': '2026-07-26T12:40:00Z',
          'score': null,
          'totalMins': 40,
          'deepMins': 0,
          'remMins': 10,
          'lightMins': 30,
          'wakeMins': 0,
          'stagesTruncated': false,
          'stages': <dynamic>[],
        },
      ],
    });

    expect(sleep.main!.totalMins, 430);
    expect(sleep.main!.score, 70);
    expect(sleep.main!.stagesTruncated, isTrue);
    expect(sleep.naps.single.score, isNull);
    expect(sleep.naps.single.totalMins, 40);
    expect(sleep.main!.stages.first.end, DateTime.utc(2026, 7, 25, 21, 12));
  });

  test('day bundle keeps a null day distinct from empty data', () {
    final bundle = DayBundle.fromJson({
      'day': null,
      'sleep': null,
      'activities': <dynamic>[],
    });
    expect(bundle.day, isNull);
    expect(bundle.mainSleep, isNull);
    expect(bundle.hasData, isFalse);

    final withDay = DayBundle.fromJson({
      'day': _dayJson(),
      'sleep': null,
      'activities': <dynamic>[],
    });
    expect(withDay.hasData, isTrue);
  });

  test('coverage requires exactly the eleven measured codes', () {
    final types = <String, dynamic>{
      for (final code in SyncCoverage.measuredTypeCodes) code: null,
    };
    final coverage = SyncCoverage.fromJson({
      'hasData': false,
      'lastIngestAt': null,
      'dataThrough': null,
      'types': types,
    });
    expect(coverage.types.keys.toSet(), SyncCoverage.measuredTypeCodes.toSet());
    expect(coverage.hasData, isFalse);

    final withRawOnly = {...types, '0x26': null};
    expect(
      () => SyncCoverage.fromJson({'hasData': true, 'types': withRawOnly}),
      throwsA(isA<ProtocolException>()),
    );

    final missing = Map<String, dynamic>.from(types)..remove('0x25');
    expect(
      () => SyncCoverage.fromJson({'hasData': true, 'types': missing}),
      throwsA(isA<ProtocolException>()),
    );

    expect(
      () => SyncCoverage.fromJson({'types': types}),
      throwsA(isA<ProtocolException>()),
    );
  });

  test('activity keeps every nullable field and its kind', () {
    final json = {
      'kind': 'auto',
      'dayKey': '2026-07-26',
      'startedAt': '2026-07-26T06:00:00Z',
      'endedAt': '2026-07-26T06:30:00Z',
      'durationSec': 1800,
      'sportType': 0,
      'sportName': 'Walk',
      'calories': null,
      'avgHr': null,
      'maxHr': null,
      'minHr': null,
      'steps': null,
      'hasDetail': false,
    };
    final activity = ActivityMetric.fromJson(json);
    expect(activity.kind, ActivityKind.auto);
    expect(activity.hasDetail, isFalse);
    expect(activity.calories, isNull);
    expect(activity.steps, isNull);
    expect(activity.minHr, isNull);
    expect(ActivityMetric.fromJson(activity.toJson()).kind, ActivityKind.auto);

    expect(
      () => ActivityMetric.fromJson({...json, 'kind': 'other'}),
      throwsA(isA<FormatException>()),
    );
  });

  test('readiness early states keep nulls, baselines and flags', () {
    final components = ReadinessComponents.fromJson({
      'status': 'calibrating',
      'score': null,
      'raw': null,
      'baselineNights': 6,
      'components': [
        {
          'name': 'hrv',
          'value': 48.2,
          'x': null,
          'center': 47.0,
          'sd': null,
          'sdPersonal': null,
          'n': 120,
          'z': null,
          'sub': null,
          'weight': null,
          'points': null,
          'nights': 6,
          'chronic': null,
          'ratio': null,
          'dev': null,
        },
      ],
      'flags': ['missing:resp_rate', 'temp_high'],
    });
    expect(components.status, ReadinessStatus.calibrating);
    expect(components.score, isNull);
    expect(components.baselineNights, 6);
    expect(components.flags, ['missing:resp_rate', 'temp_high']);

    final round = ReadinessComponents.fromJson(components.toJson());
    expect(round.components.single.x, isNull);
    expect(round.components.single.center, 47.0);
    expect(round.components.single.nights, 6);
    expect(round.flags, components.flags);
  });
}
