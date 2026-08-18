import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:heliolytics/constants/constants.dart';
import 'package:heliolytics/models/day_bundle.dart';
import 'package:heliolytics/models/day_metric.dart';

/// Per-day bundle cache backed by a Hive box (opened once at app startup in
/// main.dart) — real per-key read/write, unlike the old shared_preferences
/// version which had to decode/re-encode one ever-growing JSON blob on
/// every single access. Each entry is a JSON-encoded [DayBundle], keyed by
/// dayKey, so the box stays a plain `Box&lt;String&gt;` with no TypeAdapter needed.
class DailyBundleCacheStorage {
  DailyBundleCacheStorage({Box<String>? box}) : _boxOverride = box;

  final Box<String>? _boxOverride;

  Box<String> get _box => _boxOverride ?? Hive.box<String>(cachedDaysBoxName);

  bool get _hasCurrentSchema =>
      _box.get(dailyBundleCacheSchemaKey) ==
      dailyBundleCacheSchemaVersion.toString();

  /// Removes entries produced before cache completeness was enforced.
  /// Returns true only when a migration was required.
  Future<bool> migrateSchemaIfNeeded() async {
    if (_hasCurrentSchema) return false;
    await _box.clear();
    await _markSchemaCurrent();
    return true;
  }

  Future<DayBundle?> read(String dayKey) async {
    if (!_hasCurrentSchema) return null;
    try {
      final raw = _box.get(dayKey);
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
      await migrateSchemaIfNeeded();
      await _box.put(dayKey, jsonEncode(bundle.toJson()));
    } catch (_) {
      // Best-effort — a disk failure must never crash the app.
    }
  }

  Future<void> clear() async {
    await _box.clear();
    await _markSchemaCurrent();
  }

  /// All cached days' DayMetric only (no sleep/workouts) — used to seed
  /// baseline assessments without a dedicated bulk fetch. Grows naturally
  /// as the user visits more days; empty on a fresh install. Skips any
  /// individually corrupt entry rather than discarding the whole cache.
  Future<List<DayMetric>> readAllCachedDays() async {
    if (!_hasCurrentSchema) return const [];
    final out = <DayMetric>[];
    for (final entry in _box.toMap().entries) {
      if (entry.key == dailyBundleCacheSchemaKey) continue;
      try {
        final map = Map<String, dynamic>.from(jsonDecode(entry.value) as Map);
        out.add(DayBundle.fromJson(map).day);
      } catch (_) {
        // Skip this one entry, keep the rest.
      }
    }
    return out;
  }

  Future<void> _markSchemaCurrent() => _box.put(
    dailyBundleCacheSchemaKey,
    dailyBundleCacheSchemaVersion.toString(),
  );
}

final dailyBundleCacheStorageProvider = Provider<DailyBundleCacheStorage>((
  ref,
) {
  return DailyBundleCacheStorage();
});
