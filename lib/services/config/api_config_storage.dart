import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:heliolytics/constants/constants.dart';
import 'package:heliolytics/services/ble/auth/auth_key_storage.dart';
import 'package:heliolytics/services/ble/auth/auth_key_store.dart';
import 'package:heliolytics/services/network/request_signer.dart';

/// Cloud API origin and phone API key, both kept in secure storage.
class ApiConfigStorage {
  ApiConfigStorage(this._store);

  final AuthKeyStore _store;

  Future<String?> readBaseUrl() async {
    final value = await _store.read(apiBaseUrlStorageKey);
    return (value == null || value.isEmpty) ? null : value;
  }

  Future<String?> readApiKey() async {
    final value = await _store.read(apiKeyStorageKey);
    return (value == null || value.isEmpty) ? null : value;
  }

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
  }

  Future<void> clear() async {
    await _store.delete(apiBaseUrlStorageKey);
    await _store.delete(apiKeyStorageKey);
  }

  /// Seeds the optional build-time origin when nothing is stored yet.
  Future<void> ensureDevDefaults() async {
    final url = await readBaseUrl();
    if (url == null && defaultApiUrl.isNotEmpty) {
      await _store.write(apiBaseUrlStorageKey, defaultApiUrl);
    }
  }
}

final apiConfigStorageProvider = Provider<ApiConfigStorage>((ref) {
  return ApiConfigStorage(ref.watch(authKeyStoreProvider));
});
