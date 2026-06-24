import 'package:flutter/material.dart';
import 'package:heliolytics/design_system/tokens/helio_colors.dart';
import 'package:heliolytics/design_system/tokens/helio_spacing.dart';
import 'package:heliolytics/design_system/tokens/helio_typography.dart';

/// ALL-CAPS section header for a Settings group.
class SettingsSectionLabel extends StatelessWidget {
  final String text;
  const SettingsSectionLabel(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 2),
      child: Text(
        text,
        style: HelioTypography.sectionTitle.copyWith(
          fontSize: 12,
          letterSpacing: 1.2,
          fontWeight: FontWeight.w700,
          color: HelioColors.textMuted,
        ),
      ),
    );
  }
}

/// Tappable Settings row: icon, title/subtitle, optional status dot, chevron.
class SettingsTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final bool? statusDot;
  final VoidCallback? onTap;

  const SettingsTile({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    this.statusDot,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: HelioSpacing.lg,
          vertical: HelioSpacing.md,
        ),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 17, color: iconColor),
            ),
            const SizedBox(width: HelioSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: HelioTypography.body.copyWith(fontWeight: FontWeight.w500)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: HelioTypography.bodyMuted.copyWith(fontSize: 12)),
                ],
              ),
            ),
            if (statusDot != null)
              Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.only(right: HelioSpacing.sm),
                decoration: BoxDecoration(
                  color: statusDot! ? HelioColors.optimalGreen : HelioColors.recoveryLow,
                  shape: BoxShape.circle,
                ),
              ),
            const Icon(Icons.chevron_right, size: 18, color: HelioColors.textMuted),
          ],
        ),
      ),
    );
  }
}
