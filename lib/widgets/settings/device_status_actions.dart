import 'package:flutter/material.dart';
import 'package:heliolytics/design_system/tokens/helio_colors.dart';
import 'package:heliolytics/design_system/tokens/helio_typography.dart';

class DeviceStatusActions extends StatelessWidget {
  const DeviceStatusActions({
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
  Widget build(BuildContext context) => Container(
    decoration: const BoxDecoration(
      border: Border(top: BorderSide(color: HelioColors.border)),
    ),
    child: Row(
      children: [
        _action(Icons.sync, busy ? 'SYNCING' : 'SYNC', busy ? null : onSync),
        _action(Icons.cloud_upload_outlined, 'UPLOAD', busy ? null : onUpload),
        _action(Icons.bluetooth_searching, 'SCAN', onScan),
      ],
    ),
  );

  Widget _action(IconData icon, String label, VoidCallback? onTap) => Expanded(
    child: InkWell(
      onTap: onTap,
      child: SizedBox(
        height: 54,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 19,
              color: onTap == null
                  ? HelioColors.textMuted
                  : HelioColors.textPrimary,
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: HelioTypography.capsLabel.copyWith(
                color: onTap == null
                    ? HelioColors.textMuted
                    : HelioColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
