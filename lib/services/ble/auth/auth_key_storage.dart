import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:heliolytics/services/ble/auth/auth_key_store.dart';
import 'package:heliolytics/services/ble/auth/auth_key_validator.dart';
import 'package:heliolytics/constants/constants.dart';

final authKeyStoreProvider = Provider<AuthKeyStore>(
  (ref) => throw UnimplementedError(
      'Override authKeyStoreProvider in ProviderScope'),
);

class AuthKeyStorage {
  final AuthKeyStore _store;
  // Expose store for callers that need to write arbitrary meta keys
  // (e.g., sync_fetcher_session persisting strap battery).
  AuthKeyStore get store => _store;
  AuthKeyStorage({required AuthKeyStore store}) : _store = store;

  Future<void> save(String key) async {
    final reason = AuthKeyValidator.validate(key);
    if (reason != null) throw FormatException('Invalid auth key: $reason');
    await _store.write(authKeyStorageKey, AuthKeyValidator.normalize(key));
  }

  Future<String?> read() => _store.read(authKeyStorageKey);

  Future<Uint8List?> readBytes() async {
    final s = await read();
    return s == null ? null : AuthKeyValidator.toBytes(s);
  }

  Future<bool> hasKey() async => (await read()) != null;

  Future<void> clear() => _store.delete(authKeyStorageKey);

  /// MAC address of the strap — stored so we can connect directly without scanning.
  Future<void> saveMac(String mac) =>
      _store.write(strapMacStorageKey, mac.toUpperCase().trim());

  Future<String?> readMac() => _store.read(strapMacStorageKey);

  Future<bool> hasMac() async => (await readMac()) != null;

  /// Strap battery — persisted after each successful BLE sync so the UI
  /// can display it even when not currently connected.
  Future<void> saveBattery(int percent) =>
      _store.write(strapBatteryStorageKey, '$percent');

  Future<int?> readBattery() async {
    final s = await _store.read(strapBatteryStorageKey);
    return s == null ? null : int.tryParse(s);
  }
}
