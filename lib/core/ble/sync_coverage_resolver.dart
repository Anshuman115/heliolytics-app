import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:heliolytics/core/ble/sync_fetch_plan.dart';
import 'package:heliolytics/core/constants.dart';
import 'package:heliolytics/core/utils/logger.dart';
import 'package:heliolytics/features/cloud_sync/presentation/providers/cloud_sync_provider.dart';
import 'package:heliolytics/features/health_data/presentation/providers/live_health_provider.dart';

/// Resolves BLE fetch start times from backend per-type coverage only.
Future<SyncFetchPlan> resolveSyncFetchSince(Ref ref) async {
  final configured = await ref.read(apiConfiguredProvider.future);
  if (!configured) {
    return _backfillPlan('Fetch: configure Cloud API before syncing');
  }
  try {
    final cov = await ref.read(metricsApiClientProvider).fetchCoverage();
    if (cov.types.isNotEmpty) {
      return SyncFetchPlan(
        since: earliestTypeFetchSince(cov.types),
        typeCoverage: cov.types,
        backendDataThrough: cov.dataThrough,
        logLine: 'Fetch: per-type backend coverage (${cov.types.length} types)',
      );
    }
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
      return _backfillPlan('Fetch: backend empty — first sync last $initialSyncBackfillDays days');
    }
  } catch (e) {
    appLog('coverage fetch failed, using 10-day backfill', error: e);
  }
  return _backfillPlan('Fetch: coverage unavailable — backfill $initialSyncBackfillDays days');
}

SyncFetchPlan _backfillPlan(String logLine) {
  final since = DateTime.now().subtract(const Duration(days: initialSyncBackfillDays));
  return SyncFetchPlan(since: since, logLine: logLine);
}

DateTime earliestTypeFetchSince(Map<String, DateTime?> types) {
  final fallback = DateTime.now().subtract(const Duration(days: initialSyncBackfillDays));
  var earliest = DateTime.now();
  for (final code in fetchTypeCodes) {
    final s = resolveTypeFetchSince(
      typeCode: code,
      defaultSince: fallback,
      types: types,
    );
    if (s.isBefore(earliest)) earliest = s;
  }
  return earliest;
}

DateTime resolveTypeFetchSince({
  required String typeCode,
  required DateTime defaultSince,
  Map<String, DateTime?>? types,
}) {
  if (types == null || !types.containsKey(typeCode)) {
    return defaultSince;
  }
  final through = types[typeCode];
  if (through == null) {
    return DateTime.now().subtract(const Duration(days: initialSyncBackfillDays));
  }
  return through.subtract(const Duration(minutes: syncCoverageOverlapMinutes));
}

String typeFetchLogLine(String typeCode, DateTime fetchSince, DateTime planSince) {
  if (fetchSince == planSince) return '';
  return '  $typeCode: fetch from ${fetchSince.toIso8601String()}';
}
