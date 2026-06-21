import 'package:flutter/material.dart';
import 'package:heliolytics/design_system/tokens/helio_colors.dart';
import 'package:heliolytics/design_system/tokens/helio_spacing.dart';
import 'package:heliolytics/design_system/tokens/helio_typography.dart';

/// A single WHOOP-style vital row:
/// ICON  LABEL (caps, muted)  ········  VALUE  ▲/▼ delta
class HomeVitalRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String unit;
  final String? delta;
  final bool deltaUp;
  final Color? valueColor;
  final VoidCallback? onTap;

  const HomeVitalRow({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.unit,
    this.delta,
    this.deltaUp = true,
    this.valueColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: HelioSpacing.sm + 2),
        child: Row(
          children: [
            Icon(icon, size: 18, color: HelioColors.textMuted),
            const SizedBox(width: HelioSpacing.md),
            Text(
              label.toUpperCase(),
              style: HelioTypography.capsLabel.copyWith(fontSize: 11),
            ),
            const Spacer(),
            // Value + unit
            RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: value,
                    style: HelioTypography.scoreMedium.copyWith(
                      fontSize: 20,
                      color: valueColor ?? HelioColors.textPrimary,
                    ),
                  ),
                  if (unit.isNotEmpty)
                    TextSpan(
                      text: ' $unit',
                      style: HelioTypography.bodyMuted.copyWith(fontSize: 12),
                    ),
                ],
              ),
            ),
            if (delta != null) ...[
              const SizedBox(width: HelioSpacing.sm),
              Text(
                '${deltaUp ? '▲' : '▼'} $delta',
                style: HelioTypography.trendDelta.copyWith(
                  color: deltaUp ? HelioColors.recoveryHigh : HelioColors.recoveryLow,
                ),
              ),
            ],
            if (onTap != null) ...[
              const SizedBox(width: HelioSpacing.xs),
              const Icon(Icons.chevron_right, size: 16, color: HelioColors.textMuted),
            ],
          ],
        ),
      ),
    );
  }
}
