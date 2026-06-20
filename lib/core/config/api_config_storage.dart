import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:heliolytics/core/ble/auth/auth_key_storage.dart';
import 'package:heliolytics/core/ble/auth/auth_key_store.dart';
import 'package:heliolytics/core/constants.dart';

const _baseUrlKey = 'api_base_url';
const _signingSecretKey = 'signing_secret';
const _legacyApiKeyKey = 'api_key';

class ApiConfigStorage {
  final AuthKeyStore _store;
  ApiConfigStorage(this._store);

  Future<String?> readBaseUrl() => _store.read(_baseUrlKey);

  Future<String?> readSigningSecret() async {
    final secret = await _store.read(_signingSecretKey);
    if (secret != null && secret.isNotEmpty) return secret;
    final legacy = await _store.read(_legacyApiKeyKey);
    if (legacy != null && legacy.isNotEmpty) {
      await _store.write(_signingSecretKey, legacy);
      await _store.delete(_legacyApiKeyKey);
      return legacy;
    }
    return null;
  }

  Future<bool> isConfigured() async {
    final u = await readBaseUrl();
    final s = await readSigningSecret();
    return u != null && u.isNotEmpty && s != null && s.isNotEmpty;
  }

  Future<void> save({required String baseUrl, required String signingSecret}) async {
    await _store.write(_baseUrlKey, baseUrl.trim());
    await _store.write(_signingSecretKey, signingSecret.trim());
    await _store.delete(_legacyApiKeyKey);
  }

  Future<void> clear() async {
    await _store.delete(_baseUrlKey);
    await _store.delete(_signingSecretKey);
    await _store.delete(_legacyApiKeyKey);
  }

  /// Seeds defaults (env-injected at build time) when missing (e.g. after reinstall).
  Future<void> ensureDevDefaults() async {
    final url = await readBaseUrl();
    final secret = await readSigningSecret();
    final nextUrl = (url == null || url.isEmpty) ? defaultApiUrl : url;
    final nextSecret =
        (secret == null || secret.isEmpty) ? defaultApiSigningSecret : secret;
    if (nextUrl != url || nextSecret != secret) {
      await save(baseUrl: nextUrl, signingSecret: nextSecret);
    }
  }
}

final apiConfigStorageProvider = Provider<ApiConfigStorage>((ref) {
  return ApiConfigStorage(ref.watch(authKeyStoreProvider));
});
