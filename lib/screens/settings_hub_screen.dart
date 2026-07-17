import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:heliolytics/models/session_state.dart';
import 'package:heliolytics/providers/sync_orchestrator.dart';
import 'package:heliolytics/utils/error_messages.dart';
import 'package:heliolytics/design_system/components/helio_cloud_banner.dart';
import 'package:heliolytics/design_system/components/helio_top_bar.dart';
import 'package:heliolytics/design_system/tokens/helio_spacing.dart';
import 'package:heliolytics/providers/band_session_provider.dart';
import 'package:heliolytics/providers/cloud_sync_provider.dart';
import 'package:heliolytics/providers/sync_status_provider.dart';
import 'package:heliolytics/widgets/settings/device_hero_card.dart';
import 'package:heliolytics/widgets/settings/settings_menu_list.dart';

class SettingsHubScreen extends ConsumerWidget {
  const SettingsHubScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final snap = ref.watch(syncOrchestratorProvider);
    final band = ref.watch(bandSessionProvider);
    final apiReady = ref.watch(apiConfiguredProvider);
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
              const SettingsMenuList(),
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
