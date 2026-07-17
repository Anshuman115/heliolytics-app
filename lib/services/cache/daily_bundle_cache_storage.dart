import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:heliolytics/constants/constants.dart';
import 'package:heliolytics/models/day_bundle.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DailyBundleCacheStorage {
  Future<DayBundle?> read(String dayKey) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(dailyBundleCacheKey);
    if (raw == null) return null;
    try {
      final map = Map<String, dynamic>.from(jsonDecode(raw) as Map);
      final entry = map[dayKey];
      if (entry == null) return null;
      return DayBundle.fromJson(Map<String, dynamic>.from(entry as Map));
    } catch (_) {
      return null;
    }
  }

  Future<void> write(String dayKey, DayBundle bundle) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(dailyBundleCacheKey);
    final map = <String, dynamic>{};
    if (raw != null) {
      try {
        map.addAll(Map<String, dynamic>.from(jsonDecode(raw) as Map));
      } catch (_) {
        // Corrupt cache — start fresh rather than fail the write.
      }
    }
    map[dayKey] = bundle.toJson();
    await prefs.setString(dailyBundleCacheKey, jsonEncode(map));
  }
}

final dailyBundleCacheStorageProvider = Provider<DailyBundleCacheStorage>((ref) {
  return DailyBundleCacheStorage();
});
