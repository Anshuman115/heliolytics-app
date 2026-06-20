import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:heliolytics/services/config/api_config_storage.dart';
import 'package:heliolytics/services/network/heliolytics_token.dart';
import 'package:heliolytics/models/sync_payload.dart';
import 'package:heliolytics/services/cloud_sync_repository.dart';

class CloudSyncRepositoryImpl implements CloudSyncRepository {
  final ApiConfigStorage _config;
  final Dio _dio;

  CloudSyncRepositoryImpl({
    required ApiConfigStorage config,
    required Dio dio,
  })  : _config = config,
        _dio = dio;

  @override
  Future<void> uploadPayload(SyncPayload payload) async {
    final base = await _config.readBaseUrl();
    final secret = await _config.readSigningSecret();
    if (base == null || secret == null || base.isEmpty || secret.isEmpty) {
      throw StateError('Set API URL and API key in Settings');
    }

    final form = FormData();
    form.files.add(MapEntry(
      'session',
      MultipartFile.fromString(
        jsonEncode(payload.session.toJson()),
        filename: 'session.json',
      ),
    ));
    form.files.add(MapEntry(
      'catalog',
      MultipartFile.fromString(
        jsonEncode(payload.catalog.toJson()),
        filename: 'types.json',
      ),
    ));

    for (final entry in payload.catalog.chunked) {
      if (entry.bytes <= 0) continue;
      final raw = payload.rawByCode[entry.code];
      if (raw == null || raw.isEmpty) continue;
      final name = '${entry.code}_raw.bin';
      form.files.add(MapEntry(
        name,
        MultipartFile.fromBytes(raw, filename: name),
      ));
    }

    final url = '${base.replaceAll(RegExp(r'/+$'), '')}/api/v1/ingest';
    final res = await _dio.post<dynamic>(
      url,
      data: form,
      options: Options(
        headers: {'X-Heliolytics-Token': mintHeliolyticsToken(secret)},
        sendTimeout: const Duration(minutes: 10),
        receiveTimeout: const Duration(minutes: 2),
      ),
    );
    final code = res.statusCode ?? 0;
    if (code < 200 || code >= 300) {
      throw StateError('Ingest failed ($code): ${_bodySnippet(res.data)}');
    }
  }

  static String _bodySnippet(dynamic data) {
    if (data == null) return '';
    final text = data is String ? data : data.toString();
    return text.length > 120 ? '${text.substring(0, 120)}…' : text;
  }
}
