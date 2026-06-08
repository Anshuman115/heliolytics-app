import 'package:flutter/material.dart';
import 'package:heliolytics/core/ble/session_state.dart';

class SyncStatusBar extends StatelessWidget {
  final SessionSnapshot snap;
  const SyncStatusBar({super.key, required this.snap});

  @override
  Widget build(BuildContext context) {
    final color = switch (snap.state) {
      SessionState.fetching => Colors.orange,
      SessionState.connecting || SessionState.authenticating => Colors.blue,
      SessionState.error => Colors.red,
      SessionState.connected => Colors.green,
      _ => Colors.grey,
    };
    final label = switch (snap.state) {
      SessionState.idle => 'Ready — tap Sync to fetch last 30 days',
      SessionState.fetching => 'Syncing ${snap.currentTypeCode ?? '…'}',
      SessionState.connecting => 'Connecting…',
      SessionState.authenticating => 'Authenticating…',
      SessionState.connected => 'Connected',
      SessionState.error => snap.lastErrorMessage ?? 'Error',
      _ => snap.state.name,
    };
    return Material(
      color: color.withValues(alpha: 0.12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(Icons.circle, size: 10, color: color),
            const SizedBox(width: 8),
            Expanded(child: Text(label, style: TextStyle(color: color))),
          ],
        ),
      ),
    );
  }
}
