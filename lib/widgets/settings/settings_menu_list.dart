import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:heliolytics/design_system/components/helio_surface_card.dart';
import 'package:heliolytics/design_system/tokens/helio_colors.dart';
import 'package:heliolytics/design_system/tokens/helio_spacing.dart';
import 'package:heliolytics/models/band_session_state.dart';
import 'package:heliolytics/providers/auth_key_status_provider.dart';
import 'package:heliolytics/providers/band_alerts_provider.dart';
import 'package:heliolytics/providers/band_session_provider.dart';
import 'package:heliolytics/providers/cloud_sync_provider.dart';
import 'package:heliolytics/widgets/settings/settings_tile.dart';

class SettingsMenuList extends ConsumerWidget {
  const SettingsMenuList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final apiReady = ref.watch(apiConfiguredProvider);
    final hasAuthKey = ref.watch(authKeyStatusProvider);
    final alerts = ref.watch(bandAlertsProvider);
    final band = ref.watch(bandSessionProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SettingsSectionLabel('CONNECTIONS'),
        const SizedBox(height: HelioSpacing.sm),
        _group([
          SettingsTile(
            icon: Icons.cloud_outlined,
            iconColor: HelioColors.strainBlue,
            title: 'Cloud API',
            subtitle: apiReady.maybeWhen(
              data: (ok) => ok ? 'Connected' : 'Required before first sync',
              orElse: () => 'Checking...',
            ),
            statusDot: apiReady.maybeWhen(data: (ok) => ok, orElse: () => null),
            onTap: () => context.push('/settings/api'),
          ),
          SettingsTile(
            icon: Icons.key_outlined,
            iconColor: HelioColors.recoveryMid,
            title: 'Amazfit Auth Key',
            subtitle: hasAuthKey.when(
              data: (saved) =>
                  saved ? 'Saved securely' : 'Required for strap connection',
              loading: () => 'Checking...',
              error: (_, __) => 'Status unavailable',
            ),
            statusDot: hasAuthKey.valueOrNull,
            onTap: () => context.push('/settings/auth-key'),
          ),
          SettingsTile(
            icon: Icons.notifications_active_outlined,
            iconColor: HelioColors.sleepBlue,
            title: 'Band Alerts',
            subtitle: _bandAlertsSubtitle(
              alerts.config.enabled,
              alerts.isReady,
              band,
            ),
            statusDot: alerts.config.enabled,
            onTap: () => context.push('/settings/band-alerts'),
          ),
        ]),
        const SizedBox(height: HelioSpacing.xl),
        const SettingsSectionLabel('APP'),
        const SizedBox(height: HelioSpacing.sm),
        _group([
          SettingsTile(
            icon: Icons.build_outlined,
            iconColor: HelioColors.textMuted,
            title: 'Diagnostics',
            subtitle: 'Vibration tests and strap diagnostics',
            onTap: () => context.push('/settings/diagnostics'),
          ),
          SettingsTile(
            icon: Icons.article_outlined,
            iconColor: HelioColors.textMuted,
            title: 'App Logs',
            subtitle: 'View persisted app logs',
            onTap: () => context.push('/settings/logs'),
          ),
        ]),
        const SizedBox(height: HelioSpacing.xl),
        const SettingsSectionLabel('SUPPORT'),
        const SizedBox(height: HelioSpacing.sm),
        _group([
          SettingsTile(
            icon: Icons.info_outline,
            iconColor: HelioColors.textMuted,
            title: 'About',
            subtitle: 'Build information and version',
            onTap: () => context.push('/settings/about'),
          ),
        ]),
      ],
    );
  }

  Widget _group(List<Widget> rows) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      HelioSurfaceCard(
        padding: EdgeInsets.zero,
        color: HelioColors.surface.withValues(alpha: 0.62),
        showBorder: false,
        child: Column(
          children: [
            for (var index = 0; index < rows.length; index++) ...[
              rows[index],
              if (index < rows.length - 1)
                Divider(
                  height: 1,
                  thickness: 0.5,
                  indent: 52,
                  endIndent: 16,
                  color: HelioColors.textPrimary.withValues(alpha: 0.09),
                ),
            ],
          ],
        ),
      ),
    ],
  );

  String _bandAlertsSubtitle(
    bool enabled,
    bool ready,
    BandSessionSnapshot band,
  ) {
    if (enabled) {
      if (band.isConnected) return 'Forwarding active';
      if (band.isConnecting) return 'Connecting to strap...';
      return band.errorMessage ?? 'Strap disconnected';
    }
    return ready ? 'Off' : 'Setup required';
  }
}
