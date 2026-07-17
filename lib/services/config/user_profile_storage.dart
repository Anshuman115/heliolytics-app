import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:heliolytics/constants/constants.dart';
import 'package:heliolytics/models/user_profile.dart';
import 'package:heliolytics/services/ble/auth/auth_key_storage.dart';
import 'package:heliolytics/services/ble/auth/auth_key_store.dart';

class UserProfileStorage {
  final AuthKeyStore _store;
  UserProfileStorage(this._store);

  Future<UserProfile?> readProfile() async {
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

  Future<void> saveProfile(UserProfile profile) =>
      _store.write(userProfileStorageKey, jsonEncode(profile.toJson()));

  Future<bool> isOnboardingComplete() async {
    final v = await _store.read(onboardingCompleteStorageKey);
    return v == '1';
  }

  Future<void> markOnboardingComplete() =>
      _store.write(onboardingCompleteStorageKey, '1');
}

final userProfileStorageProvider = Provider<UserProfileStorage>((ref) {
  return UserProfileStorage(ref.watch(authKeyStoreProvider));
});
