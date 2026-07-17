import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:heliolytics/services/ble/auth/auth_key_store.dart';

class SecureKeyStore implements AuthKeyStore {
  final fss = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  @override
  Future<String?> read(String key) => fss.read(key: key);

  @override
  Future<void> write(String key, String value) => fss.write(key: key, value: value);

  @override
  Future<void> delete(String key) => fss.delete(key: key);
}
