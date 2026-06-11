import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:heliolytics/core/config/api_config_storage.dart';
import 'package:heliolytics/core/network/api_dio.dart';
import 'package:heliolytics/features/cloud_sync/data/repositories/cloud_sync_repository_impl.dart';
import 'package:heliolytics/features/cloud_sync/domain/repositories/cloud_sync_repository.dart';

final cloudSyncRepositoryProvider = Provider<CloudSyncRepository>((ref) {
  return CloudSyncRepositoryImpl(
    config: ref.watch(apiConfigStorageProvider),
    dio: ref.watch(apiDioProvider),
  );
});

final apiConfiguredProvider = FutureProvider<bool>((ref) async {
  return ref.watch(apiConfigStorageProvider).isConfigured();
});
