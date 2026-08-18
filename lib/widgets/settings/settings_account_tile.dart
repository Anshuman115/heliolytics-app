import 'package:flutter/material.dart';
import 'package:heliolytics/design_system/components/helio_surface_card.dart';
import 'package:heliolytics/design_system/tokens/helio_colors.dart';
import 'package:heliolytics/design_system/tokens/helio_spacing.dart';
import 'package:heliolytics/design_system/tokens/helio_typography.dart';
import 'package:heliolytics/models/user_profile.dart';

class SettingsAccountTile extends StatelessWidget {
  const SettingsAccountTile({super.key, required this.profile, this.onTap});

  final UserProfile? profile;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final name = profile?.name.trim();
    final displayName = name == null || name.isEmpty ? '?' : name;
    final hasName = displayName != '?';
    return HelioSurfaceCard(
      padding: EdgeInsets.zero,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(HelioSpacing.md),
        child: Row(
          children: [
            _avatar(displayName),
            const SizedBox(width: HelioSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    hasName ? displayName : 'Complete your profile',
                    style: HelioTypography.body.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    hasName
                        ? 'Personal metrics and goals'
                        : 'Add details to improve your insights',
                    style: HelioTypography.bodyMuted,
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right,
              size: 22,
              color: HelioColors.textMuted,
            ),
          ],
        ),
      ),
    );
  }

  Widget _avatar(String name) {
    final initials = name == '?' ? name : _initials(name);
    return CircleAvatar(
      radius: 24,
      backgroundColor: HelioColors.sleepBlue.withValues(alpha: 0.18),
      child: Text(
        initials,
        style: HelioTypography.body.copyWith(
          color: HelioColors.sleepBlue,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  String _initials(String name) => name
      .split(RegExp(r'\s+'))
      .map((part) => part[0])
      .take(2)
      .join()
      .toUpperCase();
}
