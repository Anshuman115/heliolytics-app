import 'package:flutter/material.dart';
import 'package:heliolytics/design_system/components/helio_surface_card.dart';
import 'package:heliolytics/design_system/tokens/helio_colors.dart';
import 'package:heliolytics/design_system/tokens/helio_radii.dart';
import 'package:heliolytics/design_system/tokens/helio_spacing.dart';
import 'package:heliolytics/design_system/tokens/helio_typography.dart';

class ActivityRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String duration;
  final String timeRange;
  final String? kind;
  final VoidCallback? onTap;

  const ActivityRow({
    super.key,
    required this.icon,
    required this.title,
    required this.duration,
    required this.timeRange,
    this.kind,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: HelioSpacing.sm),
      child: HelioSurfaceCard(
        onTap: onTap,
        padding: const EdgeInsets.all(HelioSpacing.md),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 52,
              decoration: BoxDecoration(
                color: HelioColors.strainBlue.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(HelioRadii.sm),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, color: HelioColors.strainBlue, size: 22),
                  const SizedBox(height: 2),
                  Text(
                    duration,
                    style: HelioTypography.capsLabel.copyWith(
                      fontSize: 9,
                      color: HelioColors.strainBlue,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: HelioSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title.toUpperCase(),
                    style: HelioTypography.capsLabel.copyWith(
                      color: HelioColors.textPrimary,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    kind == null ? timeRange : '$kind · $timeRange',
                    style: HelioTypography.bodyMuted,
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right,
              color: HelioColors.textMuted,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
