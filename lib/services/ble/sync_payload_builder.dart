import 'package:heliolytics/services/ble/sync_session_port.dart';
import 'package:heliolytics/models/session_catalog.dart';
import 'package:heliolytics/models/sync_payload.dart';

Future<SyncPayload?> payloadFromLastSession(
  SyncSessionPort store,
  String? sessionId,
) async {
  if (sessionId == null) return null;
  final session = await store.readSessionJson(sessionId);
  return SyncPayload(
    session: session,
    catalog: SessionCatalog(
      sessionId: sessionId,
      chunked: const [],
      unsolicited: const [],
    ),
    rawByCode: const {},
  );
}
