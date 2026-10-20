import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:heliolytics/constants/constants.dart';
import 'package:heliolytics/models/user_profile.dart';
import 'package:heliolytics/services/ble/auth/auth_key_storage.dart';
import 'package:heliolytics/services/ble/auth/auth_key_store.dart';

/// Local profile storage with a one-time reset at the optional-field cutover.
class UserProfileStorage {
  UserProfileStorage(this._store);

  final AuthKeyStore _store;

  Future<UserProfile?> readProfile() async {
    await ensureSchema();
    final raw = await _store.read(userProfileStorageKey);
    if (raw == null || raw.isEmpty) return null;
    try {
      return UserProfile.fromJson(
        Map<String, dynamic>.from(jsonDecode(raw) as Map),
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> saveProfile(UserProfile profile) async {
    await ensureSchema();
    await _store.write(userProfileStorageKey, jsonEncode(profile.toJson()));
  }

  Future<bool> isOnboardingComplete() async {
    await ensureSchema();
    final v = await _store.read(onboardingCompleteStorageKey);
    return v == '1';
  }

  Future<void> markOnboardingComplete() =>
      _store.write(onboardingCompleteStorageKey, '1');

  /// Clears a pre-cutover profile once so the user is asked again.
  Future<void> ensureSchema() async {
    final current = await _store.read(userProfileSchemaKey);
    if (current == '$userProfileSchemaVersion') return;
    await _store.delete(userProfileStorageKey);
    await _store.delete(onboardingCompleteStorageKey);
    await _store.write(userProfileSchemaKey, '$userProfileSchemaVersion');
  }
}

final userProfileStorageProvider = Provider<UserProfileStorage>((ref) {
  return UserProfileStorage(ref.watch(authKeyStoreProvider));
});
