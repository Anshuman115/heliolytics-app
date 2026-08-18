import 'package:flutter_test/flutter_test.dart';
import 'package:heliolytics/services/ble/auth/auth_key_storage.dart';
import 'package:heliolytics/services/ble/auth/auth_key_store.dart';

void main() {
  test(
    'setup remains pending until the selected-range sync completes',
    () async {
      final storage = AuthKeyStorage(store: _MemoryKeyStore());

      expect(await storage.isSetupPending(), isFalse);

      await storage.markSetupPending();
      expect(await storage.isSetupPending(), isTrue);

      await storage.completeSetup();
      expect(await storage.isSetupPending(), isFalse);
    },
  );
}

class _MemoryKeyStore implements AuthKeyStore {
  final _values = <String, String>{};

  @override
  Future<void> delete(String key) async => _values.remove(key);

  @override
  Future<String?> read(String key) async => _values[key];

  @override
  Future<void> write(String key, String value) async => _values[key] = value;
}
