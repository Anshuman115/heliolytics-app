import 'package:heliolytics/services/ble/band_link_port.dart';
import 'package:heliolytics/services/ble/sync_session_port.dart';
import 'package:heliolytics/models/dump_entry.dart';
import 'package:heliolytics/models/session.dart';
import 'package:heliolytics/models/session_catalog.dart';

Future<Session> finalizeFetchSession({
  required SyncSessionPort store,
  required String sessionId,
  required SessionCatalog catalog,
  required BandLinkPort client,
}) async {
  await store.writeCatalogJson(catalog);
  final base = await store.readSessionJson(sessionId);
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
    batteryPercent: client.batteryPercent,
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
