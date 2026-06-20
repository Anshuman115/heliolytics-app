import 'package:flutter/material.dart';
import 'package:heliolytics/design_system/tokens/helio_colors.dart';
import 'package:heliolytics/design_system/tokens/helio_radii.dart';
import 'package:heliolytics/design_system/tokens/helio_spacing.dart';
import 'package:heliolytics/design_system/tokens/helio_typography.dart';

class HelioMetricBar extends StatelessWidget {
  final String label;
  final int percent;
  final Color color;

  const HelioMetricBar({
    super.key,
    required this.label,
    required this.percent,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final clamped = percent.clamp(0, 100);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(label.toUpperCase(), style: HelioTypography.capsLabel),
            const Spacer(),
            Text('$clamped%', style: HelioTypography.body),
          ],
        ),
        const SizedBox(height: HelioSpacing.xs),
        ClipRRect(
          borderRadius: BorderRadius.circular(HelioRadii.pill),
          child: LinearProgressIndicator(
            value: clamped / 100,
            minHeight: 6,
            backgroundColor: HelioColors.surfaceElevated,
            color: color,
          ),
        ),
      ],
    );
  }
}
