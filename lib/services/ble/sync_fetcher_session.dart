import 'package:heliolytics/models/dump_entry.dart';
import 'package:heliolytics/models/session.dart';
import 'package:heliolytics/models/session_catalog.dart';
import 'package:heliolytics/models/strap_health_config.dart';
import 'package:heliolytics/services/ble/auth/auth_key_storage.dart';
import 'package:heliolytics/services/ble/band_link_port.dart';
import 'package:heliolytics/services/ble/health_config_catalog.dart';
import 'package:heliolytics/services/ble/sync_session_port.dart';

Future<Session> finalizeFetchSession({
  required SyncSessionPort store,
  required String sessionId,
  required SessionCatalog catalog,
  required BandLinkPort client,
  required AuthKeyStorage auth,
}) async {
  final frozenCatalog = catalogWithHealthConfig(catalog, catalog.strapConfig);
  await store.writeCatalogJson(frozenCatalog);
  final base = await store.readSessionJson(sessionId);
  final batt = client.batteryPercent;

  if (batt != null) {
    await auth.saveBattery(batt);
  }

  await store.writeSessionJson(
    Session(
      sessionId: base.sessionId,
      startedAt: base.startedAt,
      endedAt: DateTime.now().toUtc(),
      deviceMac: base.deviceMac,
      fetchWindowHours: base.fetchWindowHours,
      listenDurationSec: base.listenDurationSec,
      mode: base.mode,
      entries: base.entries,
      unsolicited: base.unsolicited,
      batteryPercent: batt,
    ),
  );
  return store.readSessionJson(sessionId);
}

SessionCatalog buildCatalog(
  String sessionId,
  List<DumpEntry> entries, {
  HealthConfigSnapshot? strapConfig,
}) {
  return SessionCatalog(
    sessionId: sessionId,
    chunked: List.unmodifiable(entries),
    unsolicited: const [],
    strapConfig: strapConfig == null
        ? null
        : HealthConfigSnapshot(
            version: strapConfig.version,
            spo2AllDay: strapConfig.spo2AllDay,
            spo2LowAlert: strapConfig.spo2LowAlert,
            sleepBreathing: strapConfig.sleepBreathing,
          ),
  );
}
