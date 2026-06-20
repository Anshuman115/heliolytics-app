import 'package:flutter_riverpod/flutter_riverpod.dart';

final helioNavProvider = StateProvider<int>((ref) => 0);

void goToHelioTab(WidgetRef ref, int index) =>
    ref.read(helioNavProvider.notifier).state = index;

void goToHelioSettings(WidgetRef ref) => goToHelioTab(ref, 3);

void goToHelioSleep(WidgetRef ref) => goToHelioTab(ref, 1);
