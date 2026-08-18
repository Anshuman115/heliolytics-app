class DailyHealthScores {
  final String dayKey;
  final int? calories;
  final int? avgHeartRate;
  final int? sleepEfficiencyPct;

  const DailyHealthScores({
    required this.dayKey,
    this.calories,
    this.avgHeartRate,
    this.sleepEfficiencyPct,
  });

  factory DailyHealthScores.empty(String dayKey) =>
      DailyHealthScores(dayKey: dayKey);

  /// Cache round-trip format (used by DailyHealthScoresCacheStorage) — same
  /// key names [fromJson] reads, so caching and backend parsing share one
  /// source of truth.
  Map<String, dynamic> toJson() => {
    'dayKey': dayKey,
    'caloriesTotal': calories,
    'avgHr': avgHeartRate,
    'sleepEfficiencyPct': sleepEfficiencyPct,
  };

  /// Parses both one entry from the backend's `/api/v1/daily-health-scores`
  /// `{"days": [tile, ...]}` response (each tile already carries its own
  /// `dayKey`) and our own cached [toJson] output — same key names either way.
  factory DailyHealthScores.fromJson(Map<String, dynamic> j) =>
      DailyHealthScores(
        dayKey: j['dayKey'] as String,
        calories: ((j['caloriesTotal'] ?? j['calories']) as num?)?.toInt(),
        avgHeartRate: (j['avgHr'] as num?)?.toInt(),
        sleepEfficiencyPct: (j['sleepEfficiencyPct'] as num?)?.toInt(),
      );
}
