import 'package:flutter/material.dart';
import 'package:heliolytics/design_system/tokens/helio_colors.dart';
import 'package:heliolytics/design_system/tokens/helio_spacing.dart';
import 'package:heliolytics/design_system/tokens/helio_typography.dart';

class HelioBottomNav extends StatelessWidget {
  final int index;
  final ValueChanged<int> onChanged;

  const HelioBottomNav({super.key, required this.index, required this.onChanged});

  static const _tabs = [
    (Icons.home_outlined, Icons.home, 'Home'),
    (Icons.bedtime_outlined, Icons.bedtime, 'Sleep'),
    (Icons.directions_run_outlined, Icons.directions_run, 'Activity'),
    (Icons.more_horiz, Icons.more_horiz, 'More'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: HelioColors.surface,
        border: Border(top: BorderSide(color: HelioColors.border)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            children: List.generate(_tabs.length, (i) {
              final selected = i == index;
              final tab = _tabs[i];
              return Expanded(
                child: InkWell(
                  onTap: () => onChanged(i),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        selected ? tab.$2 : tab.$1,
                        size: 22,
                        color: selected ? HelioColors.textPrimary : HelioColors.textMuted,
                      ),
                      const SizedBox(height: HelioSpacing.xs),
                      Text(
                        tab.$3.toUpperCase(),
                        style: HelioTypography.navLabel.copyWith(
                          color: selected ? HelioColors.textPrimary : HelioColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
