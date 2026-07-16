import 'package:heliolytics/constants/constants.dart';
import 'package:heliolytics/models/health_sample.dart';

/// Stress bands. The strap reports 0–100; these are the thresholds we bucket by.
enum StressZone { low, medium, high }

StressZone stressZoneOf(double value) {
  if (value < stressMediumMin) return StressZone.low;
  if (value < stressHighMin) return StressZone.medium;
  return StressZone.high;
}

String stressZoneLabel(StressZone z) => switch (z) {
      StressZone.low => 'LOW',
      StressZone.medium => 'MEDIUM',
      StressZone.high => 'HIGH',
    };

/// Minutes spent in each band across [samples].
class StressSplit {
  final Map<StressZone, int> minutes;

  const StressSplit(this.minutes);

  int get total =>
      minutes.values.fold(0, (a, b) => a + b);

  int minutesIn(StressZone z) => minutes[z] ?? 0;

  double shareOf(StressZone z) => total == 0 ? 0 : minutesIn(z) / total;

  bool get hasData => total > 0;
}

/// Buckets [samples] into bands, one minute per sample.
///
/// The strap emits stress roughly once a minute; a gap means the band was off
/// the wrist, so missing minutes are simply absent rather than interpolated —
/// counting them would inflate whichever band happened to precede the gap.
StressSplit splitStressByZone(List<HealthSample> samples) {
  final out = <StressZone, int>{};
  for (final s in samples) {
    final z = stressZoneOf(s.value);
    out[z] = (out[z] ?? 0) + 1;
  }
  return StressSplit(out);
}

/// Mean stress across [samples], or null when there is nothing to average.
double? meanStress(List<HealthSample> samples) {
  if (samples.isEmpty) return null;
  final sum = samples.fold<double>(0, (a, s) => a + s.value);
  return sum / samples.length;
}

/// The most recent sample, or null.
HealthSample? latestStress(List<HealthSample> samples) {
  if (samples.isEmpty) return null;
  var latest = samples.first;
  for (final s in samples) {
    if (s.sampledAt.isAfter(latest.sampledAt)) latest = s;
  }
  return latest;
}
