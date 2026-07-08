import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:heliolytics/constants/constants.dart';
import 'package:heliolytics/services/ble/auth/auth_key_store.dart';
import 'package:heliolytics/services/ble/auth/auth_key_storage.dart';

class BandAlertsAppPatternsStorage {
  final AuthKeyStore _store;
  BandAlertsAppPatternsStorage(this._store);

  Future<Map<String, List<int>>> load() async {
    final raw = await _store.read(bandAlertsAppPatternsKey);
    if (raw == null || raw.isEmpty) return {};
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return {};
      final out = <String, List<int>>{};
      for (final entry in decoded.entries) {
        final key = entry.key;
        final val = entry.value;
        if (key is! String || val is! List) continue;
        final ints = <int>[];
        for (final v in val) {
          if (v is int) ints.add(v);
        }
        if (ints.isEmpty) continue;
        out[key] = ints;
      }
      return out;
    } catch (_) {
      return {};
    }
  }

  Future<void> save(Map<String, List<int>> patterns) async {
    final keys = patterns.keys.toList()..sort();
    final out = <String, List<int>>{};
    for (final k in keys) {
      final v = patterns[k];
      if (v == null || v.isEmpty) continue;
      out[k] = v;
    }
    await _store.write(bandAlertsAppPatternsKey, jsonEncode(out));
  }

  Future<void> clear() => _store.delete(bandAlertsAppPatternsKey);
}

final bandAlertsAppPatternsStorageProvider =
    Provider<BandAlertsAppPatternsStorage>((ref) {
  return BandAlertsAppPatternsStorage(ref.watch(authKeyStoreProvider));
});

