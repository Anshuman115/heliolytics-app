import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:heliolytics/models/sync_coverage.dart';
import 'package:heliolytics/providers/cloud_sync_provider.dart';
import 'package:heliolytics/providers/detail_metrics_provider.dart';
import 'package:heliolytics/services/ble/auth/auth_key_storage.dart';
import 'package:heliolytics/services/session_store.dart';

/// Confirmed cloud state plus the local battery fallback.
class SyncStatus {
  const SyncStatus({
    this.batteryPercent,
    this.lastSyncedAt,
    this.coverage,
    this.coverageError,
    this.apiConfigured = true,
  });

  final int? batteryPercent;

  /// Confirmed backend `lastIngestAt` only. Null until a session is committed.
  final DateTime? lastSyncedAt;
  final SyncCoverage? coverage;

  /// Set when the coverage request failed, so staleness is never guessed.
  final Object? coverageError;
  final bool apiConfigured;

  bool get coverageKnown => coverage != null;

  /// No confirmed sync yet and the server reports no data.
  bool get needsFirstSync =>
      coverageKnown && !coverage!.hasData && lastSyncedAt == null;

  /// Age of the last confirmed sync; never negative for future timestamps.
  Duration? get timeSinceConfirmedSync {
    final at = lastSyncedAt;
    if (at == null) return null;
    final age = DateTime.now().difference(at);
    return age.isNegative ? Duration.zero : age;
  }

  /// True only after more than 72 hours without a confirmed sync.
  bool get isStaleConfirmedSync => isStaleConfirmedSyncAt(DateTime.now());

  /// Boundary check against [now], so exactly 72 hours is not stale.
  bool isStaleConfirmedSyncAt(DateTime now) {
    final at = lastSyncedAt;
    if (at == null) return false;
    return now.difference(at) > const Duration(hours: 72);
  }

  /// Factual reminder shown when the confirmed sync is older than 72 hours.
  static const String staleSyncMessage =
      'Sync regularly to reduce gaps in short-retention metrics such as '
      'respiration.';
}

final syncStatusProvider = FutureProvider<SyncStatus>((ref) async {
  final configured = await ref.watch(apiConfiguredProvider.future);
  SyncCoverage? coverage;
  Object? coverageError;
  if (configured) {
    try {
      coverage = await ref.read(metricsApiClientProvider).fetchCoverage();
    } catch (error) {
      coverageError = error;
    }
  }

  final store = await ref.read(sessionStoreProvider.future);
  final ids = await store.listSessions();
  int? battery;
  if (ids.isNotEmpty) {
    battery = (await store.readSessionJson(ids.first)).batteryPercent;
  }
  if (battery == null) {
    final auth = AuthKeyStorage(store: ref.read(authKeyStoreProvider));
    battery = await auth.readBattery();
  }

  return SyncStatus(
    batteryPercent: battery,
    lastSyncedAt: coverage?.lastIngestAt,
    coverage: coverage,
    coverageError: coverageError,
    apiConfigured: configured,
  );
});
