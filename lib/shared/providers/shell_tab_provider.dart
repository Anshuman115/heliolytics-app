import 'package:flutter_riverpod/flutter_riverpod.dart';

final shellTabProvider = StateProvider<int>((ref) => 0);

void goToSettingsTab(WidgetRef ref) => ref.read(shellTabProvider.notifier).state = 3;

void goToSleepTab(WidgetRef ref) => ref.read(shellTabProvider.notifier).state = 1;

/// @deprecated Use [goToSettingsTab] — sync lives under Settings.
void goToSyncTab(WidgetRef ref) => goToSettingsTab(ref);
