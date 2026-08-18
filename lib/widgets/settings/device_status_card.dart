import 'package:flutter/material.dart';
import 'package:heliolytics/design_system/components/helio_surface_card.dart';
import 'package:heliolytics/design_system/tokens/helio_colors.dart';
import 'package:heliolytics/design_system/tokens/helio_spacing.dart';
import 'package:heliolytics/design_system/tokens/helio_typography.dart';
import 'package:heliolytics/models/session_state.dart';
import 'package:heliolytics/utils/formatters.dart';
import 'package:heliolytics/utils/sync_status.dart';
import 'package:heliolytics/widgets/settings/device_status_actions.dart';

class DeviceStatusCard extends StatelessWidget {
  const DeviceStatusCard({
    super.key,
    required this.state,
    required this.battery,
    required this.lastSynced,
    required this.busy,
    required this.onSync,
    required this.onUpload,
    required this.onScan,
  });

  final SessionState state;
  final int? battery;
  final DateTime? lastSynced;
  final bool busy;
  final VoidCallback onSync;
  final VoidCallback onUpload;
  final VoidCallback onScan;

  @override
  Widget build(BuildContext context) => HelioSurfaceCard(
    padding: EdgeInsets.zero,
    child: Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            HelioSpacing.lg,
            HelioSpacing.lg,
            HelioSpacing.md,
            HelioSpacing.md,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _statusDot(),
                        const SizedBox(width: HelioSpacing.xs),
                        Text(
                          syncStatusLabel(state).toUpperCase(),
                          style: HelioTypography.capsLabel.copyWith(
                            color: syncStatusColor(state),
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: HelioSpacing.sm),
                    Text(
                      'Helio strap',
                      style: HelioTypography.body.copyWith(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: HelioSpacing.xs),
                    Text(
                      lastSynced == null
                          ? 'Ready to connect'
                          : formatSyncAgo(lastSynced),
                      style: HelioTypography.bodyMuted,
                    ),
                    const SizedBox(height: HelioSpacing.md),
                    _batteryChip(),
                  ],
                ),
              ),
              const SizedBox(width: HelioSpacing.sm),
              SizedBox(
                width: 116,
                height: 116,
                child: Image.asset(
                  'assets/images/helio_strap.png',
                  fit: BoxFit.contain,
                  semanticLabel: 'Helio strap',
                ),
              ),
            ],
          ),
        ),
        DeviceStatusActions(
          busy: busy,
          onSync: onSync,
          onUpload: onUpload,
          onScan: onScan,
        ),
      ],
    ),
  );

  Widget _statusDot() => Container(
    width: 7,
    height: 7,
    decoration: BoxDecoration(
      color: syncStatusColor(state),
      shape: BoxShape.circle,
    ),
  );

  Widget _batteryChip() => Container(
    padding: const EdgeInsets.symmetric(
      horizontal: HelioSpacing.sm,
      vertical: HelioSpacing.xs,
    ),
    decoration: BoxDecoration(
      color: HelioColors.surfaceElevated,
      borderRadius: BorderRadius.circular(999),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.battery_5_bar,
          size: 16,
          color: battery == null
              ? HelioColors.textMuted
              : HelioColors.optimalGreen,
        ),
        const SizedBox(width: HelioSpacing.xs),
        Text(
          battery == null ? 'Battery unknown' : '$battery% battery',
          style: HelioTypography.bodyMuted.copyWith(fontSize: 12),
        ),
      ],
    ),
  );
}
