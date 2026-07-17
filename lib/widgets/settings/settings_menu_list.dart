import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:heliolytics/models/band_session_state.dart';
import 'package:heliolytics/design_system/components/helio_surface_card.dart';
import 'package:heliolytics/design_system/tokens/helio_colors.dart';
import 'package:heliolytics/providers/band_alerts_provider.dart';
import 'package:heliolytics/providers/band_session_provider.dart';
import 'package:heliolytics/providers/cloud_sync_provider.dart';
import 'package:heliolytics/widgets/settings/settings_tile.dart';

/// The 5 navigable Settings rows: Cloud API, Band Alerts, Diagnostics,
/// App Logs, About — each pushes its own screen.
class SettingsMenuList extends ConsumerWidget {
  const SettingsMenuList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final apiReady = ref.watch(apiConfiguredProvider);
    final alerts = ref.watch(bandAlertsProvider);
    final band = ref.watch(bandSessionProvider);

    return HelioSurfaceCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          SettingsTile(
            icon: Icons.cloud_outlined,
            iconColor: HelioColors.strainBlue,
            title: 'Cloud API',
            subtitle: apiReady.maybeWhen(
              data: (ok) => ok ? 'Connected' : 'Required before first sync',
              orElse: () => 'Checking…',
            ),
            statusDot: apiReady.maybeWhen(data: (ok) => ok, orElse: () => null),
            onTap: () => context.push('/settings/api'),
          ),
          const Divider(height: 1),
          SettingsTile(
            icon: Icons.watch_outlined,
            iconColor: HelioColors.sleepBlue,
            title: 'Band Alerts',
            subtitle: _bandAlertsSubtitle(alerts.config.enabled, alerts.isReady, band),
            statusDot: alerts.config.enabled,
            onTap: () => context.push('/settings/band-alerts'),
          ),
          const Divider(height: 1),
          SettingsTile(
            icon: Icons.build_outlined,
            iconColor: HelioColors.textMuted,
            title: 'Diagnostics',
            subtitle: 'Vibration test, raw strap dump',
            onTap: () => context.push('/settings/diagnostics'),
          ),
          const Divider(height: 1),
          SettingsTile(
            icon: Icons.article_outlined,
            iconColor: HelioColors.textMuted,
            title: 'App Logs',
            subtitle: 'View persisted app logs',
            onTap: () => context.push('/settings/logs'),
          ),
          const Divider(height: 1),
          SettingsTile(
            icon: Icons.info_outline,
            iconColor: HelioColors.textMuted,
            title: 'About',
            subtitle: 'Build info, version',
            onTap: () => context.push('/settings/about'),
          ),
        ],
      ),
    );
  }

  String _bandAlertsSubtitle(bool enabled, bool ready, BandSessionSnapshot band) {
    if (enabled) {
      if (band.isConnected) return 'Forwarding active — strap connected.';
      if (band.isConnecting) return 'Connecting to strap…';
      return band.errorMessage ?? 'Strap disconnected';
    }
    return ready ? 'Off' : 'Setup required';
  }
}
