import 'package:flutter/material.dart';
import 'package:heliolytics/design_system/tokens/helio_metric_colors.dart';
import 'package:heliolytics/models/day_metric.dart';
import 'package:heliolytics/models/health_sample.dart';
import 'package:heliolytics/models/temp_sample.dart';
import 'package:heliolytics/models/hr_sample.dart';

/// UI catalog for home cards and drill-down routes.
class MetricCatalog {
  static const homeOrder = [
    'readiness',
    'sleep',
    'stress',
    'hrv',
    'rhr',
    'spo2',
    'temperature',
    'pai',
    'steps',
  ];

  static MetricDef? byId(String id) => _all[id];

  static final _all = <String, MetricDef>{
    'readiness': MetricDef(
      id: 'readiness',
      title: 'Readiness',
      seriesKey: null,
      color: HelioMetricColors.readiness,
      icon: Icons.bolt,
      unit: '',
      note: 'Daily recovery score from overnight HRV, resting HR, sleep, and breathing rate vs your personal baseline.',
      detail: 'HRV is the biggest driver, then resting HR, sleep, and breathing rate — each compared to your own ~7–60 day baseline. Compare to yourself, not others. Use it to decide how hard to push today.',
    ),
    'sleep': MetricDef(
      id: 'sleep',
      title: 'Sleep',
      seriesKey: null,
      color: HelioMetricColors.sleep,
      icon: Icons.bedtime,
      unit: '',
      note: 'Overnight sleep score and stage breakdown (deep, REM, light).',
      detail: 'Score reflects duration and architecture. Deep and REM support recovery; light sleep is transitional.',
    ),
    'stress': MetricDef(
      id: 'stress',
      title: 'Stress',
      seriesKey: 'stress',
      color: HelioMetricColors.stress,
      icon: Icons.psychology,
      unit: '',
      note: 'Auto stress score each minute (0–100). Lower is calmer.',
      detail: 'Derived from HR variability patterns during the day. Spikes often align with meetings, workouts, or poor sleep.',
    ),
    'hrv': MetricDef(
      id: 'hrv',
      title: 'HRV',
      seriesKey: 'hrv',
      color: HelioMetricColors.hrv,
      icon: Icons.favorite,
      unit: 'ms',
      note: 'RMSSD heart-rate variability. Higher usually means better recovery.',
      detail: 'Measured during sleep and rest. Track your personal baseline — compare to yourself, not others.',
    ),
    'rhr': MetricDef(
      id: 'rhr',
      title: 'Resting HR',
      seriesKey: 'rhr',
      color: HelioMetricColors.restingHr,
      icon: Icons.monitor_heart,
      unit: 'bpm',
      note: 'Resting heart-rate readings through the day.',
      detail: 'Elevated RHR vs your baseline can signal illness, poor sleep, or accumulated fatigue.',
    ),
    'continuous_hr': MetricDef(
      id: 'continuous_hr',
      title: 'Heart rate',
      seriesKey: null,
      color: HelioMetricColors.restingHr,
      icon: Icons.favorite,
      unit: 'bpm',
      note: 'Continuous PPG heart rate (~1/sec) when the strap records a session.',
      detail: 'Synced from strap type 0x46. Gaps are normal when continuous monitoring was off.',
    ),
    'spo2': MetricDef(
      id: 'spo2',
      title: 'SpO₂',
      seriesKey: 'spo2',
      color: HelioMetricColors.spo2,
      icon: Icons.air,
      unit: '%',
      note: 'Blood oxygen spot checks during the day.',
      detail: 'Typical healthy range is 95–100%. Sustained dips warrant medical follow-up.',
    ),
    'spo2_sleep': MetricDef(
      id: 'spo2_sleep',
      title: 'SpO₂ sleep',
      seriesKey: 'spo2_sleep',
      color: HelioMetricColors.spo2,
      icon: Icons.nights_stay,
      unit: '%',
      note: 'Overnight blood oxygen during sleep.',
      detail: 'Useful for spotting breathing disturbances. Compare night-to-night trends.',
    ),
    'resp_rate': MetricDef(
      id: 'resp_rate',
      title: 'Respiratory rate',
      seriesKey: 'resp_rate',
      color: HelioMetricColors.spo2,
      icon: Icons.air,
      unit: 'br/min',
      note: 'Breaths per minute during sleep.',
      detail: 'Stable baseline is personal. Sudden sustained increases can reflect illness or altitude.',
    ),
    'max_hr': MetricDef(
      id: 'max_hr',
      title: 'Max HR',
      seriesKey: 'max_hr',
      color: HelioMetricColors.restingHr,
      icon: Icons.favorite,
      unit: 'bpm',
      note: 'Peak heart rate samples recorded that day.',
      detail: 'Reflects workout peaks and daily maximums from the strap.',
    ),
    'temperature': MetricDef(
      id: 'temperature',
      title: 'Skin temperature',
      seriesKey: null,
      color: HelioMetricColors.temperature,
      icon: Icons.thermostat,
      unit: '°C',
      note: 'Wrist skin temperature minute samples.',
      detail: 'Relative changes vs your baseline matter more than absolute values. Useful for illness and cycle tracking.',
    ),
    'pai': MetricDef(
      id: 'pai',
      title: 'PAI',
      seriesKey: null,
      color: HelioMetricColors.pai,
      icon: Icons.local_fire_department,
      unit: '',
      note: 'Personal Activity Intelligence — weekly cardio load score.',
      detail: 'Helio/Zepp PAI rewards elevated heart rate. Aim to stay above your personal target over 7 days.',
    ),
    'steps': MetricDef(
      id: 'steps',
      title: 'Steps',
      seriesKey: null,
      color: HelioMetricColors.pai,
      icon: Icons.directions_walk,
      unit: '',
      note: 'Total steps counted for the calendar day (IST).',
      detail: 'Includes walking and general movement from the strap accelerometer pipeline.',
    ),
  };
}

