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
    'load',
    'steps',
  ];

  static MetricDef? byId(String id) => _all[id];

  static final _all = <String, MetricDef>{
    'readiness': MetricDef(
      id: 'readiness',
      title: 'Recovery',
      seriesKey: null,
      color: HelioMetricColors.readiness,
      icon: Icons.bolt,
      unit: '',
      note:
          'Daily recovery score from overnight HRV, resting HR, sleep, and breathing rate vs your personal baseline.',
      detail:
          'HRV is the biggest driver, then resting HR, sleep, and breathing rate — each compared to your own ~7–60 day baseline. Compare to yourself, not others. Use it to decide how hard to push today.',
    ),
    'sleep': MetricDef(
      id: 'sleep',
      title: 'Sleep',
      seriesKey: null,
      color: HelioMetricColors.sleep,
      icon: Icons.bedtime,
      unit: '',
      note: 'Overnight sleep score and stage breakdown (deep, REM, light).',
      detail:
          'Score reflects duration and architecture. Deep and REM support recovery; light sleep is transitional.',
    ),
    'stress': MetricDef(
      id: 'stress',
      title: 'Stress',
      seriesKey: 'stress',
      color: HelioMetricColors.stress,
      icon: Icons.psychology,
      unit: '',
      note: 'Auto stress score each minute (0–100). Lower is calmer.',
      detail:
          'Derived from HR variability patterns during the day. Spikes often align with meetings, workouts, or poor sleep.',
    ),
    'hrv': MetricDef(
      id: 'hrv',
      title: 'HRV',
      seriesKey: 'hrv',
      color: HelioMetricColors.hrv,
      icon: Icons.favorite,
      unit: 'ms',
      note:
          'RMSSD heart-rate variability. Higher usually means better recovery.',
      detail:
          'Measured during sleep and rest. Track your personal baseline — compare to yourself, not others.',
    ),
    'rhr': MetricDef(
      id: 'rhr',
      title: 'Resting HR',
      seriesKey: null,
      color: HelioMetricColors.restingHr,
      icon: Icons.monitor_heart,
      unit: 'bpm',
      note: 'Lowest five-minute mean heart rate during main sleep.',
      detail:
          'Compared with your own nights, a sustained rise can accompany '
          'illness, poor sleep, or accumulated fatigue. '
          'It is not a diagnosis.',
    ),
    'continuous_hr': MetricDef(
      id: 'continuous_hr',
      title: 'Heart rate',
      seriesKey: null,
      color: HelioMetricColors.restingHr,
      icon: Icons.favorite,
      unit: 'bpm',
      note: 'Minute heart rate from strap type 0x01.',
      detail:
          'The backend stores one heart-rate value per measured minute. '
          'Gaps mean the strap measured nothing in those minutes.',
    ),
    'spo2': MetricDef(
      id: 'spo2',
      title: 'SpO₂',
      seriesKey: 'spo2',
      color: HelioMetricColors.spo2,
      icon: Icons.air,
      unit: '%',
      note: 'Blood oxygen spot checks during the day.',
      detail:
          'Typical healthy range is 95–100%. Sustained dips warrant medical follow-up.',
    ),
    'resp_rate': MetricDef(
      id: 'resp_rate',
      title: 'Respiratory rate',
      seriesKey: 'resp',
      color: HelioMetricColors.spo2,
      icon: Icons.air,
      unit: 'br/min',
      note: 'Breaths per minute during sleep.',
      detail:
          'Stable baseline is personal. Sudden sustained increases can reflect illness or altitude.',
    ),
    'temperature': MetricDef(
      id: 'temperature',
      title: 'Skin temperature',
      seriesKey: null,
      color: HelioMetricColors.temperature,
      icon: Icons.thermostat,
      unit: '°C',
      note: 'Wrist skin temperature minute samples.',
      detail:
          'Relative changes vs your baseline matter more than absolute values. Useful for illness and cycle tracking.',
    ),
    'pai': MetricDef(
      id: 'pai',
      title: 'PAI',
      seriesKey: null,
      color: HelioMetricColors.pai,
      icon: Icons.local_fire_department,
      unit: '',
      note: 'Personal Activity Intelligence score from the strap.',
      detail:
          'PAI is the device score for cardiovascular activity. '
          'It is separate from the Banister TRIMP training load.',
    ),
    'load': const MetricDef(
      id: 'load',
      title: 'Training load',
      seriesKey: null,
      color: HelioMetricColors.pai,
      icon: Icons.fitness_center,
      unit: '',
      note: 'Banister TRIMP from measured minute heart rate.',
      detail:
          'TRIMP weights each minute by heart-rate reserve relative to your '
          'estimated maximum and resting heart rate. '
          'Missing birth date or sex leaves load unavailable.',
    ),
    'steps': MetricDef(
      id: 'steps',
      title: 'Steps',
      seriesKey: null,
      color: HelioMetricColors.pai,
      icon: Icons.directions_walk,
      unit: '',
      note: 'Total steps counted for the calendar day (IST).',
      detail:
          'Includes walking and general movement from the strap accelerometer pipeline.',
    ),
    'calories': MetricDef(
      id: 'calories',
      title: 'Workout calories',
      seriesKey: null,
      color: HelioMetricColors.pai,
      icon: Icons.local_fire_department,
      unit: 'kcal',
      note: 'Calories recorded by strap workouts for the day.',
      detail:
          'Only recorded workouts report calories. '
          'This is not total daily energy expenditure.',
    ),
    'avg_hr': MetricDef(
      id: 'avg_hr',
      title: 'Average Heart Rate',
      seriesKey: null,
      color: HelioMetricColors.restingHr,
      icon: Icons.favorite,
      unit: 'bpm',
      note: 'Average heart rate for the day.',
      detail:
          'Daily average across synced heart-rate samples. Use longer-term changes to understand cardiovascular load and recovery.',
    ),
    'sleep_efficiency': MetricDef(
      id: 'sleep_efficiency',
      title: 'Sleep Efficiency',
      seriesKey: null,
      color: HelioMetricColors.sleep,
      icon: Icons.percent,
      unit: '%',
      note: 'Share of time in bed spent asleep.',
      detail:
          'Computed by the backend as sleep minutes divided by time in bed.',
    ),
    'sleep_debt': MetricDef(
      id: 'sleep_debt',
      title: 'Sleep Debt',
      seriesKey: null,
      color: HelioMetricColors.sleep,
      icon: Icons.trending_down,
      unit: '',
      note: 'Accumulated shortfall against your sleep need.',
      detail: 'Sleep debt is not yet available from the backend.',
    ),
    'sleep_consistency': MetricDef(
      id: 'sleep_consistency',
      title: 'Sleep Consistency',
      seriesKey: null,
      color: HelioMetricColors.sleep,
      icon: Icons.repeat,
      unit: '%',
      note: 'How stable your bed/wake times have been.',
      detail: 'Sleep consistency is not yet available from the backend.',
    ),
    'sleep_needed': MetricDef(
      id: 'sleep_needed',
      title: 'Sleep Needed',
      seriesKey: null,
      color: HelioMetricColors.sleep,
      icon: Icons.hotel,
      unit: '',
      note: 'Estimated sleep need based on recent debt and strain.',
      detail: 'Sleep need estimation is not yet available from the backend.',
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
    'readiness' => day.readiness != null ? '${day.readiness}%' : '—',
    'sleep' => _i(day.sleepScore),
    'stress' => _d(day.stressAvg, 1),
    'hrv' => _d(day.hrvRmssd, 1),
    'rhr' => _d(day.restingHr, 1),
    'resp_rate' => _d(day.respRate, 1),
    'continuous_hr' => _d(day.avgHr, 1),
    'spo2' => _d(day.spo2Avg, 1),
    'pai' => _i(day.paiScore),
    'load' => _d(day.trainingLoad, 1),
    'steps' => _i(day.steps),
    'temperature' => _d(day.skinTempNightC, 2),
    'calories' => _i(day.workoutCalories),
    'avg_hr' => _d(day.avgHr, 1),
    _ => '—',
  };

  String _i(int? v) => v?.toString() ?? '—';

  String _d(double? v, int decimals) =>
      v == null ? '—' : v.toStringAsFixed(decimals);
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
