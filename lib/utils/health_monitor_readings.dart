import 'package:flutter/material.dart';
import 'package:heliolytics/constants/constants.dart';
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

/// Prior days only, most recent first. The assessed day is excluded so it never
/// contributes to the baseline it is judged against.
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

String _signed(double v) => '${v >= 0 ? '+' : ''}${v.toStringAsFixed(1)}';

/// Builds every health-monitor reading for [day], judged against the user's own
/// history in [allDays].
List<HealthReading> buildHealthReadings({
  required DayMetric day,
  required List<DayMetric> allDays,
}) {
  final prior = _priorDays(allDays, day.dayKey);

  final respBase = _baselineOf(prior, (d) => d.respRateAvg?.toDouble(),
      bandFloor: healthBandFloorRespRate);
  final rhrBase = _baselineOf(prior, (d) => d.restingHr?.toDouble(),
      bandFloor: healthBandFloorRestingHr);
  final hrvBase = _baselineOf(prior, (d) => d.hrvRmssd?.toDouble(),
      bandFloor: healthBandFloorHrv);
  final tempBase = _baselineOf(prior, (d) => d.tempAvgC,
      bandFloor: healthSkinTempBandC);

  // Skin temperature is only meaningful as a deviation — the absolute number
  // tracks the room as much as the body.
  final tempDev = (day.tempAvgC != null && tempBase != null)
      ? day.tempAvgC! - tempBase.mean
      : null;

  return [
    HealthReading(
      label: 'RESPIRATORY RATE',
      icon: Icons.air,
      value: day.respRateAvg?.toStringAsFixed(1),
      unit: 'rpm',
      assessment: assessAgainstBaseline(
        day.respRateAvg?.toDouble(),
        respBase,
        decimals: 1,
      ),
      metricId: 'resp_rate',
    ),
    HealthReading(
      label: 'BLOOD OXYGEN (SPO₂)',
      icon: Icons.water_drop_outlined,
      value: day.spo2Avg?.toString(),
      unit: '%',
      assessment: assessAgainstRange(
        day.spo2Avg?.toDouble(),
        min: healthSpo2MinPct,
        max: healthSpo2MaxPct,
        unit: '%',
      ),
      metricId: 'spo2_sleep',
    ),
    HealthReading(
      label: 'RHR',
      icon: Icons.favorite_outline,
      value: day.restingHr?.toString(),
      unit: 'bpm',
      assessment: assessAgainstBaseline(day.restingHr?.toDouble(), rhrBase),
      metricId: 'rhr',
    ),
    HealthReading(
      label: 'HRV',
      icon: Icons.monitor_heart_outlined,
      value: day.hrvRmssd?.toString(),
      unit: 'ms',
      assessment: assessAgainstBaseline(day.hrvRmssd?.toDouble(), hrvBase),
      metricId: 'hrv',
    ),
    HealthReading(
      label: 'SKIN TEMP (FROM BASELINE)',
      icon: Icons.thermostat_outlined,
      value: tempDev != null ? _signed(tempDev) : null,
      unit: '°C',
      assessment: assessDeviation(tempDev, band: healthSkinTempBandC),
      metricId: 'temperature',
    ),
  ];
}
