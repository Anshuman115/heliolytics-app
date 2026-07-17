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
        start: DateTime.parse(j['start'] as String).toLocal(),
        end: DateTime.parse(j['end'] as String).toLocal(),
        type: (j['type'] as num).toInt(),
      );

  Map<String, dynamic> toJson() => {
        'start': start.toUtc().toIso8601String(),
        'end': end.toUtc().toIso8601String(),
        'type': type,
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
