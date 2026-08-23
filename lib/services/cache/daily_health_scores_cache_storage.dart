import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:heliolytics/constants/constants.dart';
import 'package:heliolytics/models/daily_health_scores.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DailyHealthScoresCacheStorage {
  Future<DailyHealthScores?> read(String dayKey) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(dailyHealthScoresCacheKey);
    if (raw == null) return null;
    try {
      final map = Map<String, dynamic>.from(jsonDecode(raw) as Map);
      final entry = map[dayKey];
      if (entry == null) return null;
      return DailyHealthScores.fromJson(
        Map<String, dynamic>.from(entry as Map),
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> write(String dayKey, DailyHealthScores scores) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(dailyHealthScoresCacheKey);
    final map = <String, dynamic>{};
    if (raw != null) {
      try {
        map.addAll(Map<String, dynamic>.from(jsonDecode(raw) as Map));
      } catch (_) {
        // Corrupt cache — start fresh rather than fail the write.
      }
    }
    map[dayKey] = scores.toJson();
    await prefs.setString(dailyHealthScoresCacheKey, jsonEncode(map));
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(dailyHealthScoresCacheKey);
  }

  Future<void> delete(String dayKey) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(dailyHealthScoresCacheKey);
    if (raw == null) return;
    try {
      final map = Map<String, dynamic>.from(jsonDecode(raw) as Map);
      map.remove(dayKey);
      if (map.isEmpty) {
        await prefs.remove(dailyHealthScoresCacheKey);
      } else {
        await prefs.setString(dailyHealthScoresCacheKey, jsonEncode(map));
      }
    } catch (_) {
      await prefs.remove(dailyHealthScoresCacheKey);
    }
  }
}

final dailyHealthScoresCacheStorageProvider =
    Provider<DailyHealthScoresCacheStorage>((ref) {
      return DailyHealthScoresCacheStorage();
    });
