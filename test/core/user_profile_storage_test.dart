import 'package:flutter_test/flutter_test.dart';

import 'package:heliolytics/constants/constants.dart';
import 'package:heliolytics/models/user_profile.dart';
import 'package:heliolytics/services/ble/auth/auth_key_store.dart';
import 'package:heliolytics/services/config/user_profile_storage.dart';

void main() {
  test('the cutover clears the profile and asks onboarding again', () async {
    final store = _MemoryStore({
      userProfileStorageKey: '{"name":"Old"}',
      onboardingCompleteStorageKey: '1',
      userProfileSchemaKey: '1',
    });
    final storage = UserProfileStorage(store);

    expect(await storage.readProfile(), isNull);
    expect(await storage.isOnboardingComplete(), isFalse);
    expect(store.values[userProfileSchemaKey], '$userProfileSchemaVersion');
  });

  test('a second run keeps the profile saved after the cutover', () async {
    final store = _MemoryStore({
      userProfileStorageKey: '{"name":"Old"}',
      onboardingCompleteStorageKey: '1',
      userProfileSchemaKey: '1',
    });
    final storage = UserProfileStorage(store);

    await storage.saveProfile(const UserProfile(name: 'New'));
    await storage.markOnboardingComplete();
    await storage.ensureSchema();

    expect((await storage.readProfile())?.name, 'New');
    expect(await storage.isOnboardingComplete(), isTrue);
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
