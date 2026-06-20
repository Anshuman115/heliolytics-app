import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:heliolytics/models/session_state.dart';
import 'package:heliolytics/providers/sync_orchestrator.dart';
import 'package:heliolytics/constants/constants.dart';
import 'package:heliolytics/utils/formatters.dart';
import 'package:heliolytics/design_system/tokens/helio_colors.dart';
import 'package:heliolytics/design_system/tokens/helio_spacing.dart';
import 'package:heliolytics/providers/live_health_provider.dart';

class HelioSyncStrip extends ConsumerWidget {
  const HelioSyncStrip({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final snap = ref.watch(syncOrchestratorProvider);
    final health = ref.watch(liveHealthProvider).valueOrNull;
    final busy = snap.state == SessionState.fetching ||
        snap.state == SessionState.connecting ||
        snap.state == SessionState.authenticating ||
        snap.state == SessionState.scanning;

    final label = _label(snap);
    final color = switch (snap.state) {
      SessionState.error => HelioColors.syncError,
      SessionState.fetching ||
      SessionState.connecting ||
      SessionState.authenticating ||
      SessionState.scanning =>
        HelioColors.syncActive,
      _ => HelioColors.textSecondary,
    };

    final batt = health?.batteryPercent ?? snap.lastSession?.batteryPercent;
    final suffix = busy ? null : _idleSuffix(health?.lastSyncedAt, batt);

    return Material(
      color: color.withValues(alpha: 0.08),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: HelioSpacing.lg,
          vertical: HelioSpacing.sm,
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
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _label(SessionSnapshot snap) {
    return switch (snap.state) {
      SessionState.connecting => 'Connecting to strap…',
      SessionState.authenticating => 'Authenticating…',
      SessionState.scanning => 'Scanning for strap…',
      SessionState.fetching => _fetchLabel(snap),
      SessionState.error => snap.lastErrorMessage ?? 'Sync error',
      _ => 'Ready',
    };
  }

  String _fetchLabel(SessionSnapshot snap) {
    final code = snap.currentTypeCode;
    final done = snap.typeResults.length;
    final total = fetchTypeCodes.length;
    final typeName = code != null ? (typeCodeLabels[code] ?? 'data') : 'data';
    final base = 'Syncing strap · $typeName ($done/$total)';
    if (done == 0) {
      return '$base · first sync · up to $initialSyncBackfillDays days';
    }
    return base;
  }

  String _idleSuffix(DateTime? syncedAt, int? batt) {
    final ago = formatSyncAgo(syncedAt).replaceFirst('Synced ', 'Last synced ');
    if (batt != null) return '$ago · 🔋 $batt%';
    return ago;
  }
}
