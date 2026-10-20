import 'package:flutter_test/flutter_test.dart';

import 'package:heliolytics/services/ble/auth/auth_key_store.dart';
import 'package:heliolytics/services/config/api_config_storage.dart';
import 'package:heliolytics/services/network/request_signer.dart';

const _secret =
    '000102030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d1e1f';
const _key = 'phone.$_secret';

void main() {
  test('stores a phone key and reports the API as configured', () async {
    final store = _MemoryStore();
    final config = ApiConfigStorage(store);

    await config.save(baseUrl: 'https://api.example.com', apiKey: _key);

    expect(await config.readApiKey(), _key);
    expect(await config.readBaseUrl(), 'https://api.example.com');
    expect(await config.isConfigured(), isTrue);
    expect(store.values['api_key'], _key);
  });

  test('rejects web, unknown and malformed keys without writing', () async {
    final store = _MemoryStore();
    final config = ApiConfigStorage(store);

    for (final bad in [
      'web.$_secret',
      'phone.${_secret.toUpperCase()}',
      'phone.abc',
      'secret-only',
    ]) {
      await expectLater(
        config.save(baseUrl: 'https://api.example.com', apiKey: bad),
        throwsA(isA<ApiKeyFormatException>()),
        reason: bad,
      );
    }
    expect(store.values, isEmpty);
    expect(await config.isConfigured(), isFalse);
  });

  test('clear removes the origin and the key', () async {
    final store = _MemoryStore();
    final config = ApiConfigStorage(store);
    await config.save(baseUrl: 'https://api.example.com', apiKey: _key);

    await config.clear();

    expect(store.values, isEmpty);
    expect(await config.isConfigured(), isFalse);
  });
}

class _MemoryStore implements AuthKeyStore {
  final Map<String, String> values = {};

  @override
  Future<void> delete(String key) async => values.remove(key);

  @override
  Future<String?> read(String key) async => values[key];

  @override
  Future<void> write(String key, String value) async => values[key] = value;
}
