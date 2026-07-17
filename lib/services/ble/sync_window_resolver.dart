import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:heliolytics/services/ble/sync_window.dart';
import 'package:heliolytics/services/ble/sync_window_plan.dart';
import 'package:heliolytics/utils/app_logger.dart';
import 'package:heliolytics/providers/cloud_sync_provider.dart';
import 'package:heliolytics/providers/live_health_provider.dart';

Future<SyncWindowPlan> resolveSyncWindow(Ref ref, {int? userBackfillDays}) async {
  final configured = await ref.read(apiConfiguredProvider.future);
  if (!configured) {
    return SyncWindow.plan(apiConfigured: false);
  }
  try {
    final cov = await ref.read(metricsApiClientProvider).fetchCoverage();
    return SyncWindow.plan(coverage: cov, userBackfillDays: userBackfillDays);
  } catch (e) {
    AppLogger.instance.log(
      'coverage fetch failed, using 10-day backfill',
      tag: 'sync',
      error: e,
    );
    return SyncWindow.plan(coverageFailed: true, userBackfillDays: userBackfillDays);
  }
}
