import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:heliolytics/models/session_state.dart';
import 'package:heliolytics/providers/sync_orchestrator.dart';
import 'package:heliolytics/constants/constants.dart';
import 'package:heliolytics/utils/error_messages.dart';
import 'package:heliolytics/design_system/components/helio_cloud_banner.dart';
import 'package:heliolytics/design_system/components/helio_section_header.dart';
import 'package:heliolytics/design_system/components/helio_settings_tile.dart';
import 'package:heliolytics/design_system/components/helio_surface_card.dart';
import 'package:heliolytics/design_system/components/helio_top_bar.dart';
import 'package:heliolytics/design_system/tokens/helio_spacing.dart';
import 'package:heliolytics/design_system/tokens/helio_typography.dart';
import 'package:heliolytics/providers/cloud_sync_provider.dart';
import 'package:heliolytics/providers/live_health_provider.dart';
import 'package:heliolytics/widgets/sync_log_panel.dart';
import 'package:heliolytics/widgets/settings_device_card.dart';

class SettingsHubScreen extends ConsumerWidget {
  const SettingsHubScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final snap = ref.watch(syncOrchestratorProvider);
    final apiReady = ref.watch(apiConfiguredProvider);
    final health = ref.watch(liveHealthProvider);
    final busy = _isBusy(snap.state);

    return Column(
      children: [
        const HelioTopBar(title: 'More', showProfile: true),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(HelioSpacing.lg),
            children: [
              apiReady.when(
                data: (ok) => ok ? const SizedBox.shrink() : const HelioCloudBanner(),
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),
              health.when(
                data: (d) => SettingsDeviceCard(syncState: snap.state, health: d),
                loading: () => SettingsDeviceCard(syncState: snap.state),
                error: (_, __) => SettingsDeviceCard(syncState: snap.state),
              ),
              const SizedBox(height: HelioSpacing.xl),
              const HelioSectionHeader(title: 'Strap'),
              HelioSurfaceCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    HelioSettingsTile(
                      icon: Icons.sync,
                      title: 'Sync strap now',
                      subtitle: busy ? 'Sync in progress…' : 'Pull latest data from band',
                      onTap: busy ? null : () => _sync(context, ref),
                    ),
                    HelioSettingsTile(
                      icon: Icons.cloud_upload_outlined,
                      title: 'Retry cloud upload',
                      subtitle: 'Send last session to API',
                      onTap: busy ? null : () => _upload(ref, context),
                    ),
                    HelioSettingsTile(
                      icon: Icons.bluetooth_searching,
                      title: 'Scan / change device',
                      subtitle: 'Pair a different strap',
                      onTap: () => context.push('/scan'),
                      showDivider: false,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: HelioSpacing.xl),
              const HelioSectionHeader(title: 'Cloud'),
              HelioSurfaceCard(
                padding: EdgeInsets.zero,
                child: HelioSettingsTile(
                  icon: Icons.cloud_outlined,
                  title: 'API configuration',
                  subtitle: apiReady.maybeWhen(
                    data: (ok) => ok ? 'Connected' : 'Required before first sync',
                    orElse: () => 'Checking…',
                  ),
                  onTap: () => context.push('/settings/api'),
                  showDivider: false,
                ),
              ),
              const SizedBox(height: HelioSpacing.xl),
              const HelioSectionHeader(title: 'About'),
              HelioSurfaceCard(
                padding: const EdgeInsets.all(HelioSpacing.lg),
                child: Text('Build $appBuildMarker', style: HelioTypography.body),
              ),
              const SizedBox(height: HelioSpacing.md),
              HelioSurfaceCard(
                padding: EdgeInsets.zero,
                child: ExpansionTile(
                  title: Text('Sync log', style: HelioTypography.body),
                  children: [SyncLogPanel(logs: snap.logs)],
                ),
              ),
              const SizedBox(height: HelioSpacing.xxl),
            ],
          ),
        ),
      ],
    );
  }

  bool _isBusy(SessionState state) =>
      state == SessionState.fetching ||
      state == SessionState.connecting ||
      state == SessionState.authenticating;

  Future<void> _sync(BuildContext context, WidgetRef ref) async {
    if (!await ref.read(syncOrchestratorProvider.notifier).hasSavedMac()) {
      if (!context.mounted) return;
      await context.push('/scan');
      return;
    }
    await ref.read(syncOrchestratorProvider.notifier).connect();
  }

  Future<void> _upload(WidgetRef ref, BuildContext context) async {
    try {
      await ref.read(syncOrchestratorProvider.notifier).retryLastUpload();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Upload complete')));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(friendlyError(e))));
      }
    }
  }
}
