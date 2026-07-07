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
import 'package:heliolytics/providers/band_session_provider.dart';
import 'package:heliolytics/providers/cloud_sync_provider.dart';
import 'package:heliolytics/providers/live_health_provider.dart';
import 'package:heliolytics/widgets/home_activities_section.dart';
import 'package:heliolytics/widgets/home_my_day_section.dart';
import 'package:heliolytics/widgets/home_primary_rings.dart';
import 'package:heliolytics/widgets/home_status_row.dart';
import 'package:heliolytics/providers/selected_day_provider.dart';
import 'package:heliolytics/providers/helio_nav_provider.dart';
import 'package:heliolytics/widgets/error_view.dart';
import 'package:heliolytics/models/session_state.dart';
import 'package:heliolytics/providers/sync_orchestrator.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final health = ref.watch(liveHealthProvider);
    final apiReady = ref.watch(apiConfiguredProvider);
    final sync = ref.watch(syncOrchestratorProvider);
    final syncBusy = _syncBusy(sync.state);

    return Column(
      children: [
        _topBar(ref, health, syncBusy),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () => ref.read(liveHealthProvider.notifier).reload(),
            child: health.when(
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
                  ErrorView(error: e, onRetry: () => ref.invalidate(liveHealthProvider)),
                ],
              ),
              data: (snap) => _body(context, ref, snap, apiReady),
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

  Widget _topBar(WidgetRef ref, AsyncValue health, bool syncBusy) {
    final day = ref.watch(selectedDayProvider);
    final keys = ref.watch(availableDayKeysProvider);
    final idx = day == null ? -1 : keys.indexOf(day.dayKey);
    final snap = health.valueOrNull;
    final sync = ref.watch(syncOrchestratorProvider);
    final band = ref.watch(bandSessionProvider);
    final isConnected = band.isConnected ||
        sync.state == SessionState.connected ||
        sync.state == SessionState.fetching ||
        sync.state == SessionState.authenticating ||
        sync.state == SessionState.connecting;

    return HelioTopBar(
      showProfile: true,
      dayLabel: day != null ? formatNavDayLabel(day.dayKey) : '—',
      onPrevDay: () => shiftSelectedDay(ref, -1),
      onNextDay: () => shiftSelectedDay(ref, 1),
      // days are DESC (keys[0] = today); older days live at higher indices,
      // so "previous" is enabled when a higher index exists, "next" when a
      // lower (newer) one does.
      canGoPrev: idx >= 0 && idx < keys.length - 1,
      canGoNext: idx > 0,
      batteryPercent: snap?.batteryPercent,
      syncActive: syncBusy,
      strapConnected: isConnected,
    );
  }

  Widget _body(BuildContext context, WidgetRef ref, snap, AsyncValue<bool> apiReady) {
    if (snap == null || snap.days.isEmpty) {
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

    final day = ref.watch(selectedDayProvider) ?? snap.days.first;
    void open(String id) => context.push('/metric/${day.dayKey}/$id');

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(HelioSpacing.lg, 0, HelioSpacing.lg, HelioSpacing.xxl),
      children: [
        _apiBanner(apiReady),
        HomePrimaryRings(day: day, onRingTap: open),
        const SizedBox(height: HelioSpacing.lg),
        HomeStatusRow(
          day: day,
          onHealthTap: () => context.push('/health/${day.dayKey}'),
          onStressTap: () => open('stress'),
        ),
        const SizedBox(height: HelioSpacing.lg),
        _stepsCard(day),
        const SizedBox(height: HelioSpacing.xl),
        HomeMyDaySection(onTap: () => open('readiness')),
        const SizedBox(height: HelioSpacing.xl),
        HomeActivitiesSection(snap: snap, day: day),
      ],
    );
  }

  Widget _stepsCard(day) {
    final steps = day.steps as int;
    final stepsStr = steps > 0 ? formatStepCount(steps) : '—';
    return HelioSurfaceCard(
      padding: const EdgeInsets.symmetric(
        horizontal: HelioSpacing.lg,
        vertical: HelioSpacing.md,
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: HelioColors.strainBlue.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.directions_walk_outlined,
              size: 18,
              color: HelioColors.strainBlue,
            ),
          ),
          const SizedBox(width: HelioSpacing.md),
          Text(
            'STEPS',
            style: HelioTypography.capsLabel,
          ),
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
