import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:heliolytics/services/ble/auth/auth_key_storage.dart';

final authKeyStatusProvider = FutureProvider<bool>((ref) {
  final storage = AuthKeyStorage(store: ref.watch(authKeyStoreProvider));
  return storage.hasKey();
});
