import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:heliolytics/models/user_profile.dart';
import 'package:heliolytics/services/config/api_config_storage.dart';
import 'package:heliolytics/services/network/api_dio.dart';
import 'package:heliolytics/services/network/api_endpoint_policy.dart';
import 'package:heliolytics/services/network/metrics_api_transport.dart';
import 'package:heliolytics/services/network/request_signer.dart';

/// Full-replacement profile write. Throws on any non-204 outcome.
class ProfileApiClient {
  ProfileApiClient(
    ApiConfigStorage config, {
    required Dio dio,
    ApiEndpointPolicy? policy,
    RequestSigner? signer,
  }) : _transport = MetricsApiTransport(
         config,
         dio: dio,
         policy: policy,
         signer: signer,
       );

  static const String profilePath = '/api/profile';

  final MetricsApiTransport _transport;

  Future<void> submitProfile(UserProfile profile) async {
    final request = await _transport.buildJsonPut(
      profilePath,
      profile.toWireJson(),
    );
    final response = await _transport.send(
      request,
      await _transport.requireApiKey(),
    );
    if (response.statusCode == 204) return;
    throw _transport.errorFor(profilePath, response);
  }
}

final profileApiClientProvider = Provider<ProfileApiClient>((ref) {
  return ProfileApiClient(
    ref.watch(apiConfigStorageProvider),
    dio: ref.watch(apiDioProvider),
  );
});
