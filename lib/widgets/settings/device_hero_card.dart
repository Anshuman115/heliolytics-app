import 'package:flutter/material.dart';
import 'package:heliolytics/models/session_state.dart';
import 'package:heliolytics/utils/formatters.dart';
import 'package:heliolytics/utils/sync_status.dart';
import 'package:heliolytics/design_system/components/helio_surface_card.dart';
import 'package:heliolytics/design_system/tokens/helio_colors.dart';
import 'package:heliolytics/design_system/tokens/helio_spacing.dart';
import 'package:heliolytics/design_system/tokens/helio_typography.dart';
import 'package:heliolytics/widgets/settings/settings_action_button.dart';

/// Strap status + battery + sync/upload/scan actions — the Settings hero card.
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
    return HelioSurfaceCard(
      padding: const EdgeInsets.all(HelioSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _header(color),
          if (lastSynced != null) ...[
            const SizedBox(height: HelioSpacing.sm),
            const Divider(height: 1, color: Color(0x14FFFFFF)),
            const SizedBox(height: HelioSpacing.sm),
            Text('Last synced ${formatWorkoutTime(lastSynced!)}',
                style: HelioTypography.bodyMuted.copyWith(fontSize: 11)),
          ],
          const SizedBox(height: HelioSpacing.md),
          const Divider(height: 1, color: Color(0x14FFFFFF)),
          const SizedBox(height: HelioSpacing.md),
          _actions(),
        ],
      ),
    );
  }

  Widget _header(Color color) => Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color.withValues(alpha: 0.3)),
            ),
            child: Icon(Icons.watch_outlined, color: color, size: 24),
          ),
          const SizedBox(width: HelioSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Helio Strap',
                    style: HelioTypography.body.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Row(children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 5),
                  Text(syncStatusLabel(state),
                      style: HelioTypography.bodyMuted.copyWith(fontSize: 12)),
                ]),
              ],
            ),
          ),
          if (battery != null) _battery(battery!),
        ],
      );

  Widget _battery(int pct) => Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text('$pct%',
              style: HelioTypography.scoreMedium.copyWith(
                fontSize: 24,
                color: pct <= 20
                    ? HelioColors.recoveryLow
                    : pct <= 50
                        ? HelioColors.recoveryMid
                        : HelioColors.optimalGreen,
              )),
          Text('BATTERY', style: HelioTypography.capsLabel.copyWith(fontSize: 9)),
        ],
      );

  Widget _actions() => Row(
        children: [
          Expanded(
            child: SettingsActionButton(
              icon: busy ? null : Icons.sync,
              label: busy ? 'SYNCING…' : 'SYNC NOW',
              color: HelioColors.strainBlue,
              loading: busy,
              onTap: busy ? null : onSync,
            ),
          ),
          const SizedBox(width: HelioSpacing.sm),
          Expanded(
            child: SettingsActionButton(
              icon: Icons.cloud_upload_outlined,
              label: 'UPLOAD',
              color: HelioColors.optimalGreen,
              onTap: busy ? null : onUpload,
            ),
          ),
          const SizedBox(width: HelioSpacing.sm),
          Expanded(
            child: SettingsActionButton(
              icon: Icons.bluetooth_searching,
              label: 'SCAN',
              color: HelioColors.textMuted,
              onTap: onScan,
            ),
          ),
        ],
      );
}
