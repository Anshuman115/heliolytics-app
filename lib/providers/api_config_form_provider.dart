import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:heliolytics/services/config/api_config_storage.dart';
import 'package:heliolytics/providers/health_data_refresh_coordinator.dart';

class ApiConfigForm {
  final String url;
  final String signingSecret;
  const ApiConfigForm({this.url = '', this.signingSecret = ''});
}

final apiConfigFormProvider =
    AsyncNotifierProvider<ApiConfigFormNotifier, ApiConfigForm>(
      ApiConfigFormNotifier.new,
    );

class ApiConfigFormNotifier extends AsyncNotifier<ApiConfigForm> {
  @override
  Future<ApiConfigForm> build() async {
    final storage = ref.read(apiConfigStorageProvider);
    final data = await Future.wait([
      storage.readBaseUrl(),
      storage.readSigningSecret(),
    ]);
    return ApiConfigForm(url: data[0] ?? '', signingSecret: data[1] ?? '');
  }

  Future<void> save(String url, String signingSecret) async {
    final storage = ref.read(apiConfigStorageProvider);
    final nextUrl = url.trim();
    final nextSecret = signingSecret.trim();
    final current = await Future.wait([
      storage.readBaseUrl(),
      storage.readSigningSecret(),
    ]);
    final changed =
        nextUrl != (current[0] ?? '').trim() ||
        nextSecret != (current[1] ?? '').trim();
    if (changed) {
      await ref
          .read(healthDataRefreshCoordinatorProvider)
          .replaceApiConfiguration(
            save: () =>
                storage.save(baseUrl: nextUrl, signingSecret: nextSecret),
          );
    }
    ref.invalidateSelf();
  }
}
