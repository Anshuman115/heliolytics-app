import 'package:flutter/material.dart';
import 'package:heliolytics/design_system/tokens/helio_colors.dart';
import 'package:heliolytics/design_system/tokens/helio_typography.dart';

class HelioDateNav extends StatelessWidget {
  final String label;
  final VoidCallback? onPrev;
  final VoidCallback? onNext;
  final bool canGoPrev;
  final bool canGoNext;
  final bool emphasize;
  final bool showArrows;
  final VoidCallback? onDateTap;

  const HelioDateNav({
    super.key,
    required this.label,
    this.onPrev,
    this.onNext,
    this.canGoPrev = true,
    this.canGoNext = true,
    this.emphasize = false,
    this.showArrows = true,
    this.onDateTap,
  });

  @override
  Widget build(BuildContext context) {
    if (emphasize) return _emphasized();

    final controls = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showArrows) _arrow(Icons.chevron_left, canGoPrev ? onPrev : null),
        GestureDetector(
          onTap: onDateTap,
          child: SizedBox(
            width: 132,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                label,
                maxLines: 1,
                textAlign: TextAlign.center,
                style: HelioTypography.capsLabel.copyWith(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: HelioColors.textPrimary,
                ),
              ),
            ),
          ),
        ),
        if (showArrows) _arrow(Icons.chevron_right, canGoNext ? onNext : null),
      ],
    );
    return controls;
  }

  Widget _emphasized() {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: HelioColors.surfaceElevated.withValues(alpha: 0.78),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _arrow(Icons.chevron_left, canGoPrev ? onPrev : null),
          GestureDetector(
            onTap: onDateTap,
            child: Container(
              width: 112,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: HelioColors.surface.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(16),
              ),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  maxLines: 1,
                  textAlign: TextAlign.center,
                  style: HelioTypography.capsLabel.copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: HelioColors.textPrimary,
                  ),
                ),
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
      height: 48,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Icon(
          icon,
          size: 28,
          color: onTap == null
              ? HelioColors.textMuted
              : HelioColors.textPrimary,
        ),
      ),
    );
  }
}
