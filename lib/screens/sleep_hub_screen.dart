import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:heliolytics/design_system/components/helio_empty_state.dart';
import 'package:heliolytics/design_system/components/helio_loading.dart';
import 'package:heliolytics/design_system/components/helio_top_bar.dart';
import 'package:heliolytics/design_system/tokens/helio_spacing.dart';
import 'package:heliolytics/providers/day_bundle_provider.dart';
import 'package:heliolytics/providers/selected_day_provider.dart';
import 'package:heliolytics/utils/day_key.dart';
import 'package:heliolytics/widgets/error_view.dart';
import 'package:heliolytics/widgets/sleep_hero.dart';

class SleepHubScreen extends ConsumerWidget {
  const SleepHubScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dayKey = ref.watch(selectedDayKeyProvider) ?? todayDayKey();
    final bundleAsync = ref.watch(dayBundleProvider(dayKey));

    return Column(
      children: [
        const HelioTopBar(title: 'Sleep'),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async => ref.invalidate(dayBundleProvider(dayKey)),
            child: bundleAsync.when(
              loading: () => ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [SizedBox(height: 120), HelioLoading()],
              ),
              error: (e, _) => ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  ErrorView(error: e, onRetry: () => ref.invalidate(dayBundleProvider(dayKey))),
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
                          message: 'Sync your strap to load sleep for this day.',
                        ),
                      ],
                    )
                  : ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(HelioSpacing.lg),
                      children: [SleepHero(bundle: bundle, dayKey: dayKey)],
                    ),
            ),
          ),
        ),
      ],
    );
  }
}
