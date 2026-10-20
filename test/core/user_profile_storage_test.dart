import 'package:flutter_test/flutter_test.dart';

import 'package:heliolytics/constants/constants.dart';
import 'package:heliolytics/models/user_profile.dart';
import 'package:heliolytics/services/ble/auth/auth_key_store.dart';
import 'package:heliolytics/services/config/user_profile_storage.dart';

void main() {
  test('a profile round-trips through secure storage', () async {
    final store = _MemoryStore({});
    final storage = UserProfileStorage(store);

    await storage.saveProfile(const UserProfile(name: 'New', heightCm: 180));
    await storage.markOnboardingComplete();

    final loaded = await storage.readProfile();
    expect(loaded?.name, 'New');
    expect(loaded?.heightCm, 180);
    expect(await storage.isOnboardingComplete(), isTrue);
  });

  test('an unparseable stored profile reads as no profile', () async {
    final store = _MemoryStore({userProfileStorageKey: '{"name":'});
    final storage = UserProfileStorage(store);

    expect(await storage.readProfile(), isNull);
    expect(await storage.isOnboardingComplete(), isFalse);
  });

  test('an absent profile reads as null', () async {
    final storage = UserProfileStorage(_MemoryStore({}));

    expect(await storage.readProfile(), isNull);
  });
}

class _MemoryStore implements AuthKeyStore {
  _MemoryStore(this.values);

  final Map<String, String> values;

  @override
  Future<void> delete(String key) async => values.remove(key);

  @override
  Future<String?> read(String key) async => values[key];

  @override
  Future<void> write(String key, String value) async => values[key] = value;
}
