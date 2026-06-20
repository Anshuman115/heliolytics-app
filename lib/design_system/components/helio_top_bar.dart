import 'package:flutter/material.dart';
import 'package:heliolytics/design_system/components/helio_date_nav.dart';
import 'package:heliolytics/design_system/tokens/helio_colors.dart';
import 'package:heliolytics/design_system/tokens/helio_spacing.dart';
import 'package:heliolytics/design_system/tokens/helio_typography.dart';

class HelioTopBar extends StatelessWidget implements PreferredSizeWidget {
  final bool showBack;
  final VoidCallback? onBack;
  final String? title;
  final String? dayLabel;
  final VoidCallback? onPrevDay;
  final VoidCallback? onNextDay;
  final bool canGoPrev;
  final bool canGoNext;
  final int? batteryPercent;
  final bool syncActive;
  final bool showProfile;

  const HelioTopBar({
    super.key,
    this.showBack = false,
    this.onBack,
    this.title,
    this.dayLabel,
    this.onPrevDay,
    this.onNextDay,
    this.canGoPrev = true,
    this.canGoNext = true,
    this.batteryPercent,
    this.syncActive = false,
    this.showProfile = false,
  });

  @override
  Size get preferredSize => const Size.fromHeight(56);

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: SizedBox(
        height: 56,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: HelioSpacing.md),
          child: Row(
            children: [
              SizedBox(width: 40, child: _leading()),
              Expanded(child: Center(child: _center())),
              _trailing(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _leading() {
    if (showBack) {
      return IconButton(
        padding: EdgeInsets.zero,
        icon: const Icon(Icons.arrow_back_ios_new, size: 18),
        onPressed: onBack,
      );
    }
    if (showProfile) {
      return CircleAvatar(
        radius: 16,
        backgroundColor: HelioColors.surfaceElevated,
        child: Icon(Icons.person, size: 18, color: HelioColors.textSecondary),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _center() {
    if (dayLabel != null) {
      return HelioDateNav(
        label: dayLabel!,
        onPrev: onPrevDay,
        onNext: onNextDay,
        canGoPrev: canGoPrev,
        canGoNext: canGoNext,
      );
    }
    if (title != null && title!.isNotEmpty) {
      return Text(
        title!.toUpperCase(),
        style: HelioTypography.sectionTitle.copyWith(color: HelioColors.textPrimary),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _trailing() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (syncActive)
          Container(
            width: 8,
            height: 8,
            margin: const EdgeInsets.only(right: HelioSpacing.sm),
            decoration: const BoxDecoration(
              color: HelioColors.syncActive,
              shape: BoxShape.circle,
            ),
          ),
        if (batteryPercent != null) ...[
          Stack(
            clipBehavior: Clip.none,
            children: [
              Icon(Icons.watch_outlined, size: 22, color: HelioColors.textSecondary),
              Positioned(
                right: -2,
                bottom: -2,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: HelioColors.optimalGreen,
                    shape: BoxShape.circle,
                    border: Border.all(color: HelioColors.canvas, width: 1.5),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 6),
          Text(
            '$batteryPercent%',
            style: const TextStyle(
              fontSize: 13,
              color: HelioColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ],
    );
  }
}
