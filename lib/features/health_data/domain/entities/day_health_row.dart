/// One IST calendar day of aggregated strap metrics.
class DayHealthRow {
  final String dayKey;
  final int steps;
  final int? avgHeartRate;
  final int? stressAvg;
  final double? tempCelsiusAvg;

  const DayHealthRow({
    required this.dayKey,
    required this.steps,
    this.avgHeartRate,
    this.stressAvg,
    this.tempCelsiusAvg,
  });
}
