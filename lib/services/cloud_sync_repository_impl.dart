import 'package:dio/dio.dart';

import 'package:heliolytics/models/ingest_result.dart';
import 'package:heliolytics/models/sync_payload.dart';
import 'package:heliolytics/services/cloud_sync_repository.dart';
import 'package:heliolytics/services/config/api_config_storage.dart';
import 'package:heliolytics/services/network/api_endpoint_policy.dart';
import 'package:heliolytics/services/network/ingest_request_encoder.dart';
import 'package:heliolytics/services/network/metrics_api_transport.dart';
import 'package:heliolytics/services/network/prepared_upload.dart';
import 'package:heliolytics/services/network/request_signer.dart';

class CloudSyncRepositoryImpl implements CloudSyncRepository {
  CloudSyncRepositoryImpl({
    required ApiConfigStorage config,
    required Dio dio,
    ApiEndpointPolicy? policy,
    RequestSigner? signer,
    IngestRequestEncoder? encoder,
  }) : _transport = MetricsApiTransport(
         config,
         dio: dio,
         policy: policy,
         signer: signer,
       ),
       _encoder = encoder ?? IngestRequestEncoder();

  static const String ingestPath = '/api/v1/ingest';

  final MetricsApiTransport _transport;
  final IngestRequestEncoder _encoder;

  PreparedUpload? _prepared;

  @override
  Future<IngestResult> uploadPayload(SyncPayload payload) async {
    final prepared = await _preparedFor(payload);
    final response = await _transport.send(
      prepared.request,
      await _transport.requireApiKey(),
    );
    if (response.statusCode == 200) {
      final data = _transport.decodeJsonObject(ingestPath, response);
      return IngestResult.fromJson(data, expectedSessionId: prepared.sessionId);
    }
    throw _transport.errorFor(ingestPath, response);
  }

  /// Reuses the prepared body only while the payload content is unchanged.
  Future<PreparedUpload> _preparedFor(SyncPayload payload) async {
    final fingerprint = payloadFingerprint(payload);
    final cached = _prepared;
    if (cached != null && cached.fingerprint == fingerprint) return cached;
    final encoded = await _encoder.encode(payload);
    final prepared = PreparedUpload(
      sessionId: encoded.sessionId,
      request: await _transport.buildMultipart(ingestPath, encoded),
      fingerprint: fingerprint,
    );
    _prepared = prepared;
    return prepared;
  }
}
