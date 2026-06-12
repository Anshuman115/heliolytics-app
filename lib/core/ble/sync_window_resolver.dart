import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:heliolytics/core/ble/sync_window.dart';
import 'package:heliolytics/core/ble/sync_window_plan.dart';
import 'package:heliolytics/core/utils/logger.dart';
import 'package:heliolytics/features/cloud_sync/presentation/providers/cloud_sync_provider.dart';
import 'package:heliolytics/features/health_data/presentation/providers/live_health_provider.dart';

Future<SyncWindowPlan> resolveSyncWindow(Ref ref) async {
  final configured = await ref.read(apiConfiguredProvider.future);
  if (!configured) {
    return SyncWindow.plan(apiConfigured: false);
  }
  try {
    final cov = await ref.read(metricsApiClientProvider).fetchCoverage();
    return SyncWindow.plan(coverage: cov);
  } catch (e) {
    appLog('coverage fetch failed, using 10-day backfill', error: e);
    return SyncWindow.plan(coverageFailed: true);
  }
}
