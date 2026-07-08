import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:heliolytics/constants/constants.dart';
import 'package:heliolytics/services/ble/auth/auth_key_storage.dart';
import 'package:heliolytics/services/ble/auth/auth_key_store.dart';

class BandAlertsCallPatternStorage {
  final AuthKeyStore _store;
  BandAlertsCallPatternStorage(this._store);

  Future<List<int>> load() async {
    final raw = await _store.read(bandAlertsCallPatternKey);
    if (raw == null || raw.isEmpty) return bandAlertsDefaultCallPatternMs;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return bandAlertsDefaultCallPatternMs;
      final ints = <int>[];
      for (final v in decoded) {
        if (v is int) ints.add(v);
      }
      if (ints.isEmpty || ints.length.isOdd) {
        return bandAlertsDefaultCallPatternMs;
      }
      return ints;
    } catch (_) {
      return bandAlertsDefaultCallPatternMs;
    }
  }

  Future<void> save(List<int> onOffMs) async {
    await _store.write(bandAlertsCallPatternKey, jsonEncode(onOffMs));
  }
}

final bandAlertsCallPatternStorageProvider =
    Provider<BandAlertsCallPatternStorage>((ref) {
  return BandAlertsCallPatternStorage(ref.watch(authKeyStoreProvider));
});
