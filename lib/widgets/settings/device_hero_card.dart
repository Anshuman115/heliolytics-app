import 'package:flutter/material.dart';
import 'package:heliolytics/design_system/components/helio_surface_card.dart';
import 'package:heliolytics/design_system/tokens/helio_colors.dart';
import 'package:heliolytics/design_system/tokens/helio_spacing.dart';
import 'package:heliolytics/design_system/tokens/helio_typography.dart';
import 'package:heliolytics/models/session_state.dart';
import 'package:heliolytics/utils/formatters.dart';
import 'package:heliolytics/utils/sync_status.dart';
import 'package:heliolytics/widgets/settings/device_hero_actions.dart';
import 'package:heliolytics/widgets/settings/device_product_visual.dart';

class DeviceHeroCard extends StatelessWidget {
  final SessionState state;
  final int? battery;
  final DateTime? lastSynced;
  final bool busy;
  final VoidCallback onSync;
  final VoidCallback onUpload;
  final VoidCallback onScan;

  const DeviceHeroCard({
    super.key,
    required this.state,
    required this.battery,
    required this.lastSynced,
    required this.busy,
    required this.onSync,
    required this.onUpload,
    required this.onScan,
  });

  @override
  Widget build(BuildContext context) {
    final color = syncStatusColor(state);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _statusHeader(color),
        const SizedBox(height: HelioSpacing.md),
        Stack(
          children: [
            const DeviceProductVisual(),
            if (battery != null)
              Positioned(right: 0, bottom: HelioSpacing.lg, child: _battery()),
          ],
        ),
        const SizedBox(height: HelioSpacing.md),
        HelioSurfaceCard(
          padding: const EdgeInsets.all(HelioSpacing.md),
          child: DeviceHeroActions(
            busy: busy,
            onSync: onSync,
            onUpload: onUpload,
            onScan: onScan,
          ),
        ),
      ],
    );
  }

  Widget _statusHeader(Color color) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_connectionEyebrow(), style: _eyebrow(color)),
            const SizedBox(height: 3),
            Text(
              'HELIO STRAP',
              style: HelioTypography.body.copyWith(
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
      Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text('LAST SYNC', style: _eyebrow(HelioColors.textSecondary)),
          const SizedBox(height: 3),
          Text(
            lastSynced == null ? 'NOT YET' : formatChartTime(lastSynced!),
            style: HelioTypography.body.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    ],
  );

  TextStyle _eyebrow(Color color) => HelioTypography.capsLabel.copyWith(
    color: color,
    fontSize: 10,
    fontWeight: FontWeight.w700,
  );

  String _connectionEyebrow() => switch (state) {
    SessionState.connected || SessionState.fetching => 'CONNECTED TO',
    SessionState.connecting || SessionState.authenticating => 'CONNECTING TO',
    _ => 'NOT CONNECTED TO',
  };

  Widget _battery() => Column(
    crossAxisAlignment: CrossAxisAlignment.end,
    children: [
      Text(
        '${battery!}%',
        style: HelioTypography.scoreMedium.copyWith(fontSize: 30),
      ),
      Text('BATTERY', style: HelioTypography.capsLabel.copyWith(fontSize: 9)),
    ],
  );
}
