import 'package:flutter/material.dart';
import 'package:heliolytics/design_system/components/helio_surface_card.dart';
import 'package:heliolytics/design_system/tokens/helio_colors.dart';
import 'package:heliolytics/design_system/tokens/helio_spacing.dart';
import 'package:heliolytics/design_system/tokens/helio_typography.dart';
import 'package:heliolytics/models/day_metric.dart';
import 'package:heliolytics/models/user_profile.dart';

class ProfileIdentity extends StatelessWidget {
  const ProfileIdentity({super.key, required this.profile});
  final UserProfile? profile;

  @override
  Widget build(BuildContext context) {
    final name = profile?.name;
    final initials = _initials(name);
    return Row(
      children: [
        CircleAvatar(
          radius: 42,
          backgroundColor: HelioColors.surfaceElevated,
          child: Text(initials, style: HelioTypography.scoreMedium),
        ),
        const SizedBox(width: HelioSpacing.lg),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name ?? 'Your profile', style: HelioTypography.scoreMedium),
              const SizedBox(height: HelioSpacing.xs),
              Text('Heliolytics member', style: HelioTypography.bodyMuted),
            ],
          ),
        ),
      ],
    );
  }

  String _initials(String? name) {
    if (name == null || name.trim().isEmpty) return '?';
    return name
        .trim()
        .split(RegExp(r'\s+'))
        .map((part) => part[0])
        .take(2)
        .join()
        .toUpperCase();
  }
}

class ProfileTodaySummary extends StatelessWidget {
  const ProfileTodaySummary({super.key, required this.day});
  final DayMetric day;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: _Score(
          label: 'RECOVERY',
          value: day.readiness,
          color: HelioColors.recoveryHigh,
        ),
      ),
      const SizedBox(width: HelioSpacing.md),
      Expanded(
        child: _Score(
          label: 'SLEEP',
          value: day.sleepScore,
          color: HelioColors.sleepBlue,
        ),
      ),
    ],
  );
}

class _Score extends StatelessWidget {
  const _Score({required this.label, required this.value, required this.color});
  final String label;
  final int? value;
  final Color color;

  @override
  Widget build(BuildContext context) => HelioSurfaceCard(
    padding: const EdgeInsets.all(HelioSpacing.lg),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: HelioTypography.sectionTitle),
        const SizedBox(height: HelioSpacing.md),
        Text(
          value == null ? '—' : '$value%',
          style: HelioTypography.scoreMedium.copyWith(color: color),
        ),
        const SizedBox(height: HelioSpacing.xs),
        Text('Today', style: HelioTypography.bodyMuted),
      ],
    ),
  );
}

class ProfileDataSection extends StatelessWidget {
  const ProfileDataSection({super.key, required this.profile});
  final UserProfile? profile;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text('PROFILE DATA', style: HelioTypography.sectionTitle),
      const SizedBox(height: HelioSpacing.md),
      _row(Icons.person_outline, 'Name', profile?.name ?? 'Not set'),
      _row(Icons.cake_outlined, 'Age', profile == null ? 'Not set' : '${profile!.age} years'),
      _row(Icons.height, 'Height', profile == null ? 'Not set' : '${profile!.heightCm.round()} cm'),
      _row(Icons.monitor_weight_outlined, 'Weight', profile == null ? 'Not set' : '${profile!.weightKg.toStringAsFixed(1)} kg'),
    ],
  );

  Widget _row(IconData icon, String label, String value) => Container(
    padding: const EdgeInsets.symmetric(vertical: HelioSpacing.md),
    decoration: const BoxDecoration(
      border: Border(bottom: BorderSide(color: HelioColors.border)),
    ),
    child: Row(
      children: [
        Icon(icon, color: HelioColors.textSecondary, size: 22),
        const SizedBox(width: HelioSpacing.md),
        Expanded(child: Text(label, style: HelioTypography.body)),
        Text(value, style: HelioTypography.bodyMuted),
      ],
    ),
  );
}
