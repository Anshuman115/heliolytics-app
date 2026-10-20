/// One activity from `GET /api/activities`; [kind] separates recorded
/// workouts from heuristic auto-detected activities.
enum ActivityKind {
  workout,
  auto;

  static ActivityKind? parse(Object? raw) => switch (raw) {
    'workout' => workout,
    'auto' => auto,
    _ => null,
  };

  String get wire => switch (this) {
    ActivityKind.workout => 'workout',
    ActivityKind.auto => 'auto',
  };

  String get label => switch (this) {
    ActivityKind.workout => 'Recorded workout',
    ActivityKind.auto => 'Auto-detected',
  };
}

class ActivityMetric {
  const ActivityMetric({
    required this.kind,
    required this.dayKey,
    required this.startedAt,
    required this.endedAt,
    required this.durationSec,
    required this.sportType,
    required this.sportName,
    required this.hasDetail,
    this.calories,
    this.avgHr,
    this.maxHr,
    this.minHr,
    this.steps,
  });

  final ActivityKind kind;
  final String dayKey;
  final DateTime startedAt;
  final DateTime endedAt;
  final int durationSec;
  final int sportType;
  final String sportName;
  final bool hasDetail;
  final int? calories;
  final int? avgHr;
  final int? maxHr;
  final int? minHr;
  final int? steps;

  bool get isWorkout => kind == ActivityKind.workout;

  /// Stable identity for navigation; start time plus kind is unique per C1.
  String get id => '${kind.wire}:${startedAt.toUtc().toIso8601String()}';

  factory ActivityMetric.fromJson(Map<String, dynamic> j) {
    final kind = ActivityKind.parse(j['kind']);
    if (kind == null) {
      throw FormatException('Unknown activity kind: ${j['kind']}');
    }
    return ActivityMetric(
      kind: kind,
      dayKey: j['dayKey'] as String,
      startedAt: DateTime.parse(j['startedAt'] as String).toUtc(),
      endedAt: DateTime.parse(j['endedAt'] as String).toUtc(),
      durationSec: (j['durationSec'] as num).toInt(),
      sportType: (j['sportType'] as num).toInt(),
      sportName: (j['sportName'] as String?) ?? '',
      hasDetail: j['hasDetail'] as bool? ?? false,
      calories: (j['calories'] as num?)?.toInt(),
      avgHr: (j['avgHr'] as num?)?.toInt(),
      maxHr: (j['maxHr'] as num?)?.toInt(),
      minHr: (j['minHr'] as num?)?.toInt(),
      steps: (j['steps'] as num?)?.toInt(),
    );
  }

  Map<String, dynamic> toJson() => {
    'kind': kind.wire,
    'dayKey': dayKey,
    'startedAt': startedAt.toUtc().toIso8601String(),
    'endedAt': endedAt.toUtc().toIso8601String(),
    'durationSec': durationSec,
    'sportType': sportType,
    'sportName': sportName,
    'hasDetail': hasDetail,
    'calories': calories,
    'avgHr': avgHr,
    'maxHr': maxHr,
    'minHr': minHr,
    'steps': steps,
  };
}
