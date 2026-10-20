import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:heliolytics/providers/health_data_refresh_coordinator.dart';
import 'package:heliolytics/services/config/api_config_storage.dart';
import 'package:heliolytics/services/network/api_endpoint_policy.dart';
import 'package:heliolytics/services/network/request_signer.dart';

class ApiConfigForm {
  const ApiConfigForm({this.url = '', this.apiKey = '', this.keyError});

  final String url;
  final String apiKey;

  /// Why the stored key is unusable, or null when it is valid or absent.
  final String? keyError;
}

final apiConfigFormProvider =
    AsyncNotifierProvider<ApiConfigFormNotifier, ApiConfigForm>(
      ApiConfigFormNotifier.new,
    );

class ApiConfigFormNotifier extends AsyncNotifier<ApiConfigForm> {
  @override
  Future<ApiConfigForm> build() async {
    final storage = ref.read(apiConfigStorageProvider);
    final url = await storage.readBaseUrl();
    final key = await storage.readApiKey();
    final keyError = key == null ? null : ApiKey.validatePhone(key);
    return ApiConfigForm(url: url ?? '', apiKey: key ?? '', keyError: keyError);
  }

  /// Validates and stores both settings, then clears cached API data.
  ///
  /// Throws [ApiEndpointException] or [ApiKeyFormatException] on bad input.
  Future<void> save(String url, String apiKey) async {
    final storage = ref.read(apiConfigStorageProvider);
    final nextUrl = url.trim();
    final nextKey = apiKey.trim();
    ApiEndpointPolicy.current.parseOrigin(nextUrl);
    final keyError = ApiKey.validatePhone(nextKey);
    if (keyError != null) throw ApiKeyFormatException(keyError);

    final currentUrl = (await storage.readBaseUrl()) ?? '';
    final currentKey = (await storage.readApiKey()) ?? '';
    final changed =
        nextUrl != currentUrl.trim() || nextKey != currentKey.trim();
    if (changed) {
      await ref
          .read(healthDataRefreshCoordinatorProvider)
          .replaceApiConfiguration(
            save: () => storage.save(baseUrl: nextUrl, apiKey: nextKey),
          );
    }
    ref.invalidateSelf();
  }
}
