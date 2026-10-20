import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';

import 'package:heliolytics/models/sync_payload.dart';
import 'package:heliolytics/services/ble/sync_type_catalog.dart';

/// Raised when a session cannot be encoded as a C2 upload.
class IngestEncodingException implements Exception {
  const IngestEncodingException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// A finalized multipart body with its frozen Content-Type.
class EncodedIngestRequest {
  const EncodedIngestRequest({
    required this.sessionId,
    required this.body,
    required this.contentType,
  });

  final String sessionId;
  final Uint8List body;
  final String contentType;
}

/// Builds the C2 multipart body exactly once, so signing and sending see the
/// same bytes and boundary.
class IngestRequestEncoder {
  IngestRequestEncoder({this.maxBytes = 16 * 1024 * 1024, this.maxParts = 40});

  static final RegExp _sessionIdPattern = RegExp(r'^[\x20-\x7E]{1,64}$');
  static final RegExp _macPattern = RegExp(
    r'^([0-9A-Fa-f]{2}:){5}[0-9A-Fa-f]{2}$',
  );

  final int maxBytes;
  final int maxParts;

  Future<EncodedIngestRequest> encode(SyncPayload payload) async {
    final session = payload.session;
    final sessionId = session.sessionId;
    if (!_sessionIdPattern.hasMatch(sessionId)) {
      throw const IngestEncodingException('The session id is not uploadable.');
    }
    final endedAt = session.endedAt;
    if (endedAt == null) {
      throw const IngestEncodingException(
        'The session has no end time yet. Finish the sync first.',
      );
    }
    final mac = session.deviceMac?.toUpperCase() ?? '';
    if (!_macPattern.hasMatch(mac)) {
      throw const IngestEncodingException(
        'The strap MAC address is missing or invalid.',
      );
    }
    if (endedAt.isBefore(session.startedAt)) {
      throw const IngestEncodingException('The session ends before it starts.');
    }

    final files = <MapEntry<String, Uint8List>>[];
    for (final code in productionFetchTypeCodes) {
      final raw = payload.rawByCode[code];
      if (raw == null || raw.isEmpty) continue;
      files.add(MapEntry(code, raw));
    }
    if (files.isEmpty) {
      throw const IngestEncodingException(
        'This session has no data to upload.',
      );
    }
    if (files.length + 2 > maxParts) {
      throw const IngestEncodingException(
        'Too many upload parts for one session.',
      );
    }

    final form = FormData();
    form.files.add(
      MapEntry(
        'session',
        MultipartFile.fromString(
          jsonEncode(_sessionJson(payload, mac, endedAt)),
          filename: 'session.json',
        ),
      ),
    );
    form.files.add(
      MapEntry(
        'catalog',
        MultipartFile.fromString(
          jsonEncode(payload.catalog.toJson()),
          filename: 'catalog.json',
        ),
      ),
    );
    for (final file in files) {
      form.files.add(
        MapEntry(
          '${file.key}_raw.bin',
          MultipartFile.fromBytes(file.value, filename: '${file.key}_raw.bin'),
        ),
      );
    }

    final contentType = 'multipart/form-data; boundary=${form.boundary}';
    final body = await _collect(form);
    return EncodedIngestRequest(
      sessionId: sessionId,
      body: body,
      contentType: contentType,
    );
  }

  Map<String, dynamic> _sessionJson(
    SyncPayload payload,
    String mac,
    DateTime endedAt,
  ) => {
    'sessionId': payload.session.sessionId,
    'startedAt': payload.session.startedAt.toUtc().toIso8601String(),
    'endedAt': endedAt.toUtc().toIso8601String(),
    'deviceMac': mac,
    'batteryPercent': payload.session.batteryPercent,
  };

  Future<Uint8List> _collect(FormData form) async {
    final builder = BytesBuilder(copy: false);
    await for (final chunk in form.finalize()) {
      builder.add(chunk);
      if (builder.length > maxBytes) {
        throw const IngestEncodingException(
          'The upload is larger than the 16 MiB limit.',
        );
      }
    }
    return builder.takeBytes();
  }
}
