import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:heliolytics/utils/day_key.dart';

final selectedDayKeyProvider = StateProvider<String?>((ref) => null);

void selectDay(WidgetRef ref, String dayKey) {
  ref.read(selectedDayKeyProvider.notifier).state = dayKey;
}

void shiftSelectedDay(WidgetRef ref, int delta) {
  final current = ref.read(selectedDayKeyProvider) ?? todayDayKey();
  final date = DateTime.parse(current).add(Duration(days: -delta));
  final next = dayKeyFor(date);
  if (next.compareTo(todayDayKey()) > 0) return; // never page into the future
  ref.read(selectedDayKeyProvider.notifier).state = next;
}
