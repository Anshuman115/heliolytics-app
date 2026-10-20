import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:heliolytics/utils/day_key.dart';
import 'package:heliolytics/utils/ist_time.dart';

final selectedDayKeyProvider = StateProvider<String?>((ref) => null);

void selectDay(WidgetRef ref, String dayKey) {
  ref.read(selectedDayKeyProvider.notifier).state = dayKey;
}

/// Today's date on the IST calendar, independent of the phone timezone.
String todayIstDayKey() => dayKeyFor(istToday());

void shiftSelectedDay(WidgetRef ref, int delta) {
  final current = ref.read(selectedDayKeyProvider) ?? todayIstDayKey();
  final date = DateTime.parse(
    '${current}T00:00:00Z',
  ).add(Duration(days: delta));
  final next = dayKeyFor(date);
  if (next.compareTo(todayIstDayKey()) > 0) return;
  ref.read(selectedDayKeyProvider.notifier).state = next;
}
