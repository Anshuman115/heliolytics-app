import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:heliolytics/design_system/components/helio_top_bar.dart';
import 'package:heliolytics/providers/onboarding_provider.dart';
import 'package:heliolytics/providers/day_bundle_provider.dart';
import 'package:heliolytics/providers/band_session_provider.dart';
import 'package:heliolytics/providers/selected_day_provider.dart';
import 'package:heliolytics/providers/sync_status_provider.dart';
import 'package:heliolytics/utils/day_key.dart';
import 'package:heliolytics/utils/day_picker.dart';
import 'package:heliolytics/utils/formatters.dart';

class HomeTopBar extends ConsumerWidget {
  final String dayKey;

  const HomeTopBar({super.key, required this.dayKey});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final name = ref.watch(onboardingProvider).profile?.name;
    final battery = ref.watch(syncStatusProvider).valueOrNull?.batteryPercent;
    final day = ref.watch(dayBundleProvider(dayKey)).valueOrNull?.day;
    final connected = ref.watch(bandSessionProvider).isConnected;

    return HelioTopBar(
      safeTop: false,
      showProfile: true,
      profileLabel: _initials(name),
      profileMetricLabel: day?.paiScore == null
          ? null
          : (day!.paiScore! / 10).toStringAsFixed(1),
      onProfile: () => context.push('/profile/view'),
      dayLabel: formatNavDayLabel(dayKey),
      onPrevDay: () => shiftSelectedDay(ref, -1),
      onNextDay: () => shiftSelectedDay(ref, 1),
      onDateTap: () async {
        final selected = await pickDay(context, dayKey: dayKey);
        if (selected != null) selectDay(ref, selected);
      },
      canGoNext: dayKey != todayDayKey(),
      emphasizeDate: true,
      batteryPercent: battery,
      strapConnected: connected,
    );
  }

  String? _initials(String? name) {
    final parts = name?.trim().split(RegExp(r'\s+')) ?? const [];
    if (parts.isEmpty || parts.first.isEmpty) return null;
    if (parts.length == 1) {
      final word = parts.first;
      return word.substring(0, word.length > 1 ? 2 : 1).toUpperCase();
    }
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }
}
