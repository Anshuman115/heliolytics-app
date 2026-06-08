import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:heliolytics/core/ble/session_state.dart';
import 'package:heliolytics/core/ble/sync_orchestrator.dart';
import 'package:heliolytics/features/ble_discovery/presentation/screens/device_scan_screen.dart';
import 'package:heliolytics/features/health_data/domain/entities/live_strap_snapshot.dart';
import 'package:heliolytics/features/health_data/presentation/providers/live_health_provider.dart';
import 'package:heliolytics/features/health_data/presentation/screens/day_detail_screen.dart';
import 'package:heliolytics/features/health_data/presentation/widgets/sync_status_bar.dart';

class HealthHomeScreen extends ConsumerWidget {
  const HealthHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final snap = ref.watch(syncOrchestratorProvider);
    final health = ref.watch(liveHealthProvider);
    final busy = snap.state == SessionState.fetching ||
        snap.state == SessionState.connecting ||
        snap.state == SessionState.authenticating;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Heliolytics'),
        actions: [
          IconButton(
            icon: const Icon(Icons.radar),
            onPressed: busy
                ? null
                : () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const DeviceScanScreen(),
                      ),
                    ),
          ),
        ],
      ),
      body: Column(
        children: [
          SyncStatusBar(snap: snap),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: busy ? null : () => _sync(context, ref),
                    icon: const Icon(Icons.sync),
                    label: const Text('Sync strap (30d)'),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () =>
                      ref.read(liveHealthProvider.notifier).reload(),
                  icon: const Icon(Icons.refresh),
                ),
              ],
            ),
          ),
          Expanded(child: _body(context, ref, health)),
        ],
      ),
    );
  }

  Future<void> _sync(BuildContext context, WidgetRef ref) async {
    final hasMac =
        await ref.read(syncOrchestratorProvider.notifier).hasSavedMac();
    if (!context.mounted) return;
    if (!hasMac) {
      await Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => const DeviceScanScreen()),
      );
      return;
    }
    await ref.read(syncOrchestratorProvider.notifier).connect();
    await ref.read(liveHealthProvider.notifier).reload();
  }

  Widget _body(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<LiveStrapSnapshot?> health,
  ) {
    return health.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Parse error: $e')),
      data: (data) {
        if (data == null) {
          return const Center(
            child: Text('No sync yet.\nTap Sync to fetch from your strap.'),
          );
        }
        return ListView(
          children: [
            ListTile(
              title: const Text('Last sync'),
              subtitle: Text(data.syncedAt.toString()),
            ),
            const Divider(),
            const ListTile(title: Text('Daily steps (IST)')),
            ...data.days.map((d) => ListTile(
                  title: Text(d.dayKey),
                  trailing: Text('${d.steps} steps'),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => DayDetailScreen(
                        day: d,
                        sleep: data.sleepSessions,
                      ),
                    ),
                  ),
                )),
            const Divider(),
            ListTile(
              title: Text('Sleep nights (${data.sleepSessions.length})'),
            ),
            ...data.sleepSessions.take(10).map(
                  (s) => ListTile(
                    dense: true,
                    title: Text(
                      s.sessionStart.toLocal().toString().substring(0, 10),
                    ),
                    subtitle: Text(
                      '${s.totalAsleepMin} min asleep · score ${s.score}',
                    ),
                  ),
                ),
            ListTile(title: Text('HRV samples: ${data.hrvSamples.length}')),
          ],
        );
      },
    );
  }
}
