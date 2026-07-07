import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:heliolytics/models/session_state.dart';
import 'package:heliolytics/providers/sync_orchestrator.dart';
import 'package:heliolytics/utils/error_messages.dart';
import 'package:heliolytics/design_system/components/helio_cloud_banner.dart';
import 'package:heliolytics/design_system/components/helio_surface_card.dart';
import 'package:heliolytics/design_system/components/helio_top_bar.dart';
import 'package:heliolytics/design_system/tokens/helio_colors.dart';
import 'package:heliolytics/design_system/tokens/helio_spacing.dart';
import 'package:heliolytics/providers/band_session_provider.dart';
import 'package:heliolytics/providers/cloud_sync_provider.dart';
import 'package:heliolytics/providers/live_health_provider.dart';
import 'package:heliolytics/widgets/settings/device_hero_card.dart';
import 'package:heliolytics/widgets/settings/raw_dump_card.dart';
import 'package:heliolytics/widgets/settings/test_vibration_card.dart';
import 'package:heliolytics/widgets/settings/settings_about_section.dart';
import 'package:heliolytics/widgets/settings/settings_tile.dart';

class SettingsHubScreen extends ConsumerWidget {
  const SettingsHubScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final snap = ref.watch(syncOrchestratorProvider);
    final band = ref.watch(bandSessionProvider);
    final apiReady = ref.watch(apiConfiguredProvider);
    final health = ref.watch(liveHealthProvider);
    final busy = _isBusy(snap.state);
    final battery = health.valueOrNull?.batteryPercent;

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
                lastSynced: health.valueOrNull?.lastSyncedAt,
                busy: busy,
                onSync: () => _sync(context, ref),
                onUpload: () => _upload(ref, context),
                onScan: () => context.push('/scan'),
              ),
              const SizedBox(height: HelioSpacing.xl),
              const SettingsSectionLabel('CLOUD'),
              const SizedBox(height: HelioSpacing.sm),
              HelioSurfaceCard(
                padding: EdgeInsets.zero,
                child: SettingsTile(
                  icon: Icons.cloud_outlined,
                  iconColor: HelioColors.strainBlue,
                  title: 'API Configuration',
                  subtitle: apiReady.maybeWhen(
                    data: (ok) => ok ? 'Connected' : 'Required before first sync',
                    orElse: () => 'Checking…',
                  ),
                  statusDot: apiReady.maybeWhen(data: (ok) => ok, orElse: () => null),
                  onTap: () => context.push('/settings/api'),
                ),
              ),
              const SizedBox(height: HelioSpacing.xl),
              const SettingsSectionLabel('DIAGNOSTICS'),
              const SizedBox(height: HelioSpacing.sm),
              const TestVibrationCard(),
              const SizedBox(height: HelioSpacing.md),
              const RawDumpCard(),
              const SizedBox(height: HelioSpacing.xl),
              const SettingsSectionLabel('ABOUT'),
              const SizedBox(height: HelioSpacing.sm),
              SettingsAboutSection(syncLogs: snap.logs),
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
