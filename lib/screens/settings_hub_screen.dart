import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:heliolytics/models/band_session_state.dart';
import 'package:heliolytics/models/session_state.dart';
import 'package:heliolytics/providers/band_alerts_provider.dart';
import 'package:heliolytics/providers/sync_orchestrator.dart';
import 'package:heliolytics/utils/error_messages.dart';
import 'package:heliolytics/design_system/components/helio_cloud_banner.dart';
import 'package:heliolytics/design_system/components/helio_surface_card.dart';
import 'package:heliolytics/design_system/components/helio_top_bar.dart';
import 'package:heliolytics/design_system/tokens/helio_colors.dart';
import 'package:heliolytics/design_system/tokens/helio_spacing.dart';
import 'package:heliolytics/providers/band_session_provider.dart';
import 'package:heliolytics/providers/cloud_sync_provider.dart';
import 'package:heliolytics/providers/sync_status_provider.dart';
import 'package:heliolytics/widgets/settings/device_hero_card.dart';
import 'package:heliolytics/widgets/settings/settings_tile.dart';

class SettingsHubScreen extends ConsumerWidget {
  const SettingsHubScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final snap = ref.watch(syncOrchestratorProvider);
    final band = ref.watch(bandSessionProvider);
    final apiReady = ref.watch(apiConfiguredProvider);
    final alerts = ref.watch(bandAlertsProvider);
    final status = ref.watch(syncStatusProvider).valueOrNull;
    final busy = _isBusy(snap.state);
    final battery = status?.batteryPercent;

    return Column(
      children: [
        HelioTopBar(
          title: 'Settings',
          batteryPercent: battery,
          strapConnected: band.isConnected ||
              snap.state == SessionState.connected ||
              snap.state == SessionState.fetching,
          syncActive: busy,
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(HelioSpacing.lg, HelioSpacing.lg,
                HelioSpacing.lg, HelioSpacing.xxl),
            children: [
              apiReady.when(
                data: (ok) => ok ? const SizedBox.shrink() : const HelioCloudBanner(),
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),
              DeviceHeroCard(
                state: snap.state,
                battery: battery,
                lastSynced: status?.lastSyncedAt,
                busy: busy,
                onSync: () => _sync(context, ref),
                onUpload: () => _upload(ref, context),
                onScan: () => context.push('/setup/bluetooth'),
              ),
              const SizedBox(height: HelioSpacing.xl),
              HelioSurfaceCard(
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
              ),
            ],
          ),
        ),
      ],
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

  bool _isBusy(SessionState state) =>
      state == SessionState.fetching ||
      state == SessionState.connecting ||
      state == SessionState.authenticating;

  Future<void> _sync(BuildContext context, WidgetRef ref) async {
    if (!await ref.read(syncOrchestratorProvider.notifier).hasSavedMac()) {
      if (!context.mounted) return;
      await context.push('/setup/bluetooth');
      return;
    }
    await ref.read(syncOrchestratorProvider.notifier).connect();
  }

  Future<void> _upload(WidgetRef ref, BuildContext context) async {
    try {
      await ref.read(syncOrchestratorProvider.notifier).retryLastUpload();
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Upload complete')));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(friendlyError(e))));
      }
    }
  }
}
