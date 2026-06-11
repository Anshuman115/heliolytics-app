import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:heliolytics/core/config/api_config_storage.dart';
import 'package:heliolytics/core/utils/logger.dart';
import 'package:heliolytics/features/cloud_sync/domain/models/sync_payload.dart';
import 'package:heliolytics/features/cloud_sync/presentation/providers/cloud_sync_provider.dart';

Future<void> tryCloudUpload(
  Ref ref,
  SyncPayload payload,
  void Function(String) log,
) async {
  final configured = await ref.read(apiConfiguredProvider.future);
  if (!configured) {
    log('• cloud upload skipped (API not configured)');
    return;
  }
  try {
    final repo = ref.read(cloudSyncRepositoryProvider);
    await repo.uploadPayload(payload);
    log('✓ cloud upload done (${payload.rawByCode.length} types)');
  } catch (e) {
    final base = await ref.read(apiConfigStorageProvider).readBaseUrl();
    final target = (base != null && base.isNotEmpty) ? ' ($base)' : '';
    log('✗ cloud upload failed$target: $e');
    appLog('cloud upload failed', error: e);
    rethrow;
  }
}
