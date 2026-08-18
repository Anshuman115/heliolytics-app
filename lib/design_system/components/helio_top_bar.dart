import 'package:flutter/material.dart';
import 'package:heliolytics/design_system/components/helio_date_nav.dart';
import 'package:heliolytics/design_system/components/helio_profile_badge.dart';
import 'package:heliolytics/design_system/components/helio_top_bar_status.dart';
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
  final bool emphasizeDate;
  final VoidCallback? onDateTap;
  final bool safeTop;
  final int? batteryPercent;
  final bool syncActive;
  final bool strapConnected;
  final bool showProfile;
  final String? profileLabel;
  final String? profileMetricLabel;
  final VoidCallback? onProfile;
  final List<Widget> actions;

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
    this.emphasizeDate = false,
    this.onDateTap,
    this.safeTop = true,
    this.batteryPercent,
    this.syncActive = false,
    this.strapConnected = false,
    this.showProfile = false,
    this.profileLabel,
    this.profileMetricLabel,
    this.onProfile,
    this.actions = const [],
  });

  @override
  Size get preferredSize => Size.fromHeight(safeTop ? 84 : 60);

  @override
  Widget build(BuildContext context) {
    final bar = SizedBox(
      height: 60,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: HelioSpacing.lg),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Center(child: _center()),
            Positioned(
              left: showBack ? -10 : 0,
              child: SizedBox(width: 160, child: _leading()),
            ),
            Positioned(right: showBack ? -5 : 0, child: _trailing()),
          ],
        ),
      ),
    );
    return safeTop ? SafeArea(bottom: false, child: bar) : bar;
  }

  Widget _leading() {
    if (showBack) {
      return Align(
        alignment: Alignment.centerLeft,
        child: IconButton(
          padding: EdgeInsets.zero,
          icon: const Icon(Icons.chevron_left, size: 48),
          onPressed: onBack,
        ),
      );
    }
    if (showProfile) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          HelioProfileBadge(label: profileLabel, onTap: onProfile),
          if (profileMetricLabel case final value?) ...[
            const SizedBox(width: 8),
            Container(
              height: 34,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: HelioColors.surfaceElevated,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.local_fire_department,
                    size: 18,
                    color: Color(0xFFFF642E),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    value,
                    style: HelioTypography.body.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
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
        showArrows: !showBack,
        emphasize: emphasizeDate,
        onDateTap: onDateTap,
      );
    }
    if (title != null && title!.isNotEmpty) {
      return Text(
        title!.toUpperCase(),
        style: HelioTypography.sectionTitle.copyWith(
          color: HelioColors.textPrimary,
          fontSize: 16,
          fontWeight: FontWeight.w800,
          letterSpacing: 0,
        ),
      );
    }
    // Default: HELIOLYTICS wordmark with logo
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: Image.asset('assets/images/logo.png', height: 22, width: 22),
        ),
        const SizedBox(width: HelioSpacing.xs),
        Text(
          'HELIOLYTICS',
          style: HelioTypography.sectionTitle.copyWith(
            color: HelioColors.textPrimary,
            letterSpacing: 0,
            fontWeight: FontWeight.w800,
            fontSize: 15,
          ),
        ),
      ],
    );
  }

  Widget _trailing() {
    return HelioTopBarStatus(
      actions: actions,
      strapConnected: strapConnected,
      syncActive: syncActive,
      batteryPercent: batteryPercent,
    );
  }
}
