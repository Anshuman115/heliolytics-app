import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:heliolytics/core/ble/sync_orchestrator.dart';
import 'package:heliolytics/core/ble/session_state.dart';
import 'package:heliolytics/core/constants.dart';
import 'package:heliolytics/features/ble_discovery/presentation/screens/device_scan_screen.dart';
import 'package:heliolytics/features/ble_discovery/presentation/screens/sessions_screen.dart';
import 'package:heliolytics/features/ble_discovery/presentation/widgets/discovery_summary_card.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final snap = ref.watch(syncOrchestratorProvider);
    final last = snap.lastSession;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Heliolytics'),
        actions: [
          IconButton(
            icon: const Icon(Icons.folder_open),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const SessionsScreen(),
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _StatePill(state: snap.state),
          if (snap.state == SessionState.error && snap.lastErrorMessage != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Text(
                snap.lastErrorMessage!,
                style: TextStyle(color: Colors.red.shade800, fontSize: 12),
              ),
            ),
          ],
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: (snap.state == SessionState.idle ||
                    snap.state == SessionState.error)
                ? () async {
                    final hasMac = await ref
                        .read(syncOrchestratorProvider.notifier)
                        .hasSavedMac();
                    if (!context.mounted) return;
                    if (hasMac) {
                      // Known device — connect directly
                      ref
                          .read(syncOrchestratorProvider.notifier)
                          .connect();
                    } else {
                      // First time — scan so user can pick their strap
                      await Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const DeviceScanScreen(),
                        ),
                      );
                    }
                  }
                : null,
            icon: const Icon(Icons.bluetooth_searching),
            label: const Text('Connect to ring'),
          ),
          if (snap.state == SessionState.idle)
            TextButton.icon(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const DeviceScanScreen(),
                ),
              ),
              icon: const Icon(Icons.radar, size: 16),
              label: const Text('Scan for different device'),
            ),
          if (snap.state == SessionState.connected) ...[
            const SizedBox(height: 8),
            FilledButton.icon(
              onPressed: () =>
                  ref.read(syncOrchestratorProvider.notifier).startFetch(
                        typeCodes: [...knownTypeCodes, '0x26'],
                        fetchWindowHours: defaultFetchWindowHours,
                        listenDurationSec: defaultListenDurationSec,
                      ),
              icon: const Icon(Icons.download),
              label: const Text('Fetch (last 2 days)'),
            ),
          ],
          const SizedBox(height: 16),
          if (last != null) DiscoverySummaryCard(session: last),
        ],
      ),
    );
  }
}

class _StatePill extends StatelessWidget {
  final SessionState state;
  const _StatePill({required this.state});

  @override
  Widget build(BuildContext context) {
    final color = (state == SessionState.connected ||
            state == SessionState.fetching ||
            state == SessionState.listening)
        ? Colors.green
        : state == SessionState.error
            ? Colors.red
            : Colors.grey;
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text(_label(state)),
      ],
    );
  }

  String _label(SessionState s) => switch (s) {
        SessionState.noAuthKey => 'No auth key',
        SessionState.idle => 'Idle',
        SessionState.scanning => 'Scanning…',
        SessionState.connecting => 'Connecting…',
        SessionState.authenticating => 'Authenticating…',
        SessionState.connected => 'Connected',
        SessionState.fetching => 'Fetching…',
        SessionState.listening => 'Listening…',
        SessionState.error => 'Error',
      };
}
