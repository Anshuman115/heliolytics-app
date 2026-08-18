import 'package:flutter/material.dart';
import 'package:heliolytics/design_system/tokens/helio_colors.dart';
import 'package:heliolytics/design_system/tokens/helio_spacing.dart';
import 'package:heliolytics/widgets/settings/settings_action_button.dart';

class DeviceHeroActions extends StatelessWidget {
  const DeviceHeroActions({
    super.key,
    required this.busy,
    required this.onSync,
    required this.onUpload,
    required this.onScan,
  });

  final bool busy;
  final VoidCallback onSync;
  final VoidCallback onUpload;
  final VoidCallback onScan;

  @override
  Widget build(BuildContext context) {
    return Row(
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
}
