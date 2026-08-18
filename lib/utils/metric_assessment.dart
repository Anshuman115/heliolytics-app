import 'package:heliolytics/utils/metric_baseline.dart';

/// How a reading compares to what is normal for this user.
enum MetricTier {
  /// Inside the typical band, or inside a clinically normal range.
  optimal,

  /// Outside it — worth a look, not a diagnosis.
  caution,

  /// No reading, or not enough history to judge one.
  unknown,
}

/// A reading plus the one-line verdict shown on its card.
class MetricAssessment {
  final MetricTier tier;

  /// Chip text, e.g. "near 16.1", "low < 37", "within 95% - 100%".
  final String label;

  const MetricAssessment({required this.tier, required this.label});

  static const noData = MetricAssessment(
    tier: MetricTier.unknown,
    label: 'no reading',
  );

  static const building = MetricAssessment(
    tier: MetricTier.unknown,
    label: 'building baseline',
  );

  static const recorded = MetricAssessment(
    tier: MetricTier.unknown,
    label: 'recorded',
  );
}

String _fmt(double v, int decimals) => v.toStringAsFixed(decimals);

double _pow10(int d) {
  var p = 1.0;
  for (var i = 0; i < d; i++) {
    p *= 10;
  }
  return p;
}

/// Rounds a bound AWAY from the typical band before display.
///
/// A bound rounded to the nearest step can land on the very value it is
/// judging — a 16.6 reading against a 16.58 bound would render "high > 16.6",
/// which reads as nonsense. Rounding outward keeps the printed bound strictly
/// clear of the printed value.
String _fmtBoundLow(double v, int decimals) {
  final p = _pow10(decimals);
  return ((v * p).ceilToDouble() / p).toStringAsFixed(decimals);
}

String _fmtBoundHigh(double v, int decimals) {
  final p = _pow10(decimals);
  return ((v * p).floorToDouble() / p).toStringAsFixed(decimals);
}

/// Judges [value] against the user's own [baseline].
///
/// Used for metrics with no meaningful population range — a 35 ms HRV is fine
/// for one person and low for another, so only their own history can say.
MetricAssessment assessAgainstBaseline(
  double? value,
  MetricBaseline? baseline, {
  int decimals = 0,
}) {
  if (value == null) return MetricAssessment.noData;
  if (baseline == null) return MetricAssessment.building;

  if (value < baseline.lowerBound) {
    return MetricAssessment(
      tier: MetricTier.caution,
      label: 'low < ${_fmtBoundLow(baseline.lowerBound, decimals)}',
    );
  }
  if (value > baseline.upperBound) {
    return MetricAssessment(
      tier: MetricTier.caution,
      label: 'high > ${_fmtBoundHigh(baseline.upperBound, decimals)}',
    );
  }
  return MetricAssessment(
    tier: MetricTier.optimal,
    label: 'near ${_fmt(baseline.mean, decimals)}',
  );
}

/// Judges [value] against a fixed range that holds for everyone.
///
/// Only for metrics with a genuine clinical range — blood oxygen, say.
MetricAssessment assessAgainstRange(
  double? value, {
  required double min,
  required double max,
  required String unit,
  int decimals = 0,
}) {
  if (value == null) return MetricAssessment.noData;

  final lo = '${_fmt(min, decimals)}$unit';
  if (value < min) {
    return MetricAssessment(tier: MetricTier.caution, label: 'low < $lo');
  }
  if (value > max) {
    return MetricAssessment(
      tier: MetricTier.caution,
      label: 'high > ${_fmt(max, decimals)}$unit',
    );
  }
  return MetricAssessment(
    tier: MetricTier.optimal,
    label: 'within $lo - ${_fmt(max, decimals)}$unit',
  );
}

/// Judges a deviation-from-baseline reading, e.g. skin temperature.
///
/// The value is already a delta, so the verdict is about distance from zero.
MetricAssessment assessDeviation(
  double? deviation, {
  required double band,
  int decimals = 1,
}) {
  if (deviation == null) return MetricAssessment.noData;
  final b = _fmt(band, decimals);
  if (deviation.abs() <= band) {
    return MetricAssessment(tier: MetricTier.optimal, label: 'near -$b to +$b');
  }
  return MetricAssessment(
    tier: MetricTier.caution,
    label: deviation > 0 ? 'high > +$b' : 'low < -$b',
  );
}
