import 'dart:typed_data';

import 'package:heliolytics/features/ble_discovery/domain/models/session.dart';
import 'package:heliolytics/features/ble_discovery/domain/models/session_catalog.dart';

/// In-memory BLE session — uploaded to Go API, no local .bin files.
class SyncPayload {
  final Session session;
  final SessionCatalog catalog;
  final Map<String, Uint8List> rawByCode;

  const SyncPayload({
    required this.session,
    required this.catalog,
    required this.rawByCode,
  });
}
