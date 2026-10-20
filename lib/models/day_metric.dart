import 'package:heliolytics/models/readiness_components.dart';

/// One day of consolidated C3 daily metrics. Missing measurements stay null.
class DayMetric {
  const DayMetric({
    required this.dayKey,
    required this.updatedAt,
    this.steps,
    this.avgHr,
    this.restingHr,
    this.hrvRmssd,
    this.respRate,
    this.spo2Avg,
    this.spo2Min,
    this.spo2SleepAvg,
    this.spo2SleepMin,
    this.spo2Samples = 0,
    this.stressAvg,
    this.skinTempNightC,
    this.skinTempDeviationC,
    this.sleepScore,
    this.sleepMins,
    this.sleepDeepMins,
    this.sleepRemMins,
    this.sleepLightMins,
    this.sleepWakeMins,
    this.timeInBedMins,
    this.sleepEfficiencyPct,
    this.napCount = 0,
    this.workoutCount = 0,
    this.autoActivityCount = 0,
    this.workoutCalories,
    this.trainingLoad,
    this.paiScore,
    this.readiness,
    this.readinessStatus,
    this.readinessBand,
    this.readinessComponents,
  });

  final String dayKey;
  final DateTime updatedAt;
  final int? steps;
  final double? avgHr;
  final double? restingHr;
  final double? hrvRmssd;
  final double? respRate;
  final double? spo2Avg;
  final int? spo2Min;
  final double? spo2SleepAvg;
  final int? spo2SleepMin;
  final int spo2Samples;
  final double? stressAvg;
  final double? skinTempNightC;
  final double? skinTempDeviationC;
  final int? sleepScore;
  final int? sleepMins;
  final int? sleepDeepMins;
  final int? sleepRemMins;
  final int? sleepLightMins;
  final int? sleepWakeMins;
  final int? timeInBedMins;
  final int? sleepEfficiencyPct;
  final int napCount;
  final int workoutCount;
  final int autoActivityCount;
  final int? workoutCalories;
  final double? trainingLoad;
  final int? paiScore;
  final int? readiness;
  final ReadinessStatus? readinessStatus;
  final ReadinessBand? readinessBand;
  final ReadinessComponents? readinessComponents;

  /// Measured SpO2 needs at least three samples before a mean is shown.
  bool get hasMeasuredSpo2 => spo2Samples > 0 && spo2Avg != null;

  factory DayMetric.fromJson(Map<String, dynamic> j) {
    final dayKey = j['dayKey'];
    if (dayKey is! String) {
      throw const FormatException('Daily metric has no dayKey');
    }
    final updatedAt = j['updatedAt'];
    if (updatedAt is! String) {
      throw FormatException('Daily metric $dayKey has no updatedAt');
    }
    return DayMetric(
      dayKey: dayKey,
      updatedAt: DateTime.parse(updatedAt).toUtc(),
      steps: _int(j['steps']),
      avgHr: _double(j['avgHr']),
      restingHr: _double(j['restingHr']),
      hrvRmssd: _double(j['hrvRmssd']),
      respRate: _double(j['respRate']),
      spo2Avg: _double(j['spo2Avg']),
      spo2Min: _int(j['spo2Min']),
      spo2SleepAvg: _double(j['spo2SleepAvg']),
      spo2SleepMin: _int(j['spo2SleepMin']),
      spo2Samples: _int(j['spo2Samples']) ?? 0,
      stressAvg: _double(j['stressAvg']),
      skinTempNightC: _double(j['skinTempNightC']),
      skinTempDeviationC: _double(j['skinTempDeviationC']),
      sleepScore: _int(j['sleepScore']),
      sleepMins: _int(j['sleepMins']),
      sleepDeepMins: _int(j['sleepDeepMins']),
      sleepRemMins: _int(j['sleepRemMins']),
      sleepLightMins: _int(j['sleepLightMins']),
      sleepWakeMins: _int(j['sleepWakeMins']),
      timeInBedMins: _int(j['timeInBedMins']),
      sleepEfficiencyPct: _int(j['sleepEfficiencyPct']),
      napCount: _int(j['napCount']) ?? 0,
      workoutCount: _int(j['workoutCount']) ?? 0,
      autoActivityCount: _int(j['autoActivityCount']) ?? 0,
      workoutCalories: _int(j['workoutCalories']),
      trainingLoad: _double(j['trainingLoad']),
      paiScore: _int(j['paiScore']),
      readiness: _int(j['readiness']),
      readinessStatus: ReadinessStatus.parse(j['readinessStatus']),
      readinessBand: ReadinessBand.parse(j['readinessBand']),
      readinessComponents: j['readinessComponents'] is Map
          ? ReadinessComponents.fromJson(
              Map<String, dynamic>.from(j['readinessComponents'] as Map),
            )
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'dayKey': dayKey,
    'updatedAt': updatedAt.toUtc().toIso8601String(),
    'steps': steps,
    'avgHr': avgHr,
    'restingHr': restingHr,
    'hrvRmssd': hrvRmssd,
    'respRate': respRate,
    'spo2Avg': spo2Avg,
    'spo2Min': spo2Min,
    'spo2SleepAvg': spo2SleepAvg,
    'spo2SleepMin': spo2SleepMin,
    'spo2Samples': spo2Samples,
    'stressAvg': stressAvg,
    'skinTempNightC': skinTempNightC,
    'skinTempDeviationC': skinTempDeviationC,
    'sleepScore': sleepScore,
    'sleepMins': sleepMins,
    'sleepDeepMins': sleepDeepMins,
    'sleepRemMins': sleepRemMins,
    'sleepLightMins': sleepLightMins,
    'sleepWakeMins': sleepWakeMins,
    'timeInBedMins': timeInBedMins,
    'sleepEfficiencyPct': sleepEfficiencyPct,
    'napCount': napCount,
    'workoutCount': workoutCount,
    'autoActivityCount': autoActivityCount,
    'workoutCalories': workoutCalories,
    'trainingLoad': trainingLoad,
    'paiScore': paiScore,
    'readiness': readiness,
    'readinessStatus': readinessStatus?.wire,
    'readinessBand': readinessBand?.name,
    'readinessComponents': readinessComponents?.toJson(),
  };
}

double? _double(Object? raw) => raw is num ? raw.toDouble() : null;

int? _int(Object? raw) => raw is num ? raw.toInt() : null;
