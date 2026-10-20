import 'package:flutter/material.dart';

class SleepStagePoint {
  final DateTime start;
  final DateTime end;
  final int type;

  const SleepStagePoint({
    required this.start,
    required this.end,
    required this.type,
  });

  SleepStageKind get kind => SleepStageKind.fromType(type);

  factory SleepStagePoint.fromJson(Map<String, dynamic> j) => SleepStagePoint(
    start: DateTime.parse(j['start'] as String).toUtc(),
    end: DateTime.parse(j['end'] as String).toUtc(),
    type: (j['type'] as num).toInt(),
  );

  Map<String, dynamic> toJson() => {
    'start': start.toUtc().toIso8601String(),
    'end': end.toUtc().toIso8601String(),
    'type': type,
  };
}

/// One sleep session from `GET /api/v1/sleep`.
///
/// Stage intervals are half-open: [end] is exclusive.
class SleepSession {
  const SleepSession({
    required this.startedAt,
    required this.endedAt,
    required this.score,
    required this.totalMins,
    required this.deepMins,
    required this.remMins,
    required this.lightMins,
    required this.wakeMins,
    required this.stagesTruncated,
    this.stages = const [],
  });

  final DateTime startedAt;
  final DateTime endedAt;

  /// Null for naps: no score is fabricated.
  final int? score;
  final int totalMins;
  final int deepMins;
  final int remMins;
  final int lightMins;
  final int wakeMins;
  final bool stagesTruncated;
  final List<SleepStagePoint> stages;

  Duration get duration => endedAt.difference(startedAt);

  /// True when stages do not cover the whole session.
  bool get hasTruncatedStages => stagesTruncated;

  factory SleepSession.fromJson(Map<String, dynamic> j) {
    final totalMins = j['totalMins'];
    final deepMins = j['deepMins'];
    final remMins = j['remMins'];
    final lightMins = j['lightMins'];
    final wakeMins = j['wakeMins'];
    if (totalMins is! num ||
        deepMins is! num ||
        remMins is! num ||
        lightMins is! num ||
        wakeMins is! num) {
      throw const FormatException('Sleep session is missing stage totals');
    }
    final rawStages = j['stages'];
    if (rawStages is! List) {
      throw const FormatException('Sleep session has no stages list');
    }
    return SleepSession(
      startedAt: DateTime.parse(j['startedAt'] as String).toUtc(),
      endedAt: DateTime.parse(j['endedAt'] as String).toUtc(),
      score: (j['score'] as num?)?.toInt(),
      totalMins: totalMins.toInt(),
      deepMins: deepMins.toInt(),
      remMins: remMins.toInt(),
      lightMins: lightMins.toInt(),
      wakeMins: wakeMins.toInt(),
      stagesTruncated: j['stagesTruncated'] as bool? ?? false,
      stages: rawStages
          .map(
            (e) =>
                SleepStagePoint.fromJson(Map<String, dynamic>.from(e as Map)),
          )
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
    'startedAt': startedAt.toUtc().toIso8601String(),
    'endedAt': endedAt.toUtc().toIso8601String(),
    'score': score,
    'totalMins': totalMins,
    'deepMins': deepMins,
    'remMins': remMins,
    'lightMins': lightMins,
    'wakeMins': wakeMins,
    'stagesTruncated': stagesTruncated,
    'stages': stages.map((s) => s.toJson()).toList(),
  };
}

/// One day of sleep: the server's main session plus every nap.
class SleepDay {
  const SleepDay({required this.dayKey, this.main, this.naps = const []});

  final String dayKey;
  final SleepSession? main;
  final List<SleepSession> naps;

  bool get hasAnySession => main != null || naps.isNotEmpty;

  factory SleepDay.fromJson(Map<String, dynamic> j) {
    final rawMain = j['main'];
    final rawNaps = j['naps'];
    if (rawNaps is! List) {
      throw const FormatException('Sleep day has no naps list');
    }
    return SleepDay(
      dayKey: j['dayKey'] as String,
      main: rawMain is Map
          ? SleepSession.fromJson(Map<String, dynamic>.from(rawMain))
          : null,
      naps: rawNaps
          .map(
            (e) => SleepSession.fromJson(Map<String, dynamic>.from(e as Map)),
          )
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
    'dayKey': dayKey,
    'main': main?.toJson(),
    'naps': naps.map((n) => n.toJson()).toList(),
  };
}

/// Huami sleep stage codes from 0x48 hypnogram.
enum SleepStageKind {
  light,
  deep,
  awake,
  rem,
  unknown;

  static SleepStageKind fromType(int type) {
    return switch (type) {
      4 => SleepStageKind.light,
      5 => SleepStageKind.deep,
      7 => SleepStageKind.awake,
      8 => SleepStageKind.rem,
      _ => SleepStageKind.unknown,
    };
  }

  String get label => switch (this) {
    SleepStageKind.light => 'Light',
    SleepStageKind.deep => 'Deep',
    SleepStageKind.awake => 'Awake',
    SleepStageKind.rem => 'REM',
    SleepStageKind.unknown => 'Unknown',
  };

  /// Y-band index: awake top → deep bottom.
  int get bandIndex => switch (this) {
    SleepStageKind.awake => 0,
    SleepStageKind.rem => 1,
    SleepStageKind.light => 2,
    SleepStageKind.deep => 3,
    SleepStageKind.unknown => 2,
  };

  Color get color => switch (this) {
    SleepStageKind.awake => const Color(0xFF94A3B8),
    SleepStageKind.rem => const Color(0xFF818CF8),
    SleepStageKind.light => const Color(0xFF38BDF8),
    SleepStageKind.deep => const Color(0xFF1E40AF),
    SleepStageKind.unknown => const Color(0xFF64748B),
  };
}
