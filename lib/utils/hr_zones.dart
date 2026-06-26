import 'package:heliolytics/constants/constants.dart';
import 'package:heliolytics/models/hr_sample.dart';

/// One heart-rate zone with its bpm bounds and accumulated time.
class HrZone {
  final int index; // 0 (rest) .. 5 (max)
  final int lowBpm;
  final int? highBpm; // null = open-ended top zone
  final int seconds;

  const HrZone({
    required this.index,
    required this.lowBpm,
    this.highBpm,
    required this.seconds,
  });
}

class HrZoneBreakdown {
  final List<HrZone> zones; // ascending, index 0..5
  final int referenceMaxHr;
  final int totalSeconds;

  const HrZoneBreakdown({
    required this.zones,
    required this.referenceMaxHr,
    required this.totalSeconds,
  });

  bool get hasData => totalSeconds > 0;
}

const int _maxGapSeconds = 120; // cap dwell per sample so gaps don't inflate
const int _tailSeconds = 60; // nominal dwell for the final sample

/// Compute time-in-zone from HR samples. Zones are fractions of [maxHr]
/// (defaults to a fixed reference so an easy session reads as low-zone,
/// matching how wearables bucket effort against true max HR).
HrZoneBreakdown computeHrZones(List<HeartRateSample> samples, {int? maxHr}) {
  final ref = (maxHr == null || maxHr <= 0) ? defaultMaxHrFallback : maxHr;

  final bounds = <int>[
    for (final f in hrZoneLowerFractions) (ref * f).round(),
  ];
  final acc = List<int>.filled(hrZoneLowerFractions.length, 0);

  final sorted = [...samples]..sort((a, b) => a.sampledAt.compareTo(b.sampledAt));
  for (var i = 0; i < sorted.length; i++) {
    final dwell = i < sorted.length - 1
        ? sorted[i + 1]
            .sampledAt
            .difference(sorted[i].sampledAt)
            .inSeconds
            .clamp(0, _maxGapSeconds)
        : _tailSeconds;
    acc[_zoneFor(sorted[i].bpm, bounds)] += dwell;
  }

  final total = acc.fold<int>(0, (a, b) => a + b);
  final zones = <HrZone>[
    for (var i = 0; i < bounds.length; i++)
      HrZone(
        index: i,
        lowBpm: bounds[i],
        highBpm: i < bounds.length - 1 ? bounds[i + 1] : null,
        seconds: acc[i],
      ),
  ];
  return HrZoneBreakdown(zones: zones, referenceMaxHr: ref, totalSeconds: total);
}

int _zoneFor(int bpm, List<int> bounds) {
  var z = 0;
  for (var i = 0; i < bounds.length; i++) {
    if (bpm >= bounds[i]) z = i;
  }
  return z;
}
