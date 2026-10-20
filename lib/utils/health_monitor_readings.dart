import 'package:flutter/material.dart';

import 'package:heliolytics/constants/constants.dart';
import 'package:heliolytics/models/day_bundle.dart';
import 'package:heliolytics/models/day_metric.dart';
import 'package:heliolytics/utils/metric_assessment.dart';
import 'package:heliolytics/utils/metric_baseline.dart';

/// One row of the health monitor, ready to render.
class HealthReading {
  final String label;
  final IconData icon;
  final String? value;
  final String unit;
  final MetricAssessment assessment;

  /// Metric id for the drill-down route, or null if the card is not tappable.
  final String? metricId;

  const HealthReading({
    required this.label,
    required this.icon,
    required this.value,
    required this.unit,
    required this.assessment,
    this.metricId,
  });
}

/// Prior days only, most recent first.
List<DayMetric> _priorDays(List<DayMetric> all, String dayKey) {
  final prior = all.where((d) => d.dayKey.compareTo(dayKey) < 0).toList()
    ..sort((a, b) => b.dayKey.compareTo(a.dayKey));
  return prior;
}

MetricBaseline? _baselineOf(
  List<DayMetric> prior,
  double? Function(DayMetric) select, {
  required double bandFloor,
}) {
  final vals = <double>[];
  for (final d in prior) {
    final v = select(d);
    if (v != null) vals.add(v);
  }
  return computeMetricBaseline(vals, bandFloor: bandFloor);
}

String _signed(double v) => '${v >= 0 ? '+' : ''}${v.toStringAsFixed(2)}';

MetricAssessment _availability(Object? value) =>
    value == null ? MetricAssessment.noData : MetricAssessment.recorded;

/// Builds every health-monitor reading for [day], judged against the user's own
/// history in [allDays].
List<HealthReading> buildHealthReadings({
  required DayMetric day,
  required List<DayMetric> allDays,
}) {
  final prior = _priorDays(allDays, day.dayKey);

  final respBase = _baselineOf(
    prior,
    (d) => d.respRate,
    bandFloor: healthBandFloorRespRate,
  );
  final rhrBase = _baselineOf(
    prior,
    (d) => d.restingHr,
    bandFloor: healthBandFloorRestingHr,
  );
  final hrvBase = _baselineOf(
    prior,
    (d) => d.hrvRmssd,
    bandFloor: healthBandFloorHrv,
  );

  return [
    HealthReading(
      label: 'RESPIRATORY RATE',
      icon: Icons.air,
      value: day.respRate?.toStringAsFixed(1),
      unit: 'rpm',
      assessment: assessAgainstBaseline(day.respRate, respBase, decimals: 1),
      metricId: 'resp_rate',
    ),
    if (day.spo2Samples > 0 || day.spo2Avg != null)
      HealthReading(
        label: 'BLOOD OXYGEN (SPO₂)',
        icon: Icons.water_drop_outlined,
        value: day.spo2Avg?.toStringAsFixed(1),
        unit: '%',
        assessment: assessAgainstRange(
          day.spo2Avg,
          min: healthSpo2MinPct,
          max: healthSpo2MaxPct,
          unit: '%',
          decimals: 1,
        ),
        metricId: 'spo2',
      ),
    HealthReading(
      label: 'RHR',
      icon: Icons.favorite_outline,
      value: day.restingHr?.toStringAsFixed(1),
      unit: 'bpm',
      assessment: assessAgainstBaseline(day.restingHr, rhrBase, decimals: 1),
      metricId: 'rhr',
    ),
    HealthReading(
      label: 'HRV',
      icon: Icons.monitor_heart_outlined,
      value: day.hrvRmssd?.toStringAsFixed(1),
      unit: 'ms',
      assessment: assessAgainstBaseline(day.hrvRmssd, hrvBase, decimals: 1),
      metricId: 'hrv',
    ),
    HealthReading(
      label: 'SKIN TEMP (FROM BASELINE)',
      icon: Icons.thermostat_outlined,
      value: day.skinTempDeviationC == null
          ? null
          : _signed(day.skinTempDeviationC!),
      unit: '°C',
      assessment: assessDeviation(
        day.skinTempDeviationC,
        band: healthSkinTempBandC,
        decimals: 2,
      ),
      metricId: 'temperature',
    ),
  ];
}

/// Builds the home-screen reading grid from the selected day's bundle only.
List<HealthReading> buildHomeHealthReadings({
  required DayBundle bundle,
  required List<DayMetric> allDays,
}) {
  final day = bundle.day;
  if (day == null) return const [];
  final prior = _priorDays(allDays, day.dayKey);
  final rhrBase = _baselineOf(
    prior,
    (d) => d.restingHr,
    bandFloor: healthBandFloorRestingHr,
  );
  final hrvBase = _baselineOf(
    prior,
    (d) => d.hrvRmssd,
    bandFloor: healthBandFloorHrv,
  );

  return [
    HealthReading(
      label: 'HRV',
      icon: Icons.monitor_heart_outlined,
      value: day.hrvRmssd?.toStringAsFixed(1),
      unit: 'ms',
      assessment: assessAgainstBaseline(day.hrvRmssd, hrvBase, decimals: 1),
      metricId: 'hrv',
    ),
    HealthReading(
      label: 'RHR',
      icon: Icons.favorite_outline,
      value: day.restingHr?.toStringAsFixed(1),
      unit: 'bpm',
      assessment: assessAgainstBaseline(day.restingHr, rhrBase, decimals: 1),
      metricId: 'rhr',
    ),
    if (day.spo2Samples > 0 || day.spo2Avg != null)
      HealthReading(
        label: 'BLOOD OXYGEN (SPO₂)',
        icon: Icons.water_drop_outlined,
        value: day.spo2Avg?.toStringAsFixed(1),
        unit: '%',
        assessment: assessAgainstRange(
          day.spo2Avg,
          min: healthSpo2MinPct,
          max: healthSpo2MaxPct,
          unit: '%',
          decimals: 1,
        ),
        metricId: 'spo2',
      ),
    HealthReading(
      label: 'WORKOUT CALORIES',
      icon: Icons.local_fire_department_outlined,
      value: day.workoutCalories?.toString(),
      unit: 'kcal',
      assessment: _availability(day.workoutCalories),
      metricId: 'calories',
    ),
    HealthReading(
      label: 'HOURS OF SLEEP',
      icon: Icons.bedtime_outlined,
      value: day.sleepMins == null
          ? null
          : (day.sleepMins! / 60).toStringAsFixed(1),
      unit: 'h',
      assessment: _availability(day.sleepMins),
      metricId: 'sleep',
    ),
    HealthReading(
      label: 'SLEEP EFFICIENCY',
      icon: Icons.percent_outlined,
      value: day.sleepEfficiencyPct?.toString(),
      unit: '%',
      assessment: _availability(day.sleepEfficiencyPct),
      metricId: 'sleep_efficiency',
    ),
    HealthReading(
      label: 'AVG HEART RATE',
      icon: Icons.favorite_border,
      value: day.avgHr?.toStringAsFixed(1),
      unit: 'bpm',
      assessment: _availability(day.avgHr),
      metricId: 'avg_hr',
    ),
    HealthReading(
      label: 'TIME IN BED',
      icon: Icons.king_bed_outlined,
      value: day.timeInBedMins == null
          ? null
          : (day.timeInBedMins! / 60).toStringAsFixed(1),
      unit: 'h',
      assessment: _availability(day.timeInBedMins),
      metricId: 'sleep',
    ),
  ];
}
