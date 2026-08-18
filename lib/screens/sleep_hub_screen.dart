import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:heliolytics/design_system/components/helio_empty_state.dart';
import 'package:heliolytics/design_system/components/helio_loading.dart';
import 'package:heliolytics/design_system/components/helio_top_bar.dart';
import 'package:heliolytics/design_system/tokens/helio_spacing.dart';
import 'package:heliolytics/providers/day_bundle_provider.dart';
import 'package:heliolytics/providers/health_data_refresh_coordinator.dart';
import 'package:heliolytics/providers/selected_day_provider.dart';
import 'package:heliolytics/utils/day_key.dart';
import 'package:heliolytics/utils/day_picker.dart';
import 'package:heliolytics/utils/formatters.dart';
import 'package:heliolytics/widgets/error_view.dart';
import 'package:heliolytics/widgets/sleep_hero.dart';
import 'package:heliolytics/widgets/sleep_metric_body.dart';

class SleepHubScreen extends ConsumerWidget {
  const SleepHubScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dayKey = ref.watch(selectedDayKeyProvider) ?? todayDayKey();
    final bundleAsync = ref.watch(dayBundleProvider(dayKey));

    return Column(
      children: [
        HelioTopBar(
          safeTop: false,
          dayLabel: formatNavDayLabel(dayKey),
          onPrevDay: () => shiftSelectedDay(ref, -1),
          onNextDay: () => shiftSelectedDay(ref, 1),
          onDateTap: () async {
            final selected = await pickDay(context, dayKey: dayKey);
            if (selected != null) selectDay(ref, selected);
          },
          canGoNext: dayKey != todayDayKey(),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () => ref
                .read(healthDataRefreshCoordinatorProvider)
                .refreshDay(dayKey),
            child: bundleAsync.when(
              loading: () => ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [SizedBox(height: 120), HelioLoading()],
              ),
              error: (e, _) => ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  ErrorView(
                    error: e,
                    onRetry: () => ref
                        .read(healthDataRefreshCoordinatorProvider)
                        .retryDay(dayKey),
                  ),
                ],
              ),
              data: (bundle) => bundle.mainSleep == null && bundle.naps.isEmpty
                  ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: const [
                        SizedBox(height: 80),
                        HelioEmptyState(
                          icon: Icons.bedtime_outlined,
                          title: 'No sleep data',
                          message:
                              'Sync your strap to load sleep for this day.',
                        ),
                      ],
                    )
                  : ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(HelioSpacing.lg),
                      children: [
                        SleepHero(bundle: bundle),
                        const SizedBox(height: HelioSpacing.xxl),
                        SleepMetricBody(bundle: bundle, dayKey: dayKey),
                      ],
                    ),
            ),
          ),
        ),
      ],
    );
  }
}
