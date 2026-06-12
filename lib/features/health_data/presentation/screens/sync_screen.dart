import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:heliolytics/core/ble/session_state.dart';
import 'package:heliolytics/core/ble/sync_orchestrator.dart';
import 'package:heliolytics/core/constants.dart';
import 'package:heliolytics/core/theme/app_spacing.dart';
import 'package:heliolytics/core/theme/app_theme.dart';
import 'package:heliolytics/core/utils/error_messages.dart';
import 'package:heliolytics/features/cloud_sync/presentation/providers/cloud_sync_provider.dart';
import 'package:heliolytics/features/health_data/presentation/widgets/sync_log_panel.dart';
import 'package:heliolytics/features/health_data/presentation/widgets/sync_status_bar.dart';

class SyncScreen extends ConsumerWidget {
  const SyncScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final snap = ref.watch(syncOrchestratorProvider);
    final apiReady = ref.watch(apiConfiguredProvider);
    final busy = snap.state == SessionState.fetching ||
        snap.state == SessionState.connecting ||
        snap.state == SessionState.authenticating;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 100,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: const Text('Sync'),
              background: DecoratedBox(decoration: BoxDecoration(gradient: headerGradient())),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.settings),
                onPressed: () => context.push('/settings/api'),
              ),
            ],
          ),
          SliverToBoxAdapter(child: SyncStatusBar(snap: snap)),
          SliverToBoxAdapter(child: SyncLogPanel(logs: snap.logs)),
          SliverPadding(
            padding: const EdgeInsets.all(AppSpacing.md),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
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
                const SizedBox(height: AppSpacing.md),
                apiReady.when(
                  data: (ok) => Text(
                    ok ? 'API configured ✓' : 'Set API URL + key in Settings',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const Text('API check failed'),
                ),
              ]),
            ),
          ),
        ],
      ),
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
