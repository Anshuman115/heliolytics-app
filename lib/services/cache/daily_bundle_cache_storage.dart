import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:heliolytics/constants/constants.dart';
import 'package:heliolytics/models/day_bundle.dart';
import 'package:heliolytics/models/day_metric.dart';

/// Per-day bundle cache in a Hive box opened at startup in main.dart. Each
/// entry is a JSON-encoded [DayBundle] keyed by dayKey, so the box stays a
/// plain `Box<String>`. An entry that fails to decode is a cache miss.
class DailyBundleCacheStorage {
  DailyBundleCacheStorage({Box<String>? box}) : _boxOverride = box;

  final Box<String>? _boxOverride;

  Box<String>? get _box {
    if (_boxOverride != null) return _boxOverride;
    if (!Hive.isBoxOpen(cachedDaysBoxName)) return null;
    return Hive.box<String>(cachedDaysBoxName);
  }

  Future<DayBundle?> read(String dayKey) async {
    final box = _box;
    if (box == null) return null;
    try {
      final raw = box.get(dayKey);
      if (raw == null) return null;
      return DayBundle.fromJson(
        Map<String, dynamic>.from(jsonDecode(raw) as Map),
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> write(String dayKey, DayBundle bundle) async {
    try {
      await _box?.put(dayKey, jsonEncode(bundle.toJson()));
    } catch (_) {
      // Best-effort — a disk failure must never crash the app.
    }
  }

  Future<void> clear() async {
    await _box?.clear();
  }

  Future<void> delete(String dayKey) async {
    await _box?.delete(dayKey);
  }

  /// Cached DayMetric values, skipping days with no metric or corrupt entry.
  Future<List<DayMetric>> readAllCachedDays() async {
    final box = _box;
    if (box == null) return const [];
    final out = <DayMetric>[];
    for (final entry in box.toMap().entries) {
      try {
        final map = Map<String, dynamic>.from(jsonDecode(entry.value) as Map);
        final day = DayBundle.fromJson(map).day;
        if (day != null) out.add(day);
      } catch (_) {
        // Skip this one entry, keep the rest.
      }
    }
    return out;
  }
}

final dailyBundleCacheStorageProvider = Provider<DailyBundleCacheStorage>((
  ref,
) {
  return DailyBundleCacheStorage();
});
