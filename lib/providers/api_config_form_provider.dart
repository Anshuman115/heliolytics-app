import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:heliolytics/services/config/api_config_storage.dart';
import 'package:heliolytics/providers/cloud_sync_provider.dart';

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
    await ref.read(apiConfigStorageProvider).save(
          baseUrl: url.trim(),
          signingSecret: signingSecret.trim(),
        );
    ref.invalidate(apiConfiguredProvider);
    ref.invalidateSelf();
  }
}
