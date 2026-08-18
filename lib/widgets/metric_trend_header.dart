import 'package:flutter/material.dart';
import 'package:heliolytics/design_system/tokens/helio_colors.dart';
import 'package:heliolytics/design_system/tokens/helio_spacing.dart';
import 'package:heliolytics/design_system/tokens/helio_typography.dart';
import 'package:heliolytics/models/metric_catalog.dart';

class MetricTrendHeader extends StatelessWidget {
  const MetricTrendHeader({super.key, required this.definition});

  final MetricDef definition;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(definition.icon, color: HelioColors.textSecondary, size: 22),
        const SizedBox(width: HelioSpacing.sm),
        Expanded(
          child: Text(
            _title().toUpperCase(),
            style: HelioTypography.sectionTitle.copyWith(
              color: HelioColors.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }

  String _title() => switch (definition.id) {
    'hrv' => 'Heart rate variability',
    'rhr' => 'Resting heart rate',
    'spo2' || 'spo2_sleep' => 'Blood oxygen',
    _ => definition.title,
  };
}
