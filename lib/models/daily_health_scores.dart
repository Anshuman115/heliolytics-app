class DailyHealthScores {
  final String dayKey;
  final int? vo2Max;
  final int? calories;
  final int? avgHeartRate;
  final int? sleepEfficiencyPct;
  final int? sleepDebtMins;
  final int? sleepConsistencyPct;
  final int? sleepNeededMins;

  const DailyHealthScores({
    required this.dayKey,
    this.vo2Max,
    this.calories,
    this.avgHeartRate,
    this.sleepEfficiencyPct,
    this.sleepDebtMins,
    this.sleepConsistencyPct,
    this.sleepNeededMins,
  });

  factory DailyHealthScores.empty(String dayKey) => DailyHealthScores(dayKey: dayKey);

  Map<String, dynamic> toJson() => {
        'dayKey': dayKey,
        'vo2Max': vo2Max,
        'calories': calories,
        'avgHeartRate': avgHeartRate,
        'sleepEfficiencyPct': sleepEfficiencyPct,
        'sleepDebtMins': sleepDebtMins,
        'sleepConsistencyPct': sleepConsistencyPct,
        'sleepNeededMins': sleepNeededMins,
      };

  factory DailyHealthScores.fromJson(Map<String, dynamic> j) => DailyHealthScores(
        dayKey: j['dayKey'] as String,
        vo2Max: (j['vo2Max'] as num?)?.toInt(),
        calories: (j['calories'] as num?)?.toInt(),
        avgHeartRate: (j['avgHeartRate'] as num?)?.toInt(),
        sleepEfficiencyPct: (j['sleepEfficiencyPct'] as num?)?.toInt(),
        sleepDebtMins: (j['sleepDebtMins'] as num?)?.toInt(),
        sleepConsistencyPct: (j['sleepConsistencyPct'] as num?)?.toInt(),
        sleepNeededMins: (j['sleepNeededMins'] as num?)?.toInt(),
      );
}
