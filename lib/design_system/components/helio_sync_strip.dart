import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:heliolytics/models/session_state.dart';
import 'package:heliolytics/providers/backfill_days_provider.dart';
import 'package:heliolytics/providers/sync_orchestrator.dart';
import 'package:heliolytics/constants/constants.dart';
import 'package:heliolytics/utils/formatters.dart';
import 'package:heliolytics/design_system/tokens/helio_colors.dart';
import 'package:heliolytics/design_system/tokens/helio_spacing.dart';
import 'package:heliolytics/providers/sync_status_provider.dart';

class HelioSyncStrip extends ConsumerWidget {
  const HelioSyncStrip({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final snap = ref.watch(syncOrchestratorProvider);
    final backfillDays = ref.watch(backfillDaysProvider);
    final status = ref.watch(syncStatusProvider).valueOrNull;
    final busy =
        snap.state == SessionState.fetching ||
        snap.state == SessionState.connecting ||
        snap.state == SessionState.authenticating ||
        snap.state == SessionState.scanning;

    final label = _label(snap, backfillDays);
    final color = switch (snap.state) {
      SessionState.error => HelioColors.syncError,
      SessionState.fetching ||
      SessionState.connecting ||
      SessionState.authenticating ||
      SessionState.scanning => HelioColors.syncActive,
      _ => HelioColors.textSecondary,
    };

    final batt = status?.batteryPercent ?? snap.lastSession?.batteryPercent;
    final suffix = busy ? null : _idleSuffix(status?.lastSyncedAt, batt);

    return Material(
      color: HelioColors.surface.withValues(alpha: 0.72),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: HelioSpacing.lg,
          vertical: HelioSpacing.xs,
        ),
        child: Row(
          children: [
            if (busy)
              SizedBox(
                width: 12,
                height: 12,
                child: CircularProgressIndicator(strokeWidth: 2, color: color),
              )
            else
              Icon(Icons.circle, size: 8, color: color),
            const SizedBox(width: HelioSpacing.sm),
            Expanded(
              child: Text(
                suffix != null ? '$label · $suffix' : label,
                style: TextStyle(fontSize: 12, color: color),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _label(SessionSnapshot snap, int? backfillDays) {
    return switch (snap.state) {
      SessionState.connecting => 'Connecting to strap…',
      SessionState.authenticating => 'Authenticating…',
      SessionState.scanning => 'Scanning for strap…',
      SessionState.fetching => _fetchLabel(snap, backfillDays),
      SessionState.error => 'Strap unavailable',
      _ => 'Ready',
    };
  }

  String _fetchLabel(SessionSnapshot snap, int? backfillDays) {
    final code = snap.currentTypeCode;
    final done = snap.typeResults.length;
    final total = fetchTypeCodes.length;
    final typeName = code != null ? (typeCodeLabels[code] ?? 'data') : 'data';
    final base = 'Syncing strap · $typeName ($done/$total)';
    if (done == 0 && backfillDays != null) {
      return '$base · first sync · up to $backfillDays days';
    }
    return base;
  }

  String _idleSuffix(DateTime? syncedAt, int? batt) {
    final ago = formatSyncAgo(syncedAt).replaceFirst('Synced ', 'Last synced ');
    if (batt != null) return '$ago · $batt% battery';
    return ago;
  }
}
