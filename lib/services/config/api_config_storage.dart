import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:heliolytics/constants/constants.dart';
import 'package:heliolytics/services/ble/auth/auth_key_storage.dart';
import 'package:heliolytics/services/ble/auth/auth_key_store.dart';
import 'package:heliolytics/services/network/request_signer.dart';

const _legacySigningSecretKey = 'signing_secret';
const _legacyApiKeyKey = 'api_key';

/// Cloud API origin and v2 phone API key, both kept in secure storage.
class ApiConfigStorage {
  ApiConfigStorage(this._store);

  final AuthKeyStore _store;

  Future<String?> readBaseUrl() async {
    final value = await _store.read(apiBaseUrlStorageKey);
    return (value == null || value.isEmpty) ? null : value;
  }

  /// Returns the stored v2 key. Legacy v1 secrets are never returned.
  Future<String?> readApiKey() async {
    final value = await _store.read(apiKeyStorageKey);
    return (value == null || value.isEmpty) ? null : value;
  }

  /// True after the v1 key slots were cleared without a v2 replacement.
  Future<bool> needsKeyReentry() async =>
      (await _store.read(apiKeyReentryStorageKey)) == '1';

  /// Why the stored key cannot be used, or null when it is valid.
  Future<String?> apiKeyError() async {
    final key = await readApiKey();
    if (key == null) return 'Enter your phone API key in Settings.';
    return ApiKey.validatePhone(key);
  }

  Future<bool> isConfigured() async {
    final base = await readBaseUrl();
    if (base == null) return false;
    final key = await readApiKey();
    return key != null && ApiKey.validatePhone(key) == null;
  }

  /// Stores validated settings. Throws [ApiKeyFormatException] before writing.
  Future<void> save({required String baseUrl, required String apiKey}) async {
    final nextKey = apiKey.trim();
    final error = ApiKey.validatePhone(nextKey);
    if (error != null) throw ApiKeyFormatException(error);
    await _store.write(apiBaseUrlStorageKey, baseUrl.trim());
    await _store.write(apiKeyStorageKey, nextKey);
    await _store.delete(apiKeyReentryStorageKey);
  }

  Future<void> clear() async {
    await _store.delete(apiBaseUrlStorageKey);
    await _store.delete(apiKeyStorageKey);
    await _store.delete(apiKeyReentryStorageKey);
  }

  /// Clears the v1 secret slots once, remembering that a key must be re-entered.
  Future<bool> migrateLegacySlots() async {
    final legacySecret = await _store.read(_legacySigningSecretKey);
    final legacyKey = await _store.read(_legacyApiKeyKey);
    if (legacySecret == null && legacyKey == null) return false;
    await _store.delete(_legacySigningSecretKey);
    await _store.delete(_legacyApiKeyKey);
    if (await readApiKey() == null) {
      await _store.write(apiKeyReentryStorageKey, '1');
    }
    return true;
  }

  /// Runs the cutover and seeds the optional build-time origin when missing.
  Future<void> ensureDevDefaults() async {
    await migrateLegacySlots();
    final url = await readBaseUrl();
    if (url == null && defaultApiUrl.isNotEmpty) {
      await _store.write(apiBaseUrlStorageKey, defaultApiUrl);
    }
  }
}

final apiConfigStorageProvider = Provider<ApiConfigStorage>((ref) {
  return ApiConfigStorage(ref.watch(authKeyStoreProvider));
});
