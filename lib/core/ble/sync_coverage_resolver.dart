import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:heliolytics/core/ble/auth/auth_key_store.dart';
import 'package:heliolytics/core/ble/sync_cursor.dart';
import 'package:heliolytics/core/ble/sync_fetch_plan.dart';
import 'package:heliolytics/core/constants.dart';
import 'package:heliolytics/core/utils/logger.dart';
import 'package:heliolytics/features/cloud_sync/presentation/providers/cloud_sync_provider.dart';
import 'package:heliolytics/features/health_data/presentation/providers/live_health_provider.dart';

/// Resolves BLE fetch start time: backend coverage first, local cursor fallback.
Future<SyncFetchPlan> resolveSyncFetchSince(Ref ref, AuthKeyStore store) async {
  final configured = await ref.read(apiConfiguredProvider.future);
  if (configured) {
    try {
      final cov = await ref.read(metricsApiClientProvider).fetchCoverage();
      if (cov.dataThrough != null) {
        final through = cov.dataThrough!;
        final since = through.subtract(const Duration(minutes: syncCoverageOverlapMinutes));
        return SyncFetchPlan(
          since: since,
          backendDataThrough: through,
          logLine:
              'Fetch: backend data through ${through.toIso8601String()} → '
              'strap from ${since.toIso8601String()}',
        );
      }
      if (!cov.hasData) {
        final since = DateTime.now().subtract(const Duration(days: initialSyncBackfillDays));
        return SyncFetchPlan(
          since: since,
          logLine: 'Fetch: backend empty — first sync last $initialSyncBackfillDays days',
        );
      }
    } catch (e) {
      appLog('coverage fetch failed, using local cursor', error: e);
    }
  }

  final cursor = SyncCursor(store);
  final since = await cursor.fetchSince(initialBackfillDays: initialSyncBackfillDays);
  final last = await cursor.readLastSuccess();
  return SyncFetchPlan(
    since: since,
    logLine: last == null
        ? 'Fetch: local first sync — last $initialSyncBackfillDays days'
        : 'Fetch: local cursor since ${since.toIso8601String()}',
  );
}

/// Event-based types (workouts) need full backfill — incremental [since] can skip sessions.
DateTime resolveTypeFetchSince(String typeCode, DateTime since) {
  if (!workoutBackfillTypeCodes.contains(typeCode)) return since;
  final full = DateTime.now().subtract(const Duration(days: initialSyncBackfillDays));
  return since.isBefore(full) ? since : full;
}
