import 'package:flutter/material.dart';
import 'package:heliolytics/core/ble/session_state.dart';
import 'package:heliolytics/core/constants.dart';
import 'package:heliolytics/core/theme/app_spacing.dart';

class SyncStatusBar extends StatelessWidget {
  final SessionSnapshot snap;
  const SyncStatusBar({super.key, required this.snap});

  @override
  Widget build(BuildContext context) {
    final color = switch (snap.state) {
      SessionState.fetching => const Color(0xFFFB923C),
      SessionState.connecting || SessionState.authenticating => const Color(0xFF38BDF8),
      SessionState.error => const Color(0xFFF87171),
      SessionState.connected => const Color(0xFF34D399),
      _ => Colors.grey,
    };
    final label = switch (snap.state) {
      SessionState.idle => 'Ready — auto-sync on open (incremental after first $initialSyncBackfillDays d)',
      SessionState.fetching => _fetchLabel(),
      SessionState.connecting => 'Connecting to strap…',
      SessionState.authenticating => 'Authenticating…',
      SessionState.connected => 'Connected',
      SessionState.error => snap.lastErrorMessage ?? 'Sync error',
      _ => snap.state.name,
    };
    final batt = snap.lastSession?.batteryPercent;
    return Material(
      color: color.withValues(alpha: 0.12),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                ExcludeSemantics(
                  child: Icon(Icons.circle, size: 10, color: color),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(child: Text(label, style: TextStyle(color: color))),
                if (batt != null) Text('$batt%', style: TextStyle(color: color)),
              ],
            ),
            if (snap.state == SessionState.fetching) ...[
              const SizedBox(height: AppSpacing.sm),
              const LinearProgressIndicator(),
            ],
          ],
        ),
      ),
    );
  }

  String _fetchLabel() {
    final code = snap.currentTypeCode;
    if (code == null) return 'Syncing data…';
    final name = typeCodeLabels[code] ?? 'health data';
    return 'Syncing $name…';
  }
}
