import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:heliolytics/core/ble/sync_orchestrator.dart';
import 'package:heliolytics/features/ble_discovery/data/session_store.dart';
import 'package:heliolytics/features/health_data/data/builders/health_snapshot_builder.dart';
import 'package:heliolytics/features/health_data/domain/entities/live_strap_snapshot.dart';

final liveHealthProvider =
    AsyncNotifierProvider<LiveHealthNotifier, LiveStrapSnapshot?>(
  LiveHealthNotifier.new,
);

class LiveHealthNotifier extends AsyncNotifier<LiveStrapSnapshot?> {
  @override
  Future<LiveStrapSnapshot?> build() async {
    ref.listen(syncOrchestratorProvider, (prev, next) {
      if (next.lastSession != null &&
          next.lastSession?.sessionId != prev?.lastSession?.sessionId) {
        ref.invalidateSelf();
      }
    });
    final store = await ref.watch(sessionStoreProvider.future);
    return HealthSnapshotBuilder(store).buildLatest();
  }

  Future<void> reload() async {
    state = const AsyncLoading();
    state = AsyncData(await build());
  }
}
