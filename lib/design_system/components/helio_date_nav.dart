import 'package:flutter/material.dart';
import 'package:heliolytics/design_system/tokens/helio_colors.dart';
import 'package:heliolytics/design_system/tokens/helio_radii.dart';
import 'package:heliolytics/design_system/tokens/helio_spacing.dart';
import 'package:heliolytics/design_system/tokens/helio_typography.dart';

class HelioDateNav extends StatelessWidget {
  final String label;
  final VoidCallback? onPrev;
  final VoidCallback? onNext;
  final bool canGoPrev;
  final bool canGoNext;

  const HelioDateNav({
    super.key,
    required this.label,
    this.onPrev,
    this.onNext,
    this.canGoPrev = true,
    this.canGoNext = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: HelioSpacing.xs),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(HelioRadii.pill),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _arrow(Icons.chevron_left, canGoPrev ? onPrev : null),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: HelioSpacing.sm),
            child: Text(
              label,
              style: HelioTypography.capsLabel.copyWith(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: HelioColors.textPrimary,
                letterSpacing: 1.6,
              ),
            ),
          ),
          _arrow(Icons.chevron_right, canGoNext ? onNext : null),
        ],
      ),
    );
  }

  Widget _arrow(IconData icon, VoidCallback? onTap) {
    return SizedBox(
      width: 32,
      height: 32,
      child: IconButton(
        padding: EdgeInsets.zero,
        icon: Icon(icon, size: 20),
        onPressed: onTap,
        color: onTap == null ? HelioColors.textMuted : HelioColors.textPrimary,
      ),
    );
  }
}
