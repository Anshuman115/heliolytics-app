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
    expect(await config.needsKeyReentry(), isFalse);
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

  test(
    'clears v1 slots once and remembers that a key must be re-entered',
    () async {
      final store = _MemoryStore({
        'api_base_url': 'https://api.example.com',
        'signing_secret': 'old-v1-secret',
        'api_key': 'old-v1-key',
      });
      final config = ApiConfigStorage(store);

      expect(await config.migrateLegacySlots(), isTrue);
      expect(store.values.containsKey('signing_secret'), isFalse);
      expect(store.values.containsKey('api_key'), isFalse);
      expect(await config.readApiKey(), isNull);
      expect(await config.needsKeyReentry(), isTrue);

      expect(await config.migrateLegacySlots(), isFalse);
    },
  );

  test(
    'legacy slots are cleared without a notice when a v2 key exists',
    () async {
      final store = _MemoryStore({
        'api_base_url': 'https://api.example.com',
        'signing_secret': 'old-v1-secret',
        'api_key_v2': _key,
      });
      final config = ApiConfigStorage(store);

      expect(await config.migrateLegacySlots(), isTrue);
      expect(await config.readApiKey(), _key);
      expect(await config.needsKeyReentry(), isFalse);
    },
  );

  test('a legacy raw secret is never reused as the API key', () async {
    final store = _MemoryStore({
      'api_base_url': 'https://api.example.com',
      'signing_secret': _secret,
    });
    final config = ApiConfigStorage(store);

    await config.migrateLegacySlots();

    expect(await config.readApiKey(), isNull);
    expect(await config.isConfigured(), isFalse);
  });

  test('save clears the re-entry notice', () async {
    final store = _MemoryStore({'api_key_needs_reentry': '1'});
    final config = ApiConfigStorage(store);

    await config.save(baseUrl: 'https://api.example.com', apiKey: _key);

    expect(await config.needsKeyReentry(), isFalse);
  });
}

class _MemoryStore implements AuthKeyStore {
  _MemoryStore([Map<String, String>? initial]) : values = {...?initial};

  final Map<String, String> values;

  @override
  Future<void> delete(String key) async => values.remove(key);

  @override
  Future<String?> read(String key) async => values[key];

  @override
  Future<void> write(String key, String value) async => values[key] = value;
}
