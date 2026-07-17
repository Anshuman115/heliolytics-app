import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:heliolytics/models/user_profile.dart';
import 'package:heliolytics/services/config/api_config_storage.dart';
import 'package:heliolytics/services/network/api_dio.dart';
import 'package:heliolytics/services/network/heliolytics_token.dart';
import 'package:heliolytics/utils/app_logger.dart';
import 'package:heliolytics/utils/error_messages.dart';

class ProfileApiClient {
  final ApiConfigStorage _config;
  final Dio _dio;
  ProfileApiClient(this._config, {required Dio dio}) : _dio = dio;

  /// Fire-and-forget: local profile save always succeeds regardless of
  /// this call's outcome. Failure is logged, never surfaced to the user.
  Future<void> submitProfile(UserProfile profile) async {
    try {
      final base = await _config.readBaseUrl();
      final secret = await _config.readSigningSecret();
      if (base == null || base.isEmpty || secret == null || secret.isEmpty) {
        return;
      }
      await _dio.post(
        '${base.replaceAll(RegExp(r'/+$'), '')}/api/v1/profile',
        data: profile.toJson(),
        options: Options(headers: {'X-Heliolytics-Token': mintHeliolyticsToken(secret)}),
      );
    } catch (e) {
      AppLogger.instance.log('profile submit: ${friendlyError(e)}', tag: 'profile');
    }
  }
}

final profileApiClientProvider = Provider<ProfileApiClient>((ref) {
  return ProfileApiClient(
    ref.watch(apiConfigStorageProvider),
    dio: ref.watch(apiDioProvider),
  );
});
