import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:heliolytics/core/ble/session_state.dart';
import 'package:heliolytics/core/ble/sync_orchestrator.dart';
import 'package:heliolytics/core/constants.dart';
import 'package:heliolytics/core/theme/app_spacing.dart';
import 'package:heliolytics/core/theme/app_theme.dart';
import 'package:heliolytics/core/utils/error_messages.dart';
import 'package:heliolytics/core/utils/formatters.dart';
import 'package:heliolytics/features/cloud_sync/presentation/providers/cloud_sync_provider.dart';
import 'package:heliolytics/features/health_data/presentation/providers/live_health_provider.dart';
import 'package:heliolytics/features/health_data/presentation/widgets/sync_log_panel.dart';
import 'package:heliolytics/features/health_data/presentation/widgets/sync_status_bar.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final snap = ref.watch(syncOrchestratorProvider);
    final apiReady = ref.watch(apiConfiguredProvider);
    final health = ref.watch(liveHealthProvider);
    final busy = snap.state == SessionState.fetching ||
        snap.state == SessionState.connecting ||
        snap.state == SessionState.authenticating;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 110,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: const Text('Settings'),
              background: DecoratedBox(decoration: BoxDecoration(gradient: headerGradient())),
            ),
          ),
          SliverToBoxAdapter(child: SyncStatusBar(snap: snap)),
          SliverPadding(
            padding: const EdgeInsets.all(AppSpacing.md),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _sectionTitle(context, 'Strap'),
                FilledButton.icon(
                  onPressed: busy ? null : () => _sync(context, ref),
                  icon: const Icon(Icons.sync),
                  label: const Text('Sync strap now'),
                ),
                const SizedBox(height: AppSpacing.sm),
                OutlinedButton.icon(
                  onPressed: busy ? null : () => _upload(ref, context),
                  icon: const Icon(Icons.cloud_upload),
                  label: const Text('Retry cloud upload'),
                ),
                const SizedBox(height: AppSpacing.sm),
                OutlinedButton.icon(
                  onPressed: () => context.push('/scan'),
                  icon: const Icon(Icons.bluetooth_searching),
                  label: const Text('Scan / change device'),
                ),
                const SizedBox(height: AppSpacing.lg),
                _sectionTitle(context, 'Cloud'),
                ListTile(
                  leading: const Icon(Icons.cloud),
                  title: const Text('API configuration'),
                  subtitle: apiReady.when(
                    data: (ok) => Text(ok ? 'Connected' : 'Not configured'),
                    loading: () => const Text('Checking…'),
                    error: (_, __) => const Text('Check failed'),
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/settings/api'),
                ),
                const SizedBox(height: AppSpacing.lg),
                _sectionTitle(context, 'About'),
                ListTile(
                  leading: const Icon(Icons.info_outline),
                  title: const Text('Build'),
                  subtitle: Text(appBuildMarker),
                ),
                health.when(
                  data: (d) => ListTile(
                    leading: const Icon(Icons.schedule),
                    title: const Text('Last sync'),
                    subtitle: Text(formatSyncAgo(d?.lastSyncedAt)),
                  ),
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                ),
                const SizedBox(height: AppSpacing.md),
                ExpansionTile(
                  title: const Text('Sync log'),
                  children: [SyncLogPanel(logs: snap.logs)],
                ),
              ]),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 80)),
        ],
      ),
    );
  }

  Widget _sectionTitle(BuildContext ctx, String t) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Text(t, style: Theme.of(ctx).textTheme.titleMedium),
    );
  }

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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Upload complete')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(friendlyError(e))),
        );
      }
    }
  }
}
