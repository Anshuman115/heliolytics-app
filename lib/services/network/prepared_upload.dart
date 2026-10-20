import 'dart:convert';

import 'package:crypto/crypto.dart';

import 'package:heliolytics/models/sync_payload.dart';
import 'package:heliolytics/services/ble/sync_type_catalog.dart';
import 'package:heliolytics/services/network/signed_request.dart';

/// Immutable upload kept for the current payload's retry.
class PreparedUpload {
  const PreparedUpload({
    required this.sessionId,
    required this.request,
    required this.fingerprint,
  });

  final String sessionId;
  final SignedRequest request;
  final String fingerprint;
}

/// Content digest of a payload, so mutated content is never sent as stale bytes.
String payloadFingerprint(SyncPayload payload) {
  final sink = _DigestSink();
  final input = sha256.startChunkedConversion(sink);
  void addText(Object? value) =>
      input.add(utf8.encode('${value?.toString()}\u0000'));
  final session = payload.session;
  addText(session.sessionId);
  addText(session.startedAt.toUtc().toIso8601String());
  addText(session.endedAt?.toUtc().toIso8601String());
  addText(session.deviceMac?.toUpperCase());
  addText(session.batteryPercent);
  addText(jsonEncode(payload.catalog.toJson()));
  for (final code in productionFetchTypeCodes) {
    final raw = payload.rawByCode[code];
    if (raw == null || raw.isEmpty) continue;
    addText(code);
    input.add(raw);
  }
  input.close();
  return sink.digest.toString();
}

class _DigestSink implements Sink<Digest> {
  late Digest digest;

  @override
  void add(Digest data) => digest = data;

  @override
  void close() {}
}
