import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:heliolytics/utils/day_key.dart';

final selectedDayKeyProvider = StateProvider<String?>((ref) => null);

void selectDay(WidgetRef ref, String dayKey) {
  ref.read(selectedDayKeyProvider.notifier).state = dayKey;
}

/// Next selectable day key; null when [delta] would pass IST today.
String? stepDayKey(String current, int delta, {DateTime? now}) {
  final next = shiftDayKey(current, delta);
  return next.compareTo(todayDayKey(now: now)) > 0 ? null : next;
}

void shiftSelectedDay(WidgetRef ref, int delta) {
  final current = ref.read(selectedDayKeyProvider) ?? todayDayKey();
  final next = stepDayKey(current, delta);
  if (next == null) return;
  ref.read(selectedDayKeyProvider.notifier).state = next;
}
