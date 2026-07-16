import 'package:flutter/material.dart';
import 'package:heliolytics/design_system/components/helio_surface_card.dart';
import 'package:heliolytics/design_system/tokens/helio_colors.dart';
import 'package:heliolytics/design_system/tokens/helio_spacing.dart';
import 'package:heliolytics/design_system/tokens/helio_typography.dart';
import 'package:heliolytics/utils/metric_assessment.dart';
import 'package:heliolytics/widgets/health/health_tier_chip.dart';

/// One reading in the health-monitor grid: icon + label, a big value with its
/// unit, and the verdict chip.
class HealthMetricCard extends StatelessWidget {
  final String label;
  final IconData icon;

  /// Formatted value, or null when there is no reading.
  final String? value;
  final String unit;
  final MetricAssessment assessment;
  final VoidCallback? onTap;

  const HealthMetricCard({
    super.key,
    required this.label,
    required this.icon,
    required this.value,
    required this.unit,
    required this.assessment,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return HelioSurfaceCard(
      onTap: onTap,
      padding: const EdgeInsets.all(HelioSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _header(),
          _value(),
          HealthTierChip(assessment: assessment),
        ],
      ),
    );
  }

  Widget _header() {
    return Row(
      children: [
        Icon(icon, size: 15, color: HelioColors.textSecondary),
        const SizedBox(width: HelioSpacing.sm),
        Expanded(
          child: Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: HelioTypography.capsLabel.copyWith(fontSize: 10),
          ),
        ),
      ],
    );
  }

  Widget _value() {
    final hasValue = value != null;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Flexible(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value ?? '—',
              style: HelioTypography.scoreLarge.copyWith(
                fontSize: 34,
                color: hasValue
                    ? HelioColors.textPrimary
                    : HelioColors.textMuted,
              ),
            ),
          ),
        ),
        if (hasValue && unit.isNotEmpty) ...[
          const SizedBox(width: 3),
          Padding(
            padding: const EdgeInsets.only(bottom: 3),
            child: Text(
              unit,
              style: HelioTypography.bodyMuted.copyWith(fontSize: 12),
            ),
          ),
        ],
      ],
    );
  }
}
