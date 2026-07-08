import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:heliolytics/constants/constants.dart';
import 'package:heliolytics/models/band_alerts_config.dart';
import 'package:heliolytics/services/ble/auth/auth_key_storage.dart';
import 'package:heliolytics/services/ble/auth/auth_key_store.dart';

class BandAlertsPrefsStorage {
  final AuthKeyStore _store;
  BandAlertsPrefsStorage(this._store);

  Future<BandAlertsConfig> load() async {
    final enabled = await _readBool(bandAlertsEnabledKey);
    final forwardCalls = await _readBool(bandAlertsForwardCallsKey, fallback: true);
    final callsOnly = await _readBool(bandAlertsCallsOnlyKey);
    final raw = await _store.read(bandAlertsAllowlistKey);
    final packages = _decodeAllowlist(raw);
    return BandAlertsConfig(
      enabled: enabled,
      forwardCalls: forwardCalls,
      callsOnly: callsOnly,
      allowedPackages: packages,
    );
  }

  Future<void> save(BandAlertsConfig config) async {
    await _store.write(
      bandAlertsEnabledKey,
      config.enabled ? '1' : '0',
    );
    await _store.write(
      bandAlertsForwardCallsKey,
      config.forwardCalls ? '1' : '0',
    );
    await _store.write(
      bandAlertsCallsOnlyKey,
      config.callsOnly ? '1' : '0',
    );
    await _store.write(
      bandAlertsAllowlistKey,
      jsonEncode(config.allowedPackages.toList()..sort()),
    );
  }

  Future<bool> _readBool(String key, {bool fallback = false}) async {
    final v = await _store.read(key);
    if (v == null) return fallback;
    return v == '1' || v.toLowerCase() == 'true';
  }

  Set<String> _decodeAllowlist(String? raw) {
    if (raw == null || raw.isEmpty) return {};
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list.map((e) => e as String).toSet();
    } catch (_) {
      return {};
    }
  }
}

final bandAlertsPrefsStorageProvider = Provider<BandAlertsPrefsStorage>((ref) {
  return BandAlertsPrefsStorage(ref.watch(authKeyStoreProvider));
});
