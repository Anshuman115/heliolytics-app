import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:heliolytics/utils/app_logger.dart';
import 'package:heliolytics/models/sync_payload.dart';
import 'package:heliolytics/providers/cloud_sync_provider.dart';
import 'package:heliolytics/providers/live_health_provider.dart';

typedef UploadFn = Future<void> Function(SyncPayload payload);
typedef ConfiguredFn = Future<bool> Function();
typedef RefreshFn = void Function();

class SyncCommitter {
  final UploadFn upload;
  final ConfiguredFn isConfigured;
  final RefreshFn onHealthRefresh;
  final void Function(String) log;

  SyncCommitter({
    required this.upload,
    required this.isConfigured,
    required this.onHealthRefresh,
    required this.log,
  });

  factory SyncCommitter.fromRef(Ref ref, void Function(String) log) {
    return SyncCommitter(
      upload: (p) => ref.read(cloudSyncRepositoryProvider).uploadPayload(p),
      isConfigured: () => ref.read(apiConfiguredProvider.future),
      onHealthRefresh: () {
        ref.read(liveHealthProvider.notifier).reload();
        ref.invalidate(detailMetricsProvider); // refresh lazy series/HR/temp too
      },
      log: log,
    );
  }

  Future<void> commit(SyncPayload payload) async {
    if (!await isConfigured()) {
      log('• cloud upload skipped (API not configured)');
      return;
    }
    try {
      await upload(payload);
      log('✓ cloud upload done (${payload.rawByCode.length} types)');
      onHealthRefresh();
    } catch (e) {
      log('✗ cloud upload failed: $e');
      AppLogger.instance.log('cloud upload failed', tag: 'sync', error: e);
      rethrow;
    }
  }
}
