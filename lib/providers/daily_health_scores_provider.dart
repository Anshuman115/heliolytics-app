import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:heliolytics/models/daily_health_scores.dart';
import 'package:heliolytics/providers/cloud_sync_provider.dart';
import 'package:heliolytics/providers/live_health_provider.dart';
import 'package:heliolytics/services/cache/daily_health_scores_cache_storage.dart';
import 'package:heliolytics/utils/day_key.dart';

final dailyHealthScoresProvider =
    FutureProvider.family<DailyHealthScores, String>((ref, dayKey) async {
  final cache = ref.watch(dailyHealthScoresCacheStorageProvider);
  final isFinal = isFinalDayKey(dayKey);

  if (isFinal) {
    final cached = await cache.read(dayKey);
    if (cached != null) return cached;
  }

  final configured = await ref.read(apiConfiguredProvider.future);
  if (!configured) return DailyHealthScores.empty(dayKey);

  final scores = await ref.read(metricsApiClientProvider).fetchDailyHealthScores(dayKey);
  if (isFinal) await cache.write(dayKey, scores);
  return scores;
});
