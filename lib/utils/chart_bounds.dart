/// Safe min/max for fl_chart when samples are flat or zero.
(double minY, double maxY) chartYBounds(Iterable<double> values, {double padFraction = 0.08}) {
  final vals = values.toList();
  if (vals.isEmpty) return (0, 1);
  var min = vals.reduce((a, b) => a < b ? a : b);
  var max = vals.reduce((a, b) => a > b ? a : b);
  if (min == max) {
    final bump = min == 0 ? 1.0 : min.abs() * padFraction + 1;
    return (min - bump, max + bump);
  }
  final span = max - min;
  return (min - span * padFraction, max + span * padFraction);
}

double chartXInterval(double maxX, {int divisions = 4}) {
  if (maxX <= 0) return 1;
  return (maxX / divisions).clamp(1.0, double.infinity);
}
