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
  final bool strapConnected;
  final bool showProfile;
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
    this.batteryPercent,
    this.syncActive = false,
    this.strapConnected = false,
    this.showProfile = false,
    this.actions = const [],
  });

  @override
  Size get preferredSize => const Size.fromHeight(60);

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: SizedBox(
        height: 60,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: HelioSpacing.md),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Truly centered center content
              Center(child: _center()),
              // Leading (left)
              Positioned(
                left: 0,
                child: SizedBox(width: 40, child: _leading()),
              ),
              // Trailing (right)
              Positioned(
                right: 0,
                child: _trailing(),
              ),
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
    // Default: HELIOLYTICS wordmark
    return Text(
      'HELIOLYTICS',
      style: HelioTypography.sectionTitle.copyWith(
        color: HelioColors.textPrimary,
        letterSpacing: 3,
        fontWeight: FontWeight.w800,
        fontSize: 13,
      ),
    );
  }

  Widget _trailing() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ...actions,
        // Strap status chip
        if (strapConnected || syncActive)
          Padding(
            padding: const EdgeInsets.only(right: HelioSpacing.sm),
            child: _StrapChip(connected: strapConnected, syncing: syncActive),
          ),
        // Battery
        if (batteryPercent != null) ...[
          _BatteryIcon(percent: batteryPercent!),
          const SizedBox(width: 4),
          Text(
            '$batteryPercent%',
            style: const TextStyle(
              fontSize: 12,
              color: HelioColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ],
    );
  }
}

class _StrapChip extends StatelessWidget {
  final bool connected;
  final bool syncing;

  const _StrapChip({required this.connected, required this.syncing});

  @override
  Widget build(BuildContext context) {
    final color = syncing
        ? HelioColors.recoveryMid
        : HelioColors.optimalGreen;
    final label = syncing ? 'SYNCING' : 'STRAP';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4), width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 3),
          Text(
            label,
            style: TextStyle(
              fontSize: 9,
              color: color,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _BatteryIcon extends StatelessWidget {
  final int percent;

  const _BatteryIcon({required this.percent});

  @override
  Widget build(BuildContext context) {
    final color = percent <= 20
        ? HelioColors.recoveryLow
        : percent <= 50
            ? HelioColors.recoveryMid
            : HelioColors.optimalGreen;

    return Icon(
      percent <= 20
          ? Icons.battery_1_bar
          : percent <= 50
              ? Icons.battery_4_bar
              : Icons.battery_full,
      size: 18,
      color: color,
    );
  }
}
