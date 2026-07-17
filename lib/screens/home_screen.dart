import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:heliolytics/utils/formatters.dart';
import 'package:heliolytics/design_system/components/helio_cloud_banner.dart';
import 'package:heliolytics/design_system/components/helio_empty_state.dart';
import 'package:heliolytics/design_system/components/helio_loading.dart';
import 'package:heliolytics/design_system/components/helio_surface_card.dart';
import 'package:heliolytics/design_system/components/helio_top_bar.dart';
import 'package:heliolytics/design_system/tokens/helio_colors.dart';
import 'package:heliolytics/design_system/tokens/helio_spacing.dart';
import 'package:heliolytics/design_system/tokens/helio_typography.dart';
import 'package:heliolytics/models/day_bundle.dart';
import 'package:heliolytics/providers/band_session_provider.dart';
import 'package:heliolytics/providers/cloud_sync_provider.dart';
import 'package:heliolytics/providers/day_bundle_provider.dart';
import 'package:heliolytics/widgets/home_activities_section.dart';
import 'package:heliolytics/widgets/home_health_scores_section.dart';
import 'package:heliolytics/widgets/home_my_day_section.dart';
import 'package:heliolytics/widgets/home_primary_rings.dart';
import 'package:heliolytics/widgets/home_status_row.dart';
import 'package:heliolytics/providers/selected_day_provider.dart';
import 'package:heliolytics/providers/helio_nav_provider.dart';
import 'package:heliolytics/utils/day_key.dart';
import 'package:heliolytics/widgets/error_view.dart';
import 'package:heliolytics/models/session_state.dart';
import 'package:heliolytics/providers/sync_orchestrator.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dayKey = ref.watch(selectedDayKeyProvider) ?? todayDayKey();
    final bundleAsync = ref.watch(dayBundleProvider(dayKey));
    final apiReady = ref.watch(apiConfiguredProvider);
    final sync = ref.watch(syncOrchestratorProvider);
    final syncBusy = _syncBusy(sync.state);

    return Column(
      children: [
        _topBar(ref, dayKey, syncBusy),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async => ref.invalidate(dayBundleProvider(dayKey)),
            child: bundleAsync.when(
              loading: () => ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [SizedBox(height: 200), HelioLoading(message: 'Loading metrics…')],
              ),
              error: (e, _) => ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [ErrorView(error: e, onRetry: () => ref.invalidate(dayBundleProvider(dayKey)))],
              ),
              data: (bundle) => _body(context, ref, bundle, apiReady, dayKey),
            ),
          ),
        ),
      ],
    );
  }

  bool _syncBusy(SessionState state) =>
      state == SessionState.fetching ||
      state == SessionState.connecting ||
      state == SessionState.authenticating ||
      state == SessionState.scanning;

  Widget _topBar(WidgetRef ref, String dayKey, bool syncBusy) {
    final sync = ref.watch(syncOrchestratorProvider);
    final band = ref.watch(bandSessionProvider);
    final isConnected = band.isConnected ||
        sync.state == SessionState.connected ||
        sync.state == SessionState.fetching ||
        sync.state == SessionState.authenticating ||
        sync.state == SessionState.connecting;

    return HelioTopBar(
      showProfile: true,
      dayLabel: formatNavDayLabel(dayKey),
      onPrevDay: () => shiftSelectedDay(ref, -1),
      onNextDay: () => shiftSelectedDay(ref, 1),
      canGoPrev: true,
      canGoNext: dayKey != todayDayKey(),
      syncActive: syncBusy,
      strapConnected: isConnected,
    );
  }

  Widget _body(BuildContext context, WidgetRef ref, DayBundle bundle,
      AsyncValue<bool> apiReady, String dayKey) {
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
      padding: const EdgeInsets.fromLTRB(HelioSpacing.lg, 0, HelioSpacing.lg, HelioSpacing.xxl),
      children: [
        _apiBanner(apiReady),
        HomePrimaryRings(day: day, onRingTap: open),
        const SizedBox(height: HelioSpacing.lg),
        HomeStatusRow(
          day: day,
          onHealthTap: () => context.push('/health/$dayKey'),
          onStressTap: () => context.push('/stress/$dayKey'),
        ),
        const SizedBox(height: HelioSpacing.lg),
        _stepsCard(day),
        const SizedBox(height: HelioSpacing.xl),
        HomeMyDaySection(onTap: () => open('readiness')),
        const SizedBox(height: HelioSpacing.xl),
        HomeActivitiesSection(bundle: bundle),
        const SizedBox(height: HelioSpacing.xl),
        HomeHealthScoresSection(dayKey: dayKey),
      ],
    );
  }

  Widget _stepsCard(day) {
    final steps = day.steps as int;
    final stepsStr = steps > 0 ? formatStepCount(steps) : '—';
    return HelioSurfaceCard(
      padding: const EdgeInsets.symmetric(horizontal: HelioSpacing.lg, vertical: HelioSpacing.md),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: HelioColors.strainBlue.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.directions_walk_outlined, size: 18, color: HelioColors.strainBlue),
          ),
          const SizedBox(width: HelioSpacing.md),
          Text('STEPS', style: HelioTypography.capsLabel),
          const Spacer(),
          Text(
            stepsStr,
            style: HelioTypography.scoreLarge.copyWith(
              fontSize: 28,
              color: steps > 0 ? HelioColors.strainBlue : HelioColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _apiBanner(AsyncValue<bool> apiReady) {
    return apiReady.when(
      data: (ok) => ok ? const SizedBox.shrink() : const Padding(
        padding: EdgeInsets.only(bottom: HelioSpacing.md),
        child: HelioCloudBanner(),
      ),
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}
