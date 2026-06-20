import 'package:flutter/material.dart';
import 'package:heliolytics/models/session_state.dart';
import 'package:heliolytics/utils/formatters.dart';
import 'package:heliolytics/design_system/components/helio_surface_card.dart';
import 'package:heliolytics/design_system/tokens/helio_colors.dart';
import 'package:heliolytics/design_system/tokens/helio_spacing.dart';
import 'package:heliolytics/design_system/tokens/helio_typography.dart';
import 'package:heliolytics/models/cloud_metrics_snapshot.dart';

class SettingsDeviceCard extends StatelessWidget {
  final SessionState syncState;
  final CloudMetricsSnapshot? health;

  const SettingsDeviceCard({
    super.key,
    required this.syncState,
    this.health,
  });

  @override
  Widget build(BuildContext context) {
    final battery = health?.batteryPercent;
    final synced = formatSyncAgo(health?.lastSyncedAt);
    final status = _statusLabel(syncState);

    return HelioSurfaceCard(
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: HelioColors.surfaceElevated,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(Icons.watch, color: HelioColors.strainBlue, size: 26),
          ),
          const SizedBox(width: HelioSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Helio strap', style: HelioTypography.body.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(status, style: HelioTypography.bodyMuted),
                Text(synced, style: HelioTypography.bodyMuted),
              ],
            ),
          ),
          if (battery != null)
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('$battery%', style: HelioTypography.scoreMedium.copyWith(fontSize: 22)),
                Text('BATTERY', style: HelioTypography.capsLabel),
              ],
            ),
        ],
      ),
    );
  }

  String _statusLabel(SessionState state) {
    return switch (state) {
      SessionState.idle => 'Ready to sync',
      SessionState.noAuthKey => 'Auth key required',
      SessionState.scanning => 'Scanning…',
      SessionState.connecting => 'Connecting…',
      SessionState.authenticating => 'Pairing…',
      SessionState.connected => 'Connected',
      SessionState.fetching => 'Syncing data…',
      SessionState.listening => 'Listening…',
      SessionState.error => 'Sync error',
    };
  }
}
