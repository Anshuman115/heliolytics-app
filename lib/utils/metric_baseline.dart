import 'dart:math' as math;

import 'package:heliolytics/constants/constants.dart';

/// A personal baseline for one metric: what "typical" looks like for this user.
///
/// Built from PRIOR days only — the day being assessed is never folded into its
/// own baseline, or a bad day partly defines its own "normal" and the comparison
/// cancels itself out. Same rule the server's readiness score follows.
class MetricBaseline {
  /// Trailing mean of prior days.
  final double mean;

  /// Half-width of the typical band. Never narrower than the metric's floor.
  final double band;

  /// How many prior days fed the baseline.
  final int days;

  const MetricBaseline({
    required this.mean,
    required this.band,
    required this.days,
  });

  double get lowerBound => mean - band;
  double get upperBound => mean + band;

  bool contains(double value) => value >= lowerBound && value <= upperBound;
}

/// Builds a baseline from [priorValues] (most recent first or last — order does
/// not matter), or null when there is not enough history to say anything.
///
/// [bandFloor] stops an unusually steady metric from producing a hair-thin band
/// that flags every trivial wobble as abnormal.
MetricBaseline? computeMetricBaseline(
  Iterable<double> priorValues, {
  required double bandFloor,
}) {
  final vals = priorValues.take(healthBaselineWindowDays).toList();
  if (vals.length < healthBaselineMinDays) return null;

  final mean = vals.reduce((a, b) => a + b) / vals.length;
  final variance =
      vals.map((v) => math.pow(v - mean, 2).toDouble()).reduce((a, b) => a + b) /
          vals.length;
  final sd = math.sqrt(variance);

  return MetricBaseline(
    mean: mean,
    band: math.max(sd, bandFloor),
    days: vals.length,
  );
}
