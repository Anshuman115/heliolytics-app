import 'package:heliolytics/services/ble/band_link_port.dart';
import 'package:heliolytics/services/ble/sync_session_port.dart';
import 'package:heliolytics/services/ble/auth/auth_key_storage.dart';
import 'package:heliolytics/models/dump_entry.dart';
import 'package:heliolytics/models/session.dart';
import 'package:heliolytics/models/session_catalog.dart';

Future<Session> finalizeFetchSession({
  required SyncSessionPort store,
  required String sessionId,
  required SessionCatalog catalog,
  required BandLinkPort client,
  required AuthKeyStorage auth,
}) async {
  await store.writeCatalogJson(catalog);
  final base = await store.readSessionJson(sessionId);
  final batt = client.batteryPercent;

  // Persist battery to secure storage so it survives app restarts
  // and is visible in the UI even before the next BLE sync.
  if (batt != null) {
    await auth.saveBattery(batt);
  }

  await store.writeSessionJson(Session(
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
  ));
  return store.readSessionJson(sessionId);
}

SessionCatalog buildCatalog(String sessionId, List<DumpEntry> entries) {
  return SessionCatalog(
    sessionId: sessionId,
    chunked: entries,
    unsolicited: const [],
  );
}
