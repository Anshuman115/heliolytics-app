import 'package:flutter/material.dart';
import 'package:heliolytics/core/theme/app_spacing.dart';
import 'package:heliolytics/core/utils/formatters.dart';

class HomeStatusBar extends StatelessWidget {
  final DateTime? lastSyncedAt;
  final int? batteryPercent;

  const HomeStatusBar({super.key, this.lastSyncedAt, this.batteryPercent});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.md, 0, AppSpacing.md, AppSpacing.sm),
      child: Row(
        children: [
          Icon(Icons.watch, size: 14, color: theme.colorScheme.onSurface.withValues(alpha: 0.6)),
          const SizedBox(width: 6),
          Expanded(
            child: Text(formatSyncAgo(lastSyncedAt), style: theme.textTheme.labelSmall),
          ),
          if (batteryPercent != null) ...[
            Icon(Icons.battery_std, size: 14, color: theme.colorScheme.primary),
            const SizedBox(width: 4),
            Text('$batteryPercent%', style: theme.textTheme.labelSmall),
          ],
        ],
      ),
    );
  }
}
