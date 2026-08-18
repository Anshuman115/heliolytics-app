import 'package:flutter/material.dart';
import 'package:heliolytics/design_system/tokens/helio_colors.dart';
import 'package:heliolytics/design_system/tokens/helio_spacing.dart';
import 'package:heliolytics/design_system/tokens/helio_typography.dart';

class HelioBottomNav extends StatelessWidget {
  final int index;
  final ValueChanged<int> onChanged;
  final VoidCallback? onOrbTap;
  final bool showTabs;

  const HelioBottomNav({
    super.key,
    required this.index,
    required this.onChanged,
    this.onOrbTap,
    this.showTabs = true,
  });

  static const _tabs = [
    (Icons.home_outlined, Icons.home_outlined, 'Home'),
    (Icons.favorite_border, Icons.favorite_border, 'Health'),
    (Icons.directions_run_outlined, Icons.directions_run_outlined, 'Activity'),
    (Icons.more_horiz, Icons.more_horiz, 'More'),
  ];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      minimum: const EdgeInsets.fromLTRB(
        HelioSpacing.lg,
        0,
        HelioSpacing.lg,
        HelioSpacing.sm,
      ),
      child: Row(
        mainAxisAlignment: showTabs
            ? MainAxisAlignment.start
            : MainAxisAlignment.end,
        children: [
          if (showTabs)
            Expanded(
              child: Container(
                height: 72,
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(36),
                  border: Border.all(color: HelioColors.border),
                ),
                child: Row(
                  children: List.generate(
                    _tabs.length,
                    (i) => Expanded(child: _tab(i)),
                  ),
                ),
              ),
            ),
          if (showTabs) const SizedBox(width: HelioSpacing.sm),
          _orb(),
        ],
      ),
    );
  }

  Widget _orb() {
    return SizedBox(
      width: 64,
      height: 72,
      child: Material(
        color: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(32),
          side: const BorderSide(color: Color(0x443F3A89)),
        ),
        child: InkWell(
          onTap: onOrbTap,
          customBorder: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(32),
          ),
          child: Center(
            child: Container(
              width: 38,
              height: 38,
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: HelioColors.sleepBlue, width: 1.5),
              ),
              child: ClipOval(
                child: Transform.scale(
                  scale: 1.55,
                  child: Image.asset(
                    'assets/images/logo.png',
                    width: 38,
                    height: 38,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _tab(int tabIndex) {
    final selected = tabIndex == index;
    final tab = _tabs[tabIndex];
    final color = selected ? HelioColors.textPrimary : HelioColors.textMuted;
    return InkWell(
      onTap: () => onChanged(tabIndex),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(selected ? tab.$2 : tab.$1, size: 23, color: color),
          const SizedBox(height: HelioSpacing.xs),
          Text(
            tab.$3,
            style: HelioTypography.navLabel.copyWith(
              color: color,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
