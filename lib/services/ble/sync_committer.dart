import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:heliolytics/models/ingest_result.dart';
import 'package:heliolytics/models/sync_payload.dart';
import 'package:heliolytics/providers/cloud_sync_provider.dart';
import 'package:heliolytics/providers/health_data_refresh_coordinator.dart';
import 'package:heliolytics/utils/app_logger.dart';
import 'package:heliolytics/utils/error_messages.dart';

typedef UploadFn = Future<IngestResult> Function(SyncPayload payload);
typedef ConfiguredFn = Future<bool> Function();
typedef RefreshFn = Future<void> Function();

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
      onHealthRefresh: () =>
          ref.read(healthDataRefreshCoordinatorProvider).afterSync(),
      log: log,
    );
  }

  /// Returns the typed upload outcome, or null when no upload was attempted.
  Future<IngestResult?> commit(SyncPayload payload) async {
    if (!await isConfigured()) {
      log('• cloud upload skipped (API not configured)');
      return null;
    }
    try {
      final result = await upload(payload);
      log('✓ cloud upload done (${_summary(result)})');
      for (final warning in result.warnings) {
        log('• $warning');
      }
      await onHealthRefresh();
      return result;
    } catch (e) {
      log('✗ cloud upload failed: ${friendlyError(e)}');
      AppLogger.instance.log('cloud upload failed', tag: 'sync', error: e);
      rethrow;
    }
  }

  String _summary(IngestResult result) {
    final statuses = <String>[];
    for (final type in result.types.values) {
      statuses.add('${type.code} ${type.status.wire}');
    }
    final partial = result.complete ? '' : ', partial';
    final dropped = result.droppedRows > 0
        ? ', ${result.droppedRows} dropped'
        : '';
    return '${statuses.join(', ')}$partial$dropped';
  }
}
