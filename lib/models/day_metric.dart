import 'sleep_stage.dart';

class DayMetric {
  final String dayKey;
  final int steps;
  final int? paiScore;
  final int? readiness;
  final int? spo2Avg;
  final int? hrvRmssd;
  final int? restingHr;
  final int? stressAvg;
  final int? sleepScore;
  final int? sleepMins;
  final int? sleepDeepMins;
  final int? sleepRemMins;
  final int? sleepLightMins;
  final double? tempAvgC;
  final int workoutCount;
  final int activitySessionCount;
  final int napCount;
  final DateTime? updatedAt;

  const DayMetric({
    required this.dayKey,
    required this.steps,
    this.paiScore,
    this.readiness,
    this.spo2Avg,
    this.hrvRmssd,
    this.restingHr,
    this.stressAvg,
    this.sleepScore,
    this.sleepMins,
    this.sleepDeepMins,
    this.sleepRemMins,
    this.sleepLightMins,
    this.tempAvgC,
    this.workoutCount = 0,
    this.activitySessionCount = 0,
    this.napCount = 0,
    this.updatedAt,
  });

  factory DayMetric.fromJson(Map<String, dynamic> j) => DayMetric(
        dayKey: j['dayKey'] as String,
        steps: (j['steps'] as num?)?.toInt() ?? 0,
        paiScore: (j['paiScore'] as num?)?.toInt(),
        readiness: (j['readiness'] as num?)?.toInt(),
        spo2Avg: (j['spo2Avg'] as num?)?.toInt(),
        hrvRmssd: (j['hrvRmssd'] as num?)?.toInt(),
        restingHr: (j['restingHr'] as num?)?.toInt(),
        stressAvg: (j['stressAvg'] as num?)?.toInt(),
        sleepScore: (j['sleepScore'] as num?)?.toInt(),
        sleepMins: (j['sleepMins'] as num?)?.toInt(),
        sleepDeepMins: (j['sleepDeepMins'] as num?)?.toInt(),
        sleepRemMins: (j['sleepRemMins'] as num?)?.toInt(),
        sleepLightMins: (j['sleepLightMins'] as num?)?.toInt(),
        tempAvgC: (j['tempAvgC'] as num?)?.toDouble(),
        workoutCount: (j['workoutCount'] as num?)?.toInt() ?? 0,
        activitySessionCount: (j['activitySessionCount'] as num?)?.toInt() ?? 0,
        napCount: (j['napCount'] as num?)?.toInt() ?? 0,
        updatedAt: j['updatedAt'] != null
            ? DateTime.parse(j['updatedAt'] as String).toLocal()
            : null,
      );
}

class SleepMetric {
  final String dayKey;
  final DateTime startedAt;
  final int score;
  final int totalMins;
  final int deepMins;
  final int remMins;
  final int lightMins;
  final int wakeMins;
  final bool isNap;
  final List<SleepStagePoint> stages;

  const SleepMetric({
    required this.dayKey,
    required this.startedAt,
    required this.score,
    required this.totalMins,
    required this.deepMins,
    required this.remMins,
    required this.lightMins,
    this.wakeMins = 0,
    this.isNap = false,
    this.stages = const [],
  });

  factory SleepMetric.fromJson(Map<String, dynamic> j) {
    final rawStages = j['stages'] as List<dynamic>? ?? [];
    return SleepMetric(
      dayKey: j['dayKey'] as String,
      startedAt: DateTime.parse(j['startedAt'] as String).toLocal(),
      score: (j['score'] as num).toInt(),
      totalMins: (j['totalMins'] as num).toInt(),
      deepMins: (j['deepMins'] as num).toInt(),
      remMins: (j['remMins'] as num).toInt(),
      lightMins: (j['lightMins'] as num).toInt(),
      wakeMins: (j['wakeMins'] as num?)?.toInt() ?? 0,
      isNap: j['isNap'] as bool? ?? false,
      stages: rawStages
          .map((e) => SleepStagePoint.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
    );
  }
}

/// Auto-detected strap activity (0x3B) — same shape as manual workouts.
class ActivitySessionMetric {
  final String dayKey;
  final DateTime startedAt;
  final int sportType;
  final String sportName;
  final int durationSec;
  final int? calories;
  final int? avgHr;
  final int? maxHr;

  const ActivitySessionMetric({
    required this.dayKey,
    required this.startedAt,
    required this.sportType,
    this.sportName = '',
    required this.durationSec,
    this.calories,
    this.avgHr,
    this.maxHr,
  });

  factory ActivitySessionMetric.fromJson(Map<String, dynamic> j) => ActivitySessionMetric(
        dayKey: j['dayKey'] as String,
        startedAt: DateTime.parse(j['startedAt'] as String).toLocal(),
        sportType: (j['sportType'] as num).toInt(),
        sportName: j['sportName'] as String? ?? '',
        durationSec: (j['durationSec'] as num).toInt(),
        calories: (j['calories'] as num?)?.toInt(),
        avgHr: (j['avgHr'] as num?)?.toInt(),
        maxHr: (j['maxHr'] as num?)?.toInt(),
      );
}

class WorkoutMetric {
  final String dayKey;
  final DateTime startedAt;
  final int sportType;
  final String sportName;
  final int durationSec;
  final int? calories;
  final int? avgHr;
  final int? maxHr;

  const WorkoutMetric({
    required this.dayKey,
    required this.startedAt,
    required this.sportType,
    this.sportName = '',
    required this.durationSec,
    this.calories,
    this.avgHr,
    this.maxHr,
  });

  factory WorkoutMetric.fromJson(Map<String, dynamic> j) => WorkoutMetric(
        dayKey: j['dayKey'] as String,
        startedAt: DateTime.parse(j['startedAt'] as String).toLocal(),
        sportType: (j['sportType'] as num).toInt(),
        sportName: j['sportName'] as String? ?? '',
        durationSec: (j['durationSec'] as num).toInt(),
        calories: (j['calories'] as num?)?.toInt(),
        avgHr: (j['avgHr'] as num?)?.toInt(),
        maxHr: (j['maxHr'] as num?)?.toInt(),
      );
}
