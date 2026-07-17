import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:heliolytics/constants/constants.dart';
import 'package:heliolytics/models/day_bundle.dart';
import 'package:heliolytics/models/day_metric.dart';
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

  /// All cached days' DayMetric only (no sleep/workouts) — used to seed
  /// baseline assessments without a dedicated bulk fetch. Grows naturally
  /// as the user visits more days; empty on a fresh install.
  Future<List<DayMetric>> readAllCachedDays() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(dailyBundleCacheKey);
    if (raw == null) return const [];
    try {
      final map = Map<String, dynamic>.from(jsonDecode(raw) as Map);
      return map.values
          .map((e) => DayBundle.fromJson(Map<String, dynamic>.from(e as Map)).day)
          .toList();
    } catch (_) {
      return const [];
    }
  }
}

final dailyBundleCacheStorageProvider = Provider<DailyBundleCacheStorage>((ref) {
  return DailyBundleCacheStorage();
});