class MetricDef {
  final String id;
  final String title;
  final String? seriesKey;
  final Color color;
  final IconData icon;
  final String unit;
  final String note;
  final String detail;

  const MetricDef({
    required this.id,
    required this.title,
    required this.seriesKey,
    required this.color,
    required this.icon,
    required this.unit,
    required this.note,
    required this.detail,
  });

  String summaryValue(DayMetric day) => switch (id) {
        'readiness' => _i(day.readiness),
        'sleep' => _i(day.sleepScore),
        'stress' => _i(day.stressAvg),
        'hrv' => day.hrvRmssd != null ? '${day.hrvRmssd}' : '—',
        'rhr' => day.restingHr != null ? '${day.restingHr}' : '—',
        'max_hr' => day.maxHr != null ? '${day.maxHr}' : '—',
        'resp_rate' => day.respRateAvg != null ? '${day.respRateAvg}' : '—',
        'continuous_hr' => '—',
        'spo2' => day.spo2Avg != null ? '${day.spo2Avg}' : '—',
        'spo2_sleep' => day.spo2Avg != null ? '${day.spo2Avg}' : '—',
        'pai' => _i(day.paiScore),
        'steps' => '${day.steps}',
        'temperature' => day.tempAvgC != null ? day.tempAvgC!.toStringAsFixed(1) : '—',
        _ => '—',
      };

  String _i(int? v) => v?.toString() ?? '—';
}

class MetricStats {
  final double? min;
  final double? max;
  final double? avg;
  final int count;

  const MetricStats({this.min, this.max, this.avg, required this.count});

  static MetricStats fromSamples(List<HealthSample> samples) {
    if (samples.isEmpty) return const MetricStats(count: 0);
    final vals = samples.map((s) => s.value).toList();
    final sum = vals.fold<double>(0, (a, b) => a + b);
    return MetricStats(
      min: vals.reduce((a, b) => a < b ? a : b),
      max: vals.reduce((a, b) => a > b ? a : b),
      avg: sum / vals.length,
      count: vals.length,
    );
  }

  static MetricStats fromTemp(List<TempSample> samples) {
    if (samples.isEmpty) return const MetricStats(count: 0);
    final vals = samples.map((s) => s.celsius).toList();
    final sum = vals.fold<double>(0, (a, b) => a + b);
    return MetricStats(
      min: vals.reduce((a, b) => a < b ? a : b),
      max: vals.reduce((a, b) => a > b ? a : b),
      avg: sum / vals.length,
      count: vals.length,
    );
  }

  static MetricStats fromHeartRate(List<HeartRateSample> samples) {
    if (samples.isEmpty) return const MetricStats(count: 0);
    final vals = samples.map((s) => s.bpm.toDouble()).toList();
    final sum = vals.fold<double>(0, (a, b) => a + b);
    return MetricStats(
      min: vals.reduce((a, b) => a < b ? a : b),
      max: vals.reduce((a, b) => a > b ? a : b),
      avg: sum / vals.length,
      count: vals.length,
    );
  }
}
