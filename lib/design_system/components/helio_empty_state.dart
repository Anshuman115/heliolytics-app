import 'package:flutter/material.dart';
import 'package:heliolytics/design_system/tokens/helio_colors.dart';
import 'package:heliolytics/design_system/tokens/helio_radii.dart';
import 'package:heliolytics/design_system/tokens/helio_spacing.dart';
import 'package:heliolytics/design_system/tokens/helio_typography.dart';

class HelioEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const HelioEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(HelioSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: HelioColors.textMuted),
            const SizedBox(height: HelioSpacing.lg),
            Text(
              title,
              style: HelioTypography.scoreMedium.copyWith(fontSize: 18),
            ),
            const SizedBox(height: HelioSpacing.sm),
            Text(
              message,
              textAlign: TextAlign.center,
              style: HelioTypography.bodyMuted,
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: HelioSpacing.xl),
              FilledButton(
                onPressed: onAction,
                style: FilledButton.styleFrom(
                  minimumSize: const Size(220, 48),
                  backgroundColor: HelioColors.surface,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(HelioRadii.card),
                  ),
                ),
                child: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
