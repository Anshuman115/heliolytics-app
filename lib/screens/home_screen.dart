import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:heliolytics/constants/constants.dart';
import 'package:heliolytics/design_system/components/helio_cloud_banner.dart';
import 'package:heliolytics/design_system/components/helio_empty_state.dart';
import 'package:heliolytics/design_system/components/helio_loading.dart';
import 'package:heliolytics/design_system/tokens/helio_spacing.dart';
import 'package:heliolytics/models/day_bundle.dart';
import 'package:heliolytics/providers/cloud_sync_provider.dart';
import 'package:heliolytics/providers/day_bundle_provider.dart';
import 'package:heliolytics/providers/health_data_refresh_coordinator.dart';
import 'package:heliolytics/widgets/home_activities_section.dart';
import 'package:heliolytics/widgets/home_daily_insight.dart';
import 'package:heliolytics/widgets/home_health_scores_section.dart';
import 'package:heliolytics/widgets/home_my_day_section.dart';
import 'package:heliolytics/widgets/home_primary_rings.dart';
import 'package:heliolytics/widgets/home_status_row.dart';
import 'package:heliolytics/widgets/home_sleep_summary_card.dart';
import 'package:heliolytics/widgets/home_top_bar.dart';
import 'package:heliolytics/providers/selected_day_provider.dart';
import 'package:heliolytics/providers/helio_nav_provider.dart';
import 'package:heliolytics/utils/day_key.dart';
import 'package:heliolytics/widgets/error_view.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dayKey = ref.watch(selectedDayKeyProvider) ?? todayDayKey();
    final bundleAsync = ref.watch(dayBundleProvider(dayKey));
    final apiReady = ref.watch(apiConfiguredProvider);

    return Column(
      children: [
        HomeTopBar(dayKey: dayKey),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () => ref
                .read(healthDataRefreshCoordinatorProvider)
                .refreshDay(dayKey, healthScores: true),
            child: bundleAsync.when(
              loading: () => ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  SizedBox(height: 200),
                  HelioLoading(message: 'Loading metrics…'),
                ],
              ),
              error: (e, _) => ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  ErrorView(
                    error: e,
                    onRetry: () => ref
                        .read(healthDataRefreshCoordinatorProvider)
                        .retryDay(dayKey, healthScores: true),
                  ),
                ],
              ),
              data: (bundle) => _body(context, ref, bundle, apiReady, dayKey),
            ),
          ),
        ),
      ],
    );
  }

  Widget _body(
    BuildContext context,
    WidgetRef ref,
    DayBundle bundle,
    AsyncValue<bool> apiReady,
    String dayKey,
  ) {
    final day = bundle.day;
    if (day.steps == 0 && day.readiness == null && day.sleepScore == null) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(HelioSpacing.lg),
        children: [
          _apiBanner(apiReady),
          HelioEmptyState(
            icon: Icons.insights_outlined,
            title: 'No metrics yet',
            message: 'Sync your strap to load health data.',
            actionLabel: 'Open Settings',
            onAction: () => goToHelioSettings(ref),
          ),
        ],
      );
    }

    void open(String id) => context.push('/metric/$dayKey/$id');

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        HelioSpacing.lg,
        0,
        HelioSpacing.lg,
        shellContentBottomPadding,
      ),
      children: [
        _apiBanner(apiReady),
        HomePrimaryRings(day: day, onRingTap: open),
        const SizedBox(height: HelioSpacing.sm),
        HomeDailyInsight(day: day, onTap: () => open('readiness')),
        const SizedBox(height: HelioSpacing.lg),
        HomeStatusRow(
          day: day,
          onHealthTap: () => context.push('/health/$dayKey'),
          onStressTap: () => context.push('/stress/$dayKey'),
        ),
        const SizedBox(height: HelioSpacing.xl),
        HomeMyDaySection(
          day: day,
          onTap: () => open('readiness'),
          onAddTap: () => goToHelioTab(ref, 2),
        ),
        if (bundle.mainSleep case final sleep?) ...[
          const SizedBox(height: HelioSpacing.lg),
          HomeSleepSummaryCard(
            sleep: sleep,
            onTap: () => context.push('/metric/$dayKey/sleep'),
          ),
        ],
        const SizedBox(height: HelioSpacing.xl),
        HomeActivitiesSection(bundle: bundle),
        const SizedBox(height: HelioSpacing.xl),
        HomeHealthScoresSection(dayKey: dayKey),
      ],
    );
  }

  Widget _apiBanner(AsyncValue<bool> apiReady) {
    return apiReady.when(
      data: (ok) => ok
          ? const SizedBox.shrink()
          : const Padding(
              padding: EdgeInsets.only(bottom: HelioSpacing.md),
              child: HelioCloudBanner(),
            ),
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}
