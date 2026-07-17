import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:heliolytics/providers/cloud_sync_provider.dart';
import 'package:heliolytics/providers/live_health_provider.dart';
import 'package:heliolytics/services/ble/auth/auth_key_storage.dart';
import 'package:heliolytics/services/session_store.dart';

class SyncStatus {
  final int? batteryPercent;
  final DateTime? lastSyncedAt;
  const SyncStatus({this.batteryPercent, this.lastSyncedAt});
}

final syncStatusProvider = FutureProvider<SyncStatus>((ref) async {
  final configured = await ref.watch(apiConfiguredProvider.future);
  DateTime? syncedAt;
  if (configured) {
    try {
      final cov = await ref.read(metricsApiClientProvider).fetchCoverage();
      syncedAt = cov.lastIngestAt ?? cov.dataThrough;
    } catch (_) {
      // Coverage fetch failed — fall through to local fallbacks below.
    }
  }

  final store = await ref.read(sessionStoreProvider.future);
  final ids = await store.listSessions();
  int? battery;
  if (syncedAt == null && ids.isNotEmpty) {
    final s = await store.readSessionJson(ids.first);
    syncedAt = (s.endedAt ?? s.startedAt).toLocal();
    battery = s.batteryPercent;
  } else if (ids.isNotEmpty) {
    battery = (await store.readSessionJson(ids.first)).batteryPercent;
  }
  if (battery == null) {
    final auth = AuthKeyStorage(store: ref.read(authKeyStoreProvider));
    battery = await auth.readBattery();
  }

  return SyncStatus(batteryPercent: battery, lastSyncedAt: syncedAt);
});
