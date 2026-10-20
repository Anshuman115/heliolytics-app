import 'package:flutter/material.dart';
import 'package:heliolytics/design_system/components/helio_surface_card.dart';
import 'package:heliolytics/design_system/tokens/helio_colors.dart';
import 'package:heliolytics/design_system/tokens/helio_spacing.dart';
import 'package:heliolytics/design_system/tokens/helio_typography.dart';
import 'package:heliolytics/models/day_bundle.dart';
import 'package:heliolytics/models/metric_catalog.dart';
import 'package:heliolytics/utils/formatters.dart';

class ScalarMetricSection extends StatelessWidget {
  const ScalarMetricSection({
    super.key,
    required this.definition,
    required this.bundle,
  });

  final MetricDef definition;
  final DayBundle bundle;

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

  String? _value() {
    final day = bundle.day;
    final steps = day?.steps;
    final calories = day?.workoutCalories;
    final avgHr = day?.avgHr;
    final load = day?.trainingLoad;
    final pai = day?.paiScore;
    final efficiency = day?.sleepEfficiencyPct;
    return switch (definition.id) {
      'steps' => steps == null ? null : formatStepCount(steps),
      'calories' => calories == null ? null : '$calories kcal',
      'avg_hr' => avgHr == null ? null : '${avgHr.toStringAsFixed(1)} bpm',
      'load' => load == null ? null : formatLoad(load),
      'pai' => pai == null ? null : '$pai',
      'sleep_efficiency' => efficiency == null ? null : '$efficiency%',
      _ => null,
    };
  }
}
