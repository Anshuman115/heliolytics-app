import 'package:flutter/material.dart';
import 'package:heliolytics/design_system/tokens/helio_colors.dart';
import 'package:heliolytics/design_system/tokens/helio_radii.dart';
import 'package:heliolytics/design_system/tokens/helio_spacing.dart';
import 'package:heliolytics/design_system/tokens/helio_typography.dart';

class HomeMyDaySection extends StatelessWidget {
  final VoidCallback? onTap;

  const HomeMyDaySection({super.key, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Section header with + button
        Row(
          children: [
            Text(
              'MY DAY',
              style: HelioTypography.sectionTitle,
            ),
            const Spacer(),
            GestureDetector(
              onTap: onTap,
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: HelioColors.surfaceElevated,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: HelioColors.border),
                ),
                child: const Icon(Icons.add, size: 16, color: HelioColors.textSecondary),
              ),
            ),
          ],
        ),
        const SizedBox(height: HelioSpacing.md),
        // Daily Outlook row
        GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: HelioSpacing.lg,
              vertical: HelioSpacing.md,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(HelioRadii.card),
              gradient: LinearGradient(
                colors: [
                  HelioColors.outlookGold.withValues(alpha: 0.25),
                  HelioColors.surface,
                ],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              border: Border.all(color: HelioColors.border),
            ),
            child: Row(
              children: [
                Icon(Icons.wb_sunny_outlined, color: HelioColors.outlookGold, size: 18),
                const SizedBox(width: HelioSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'YOUR DAILY OUTLOOK',
                        style: HelioTypography.capsLabel.copyWith(
                          fontSize: 10,
                          color: HelioColors.outlookGold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'View readiness & recovery tips',
                        style: HelioTypography.bodyMuted.copyWith(fontSize: 12),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: HelioColors.textMuted, size: 18),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
