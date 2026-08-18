import 'package:flutter/material.dart';
import 'package:heliolytics/design_system/components/helio_surface_card.dart';
import 'package:heliolytics/design_system/tokens/helio_colors.dart';
import 'package:heliolytics/design_system/tokens/helio_spacing.dart';
import 'package:heliolytics/design_system/tokens/helio_typography.dart';
import 'package:heliolytics/models/day_bundle.dart';
import 'package:heliolytics/models/hr_sample.dart';
import 'package:heliolytics/models/metric_catalog.dart';
import 'package:heliolytics/utils/formatters.dart';

class ScalarMetricSection extends StatelessWidget {
  const ScalarMetricSection({
    super.key,
    required this.definition,
    required this.bundle,
    required this.heartRate,
  });

  final MetricDef definition;
  final DayBundle bundle;
  final List<HeartRateSample> heartRate;

  @override
  Widget build(BuildContext context) {
    final value = _value();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(_label(), style: HelioTypography.capsLabel),
        const SizedBox(height: HelioSpacing.xs),
        Text(
          value ?? 'No reading',
          style: HelioTypography.scoreLarge.copyWith(
            fontSize: 36,
            color: value == null ? HelioColors.textMuted : definition.color,
          ),
        ),
        const SizedBox(height: HelioSpacing.lg),
        HelioSurfaceCard(
          padding: const EdgeInsets.all(HelioSpacing.lg),
          child: Text(definition.detail, style: HelioTypography.bodyMuted),
        ),
      ],
    );
  }

  String _label() => switch (definition.id) {
    'steps' || 'calories' => 'DAY TOTAL',
    'avg_hr' => 'DAILY AVERAGE',
    _ => definition.title.toUpperCase(),
  };

  String? _value() => switch (definition.id) {
    'steps' => formatStepCount(bundle.day.steps),
    'calories' =>
      bundle.day.calories == null ? null : '${bundle.day.calories} kcal',
    'avg_hr' =>
      heartRate.isEmpty
          ? null
          : '${(heartRate.fold<int>(0, (sum, item) => sum + item.bpm) / heartRate.length).round()} bpm',
    'sleep_efficiency' => _sleepEfficiency(),
    _ => null,
  };

  String? _sleepEfficiency() {
    final sleep = bundle.mainSleep;
    if (sleep == null || sleep.totalMins <= 0) return null;
    final inBed = sleep.totalMins + sleep.wakeMins;
    return '${(sleep.totalMins * 100 / inBed).round()}%';
  }
}
