import 'package:flutter/material.dart';
import 'package:heliolytics/design_system/tokens/helio_colors.dart';
import 'package:heliolytics/design_system/tokens/helio_spacing.dart';
import 'package:heliolytics/utils/metric_assessment.dart';

/// The verdict chip under a health reading — "near 16.1", "low < 37".
class HealthTierChip extends StatelessWidget {
  final MetricAssessment assessment;

  const HealthTierChip({super.key, required this.assessment});

  @override
  Widget build(BuildContext context) {
    final color = switch (assessment.tier) {
      MetricTier.optimal => HelioColors.tierOptimal,
      MetricTier.caution => HelioColors.tierCaution,
      MetricTier.unknown => HelioColors.textMuted,
    };
    final icon = switch (assessment.tier) {
      MetricTier.optimal => Icons.check,
      MetricTier.caution => Icons.priority_high,
      MetricTier.unknown => null,
    };

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: HelioSpacing.sm,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 4),
          ],
          Flexible(
            child: Text(
              assessment.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: color,
                height: 1,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
