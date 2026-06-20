import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:heliolytics/constants/constants.dart';
import 'package:heliolytics/design_system/components/helio_surface_card.dart';
import 'package:heliolytics/design_system/tokens/helio_colors.dart';
import 'package:heliolytics/design_system/tokens/helio_spacing.dart';
import 'package:heliolytics/design_system/tokens/helio_typography.dart';

class HelioCloudBanner extends StatelessWidget {
  const HelioCloudBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: HelioSpacing.lg),
      child: HelioSurfaceCard(
        onTap: () => context.push('/settings/api'),
        padding: const EdgeInsets.all(HelioSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.cloud_off, size: 20, color: HelioColors.recoveryLow),
                const SizedBox(width: HelioSpacing.sm),
                Expanded(
                  child: Text(
                    'CLOUD API REQUIRED',
                    style: HelioTypography.capsLabel.copyWith(color: HelioColors.recoveryLow),
                  ),
                ),
              ],
            ),
            const SizedBox(height: HelioSpacing.sm),
            Text(cloudApiSetupHintMessage, style: HelioTypography.bodyMuted),
            const SizedBox(height: HelioSpacing.sm),
            Text(
              'Tap to configure →',
              style: HelioTypography.capsLabel.copyWith(color: HelioColors.sleepBlue),
            ),
          ],
        ),
      ),
    );
  }
}
