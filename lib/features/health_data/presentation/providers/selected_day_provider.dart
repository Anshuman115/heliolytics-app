import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:heliolytics/features/health_data/domain/entities/day_metric.dart';
import 'package:heliolytics/features/health_data/presentation/providers/live_health_provider.dart';

final selectedDayKeyProvider = StateProvider<String?>((ref) => null);

final selectedDayProvider = Provider<DayMetric?>((ref) {
  final snap = ref.watch(liveHealthProvider).valueOrNull;
  if (snap == null || snap.days.isEmpty) return null;
  final key = ref.watch(selectedDayKeyProvider) ?? snap.days.first.dayKey;
  for (final d in snap.days) {
    if (d.dayKey == key) return d;
  }
  return snap.days.first;
});

final availableDayKeysProvider = Provider<List<String>>((ref) {
  final snap = ref.watch(liveHealthProvider).valueOrNull;
  if (snap == null) return [];
  return snap.days.map((d) => d.dayKey).toList();
});

void selectDay(WidgetRef ref, String dayKey) {
  ref.read(selectedDayKeyProvider.notifier).state = dayKey;
}

void shiftSelectedDay(WidgetRef ref, int delta) {
  final keys = ref.read(availableDayKeysProvider);
  if (keys.isEmpty) return;
  final current = ref.read(selectedDayProvider)?.dayKey ?? keys.first;
  final idx = keys.indexOf(current);
  if (idx < 0) {
    selectDay(ref, keys.first);
    return;
  }
  final next = (idx - delta).clamp(0, keys.length - 1);
  selectDay(ref, keys[next]);
}
