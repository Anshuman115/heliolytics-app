import 'package:flutter/material.dart';
import 'package:heliolytics/design_system/components/helio_surface_card.dart';
import 'package:heliolytics/design_system/tokens/helio_colors.dart';
import 'package:heliolytics/design_system/tokens/helio_spacing.dart';
import 'package:heliolytics/design_system/tokens/helio_typography.dart';

class RecoveryInsightCard extends StatelessWidget {
  const RecoveryInsightCard({super.key, required this.message});
  final String message;

  @override
  Widget build(BuildContext context) => HelioSurfaceCard(
    color: HelioColors.surfaceElevated,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.lightbulb_outline,
              color: HelioColors.textSecondary,
              size: 22,
            ),
            const SizedBox(width: HelioSpacing.sm),
            Text(
              'RECOVERY INSIGHT',
              style: HelioTypography.sectionTitle.copyWith(
                color: HelioColors.textPrimary,
              ),
            ),
            const Spacer(),
            const Icon(Icons.chevron_right, color: HelioColors.textMuted),
          ],
        ),
        const SizedBox(height: HelioSpacing.md),
        Text(message, style: HelioTypography.bodyMuted.copyWith(fontSize: 15)),
      ],
    ),
  );
}
