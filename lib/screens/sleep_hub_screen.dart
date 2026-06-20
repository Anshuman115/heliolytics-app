import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:heliolytics/design_system/components/helio_empty_state.dart';
import 'package:heliolytics/design_system/components/helio_loading.dart';
import 'package:heliolytics/design_system/components/helio_top_bar.dart';
import 'package:heliolytics/design_system/tokens/helio_spacing.dart';
import 'package:heliolytics/models/cloud_metrics_snapshot.dart';
import 'package:heliolytics/models/day_metric.dart';
import 'package:heliolytics/providers/live_health_provider.dart';
import 'package:heliolytics/providers/helio_nav_provider.dart';
import 'package:heliolytics/widgets/sleep_hero.dart';
import 'package:heliolytics/widgets/sleep_night_list.dart';
import 'package:heliolytics/widgets/error_view.dart';

class SleepHubScreen extends ConsumerWidget {
  const SleepHubScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final health = ref.watch(liveHealthProvider);
    return Column(
      children: [
        const HelioTopBar(title: 'Sleep'),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () => ref.read(liveHealthProvider.notifier).reload(),
            child: health.when(
              loading: () => ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  SizedBox(height: 120),
                  HelioLoading(),
                ],
              ),
              error: (e, _) => ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [ErrorView(error: e, onRetry: () => ref.invalidate(liveHealthProvider))],
              ),
              data: (snap) => _body(context, ref, snap),
            ),
          ),
        ),
      ],
    );
  }

  Widget _body(BuildContext context, WidgetRef ref, CloudMetricsSnapshot? snap) {
    if (snap == null) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [
          SizedBox(height: 80),
          HelioEmptyState(
            icon: Icons.bedtime_outlined,
            title: 'No sleep data',
            message: 'Configure API and sync your strap.',
          ),
        ],
      );
    }

    final nights = _nightKeys(snap);
    if (nights.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          HelioEmptyState(
            icon: Icons.bedtime_outlined,
            title: 'No sleep data',
            message: 'Sync your strap to load sleep.',
            actionLabel: 'Open Settings',
            onAction: () => goToHelioSettings(ref),
          ),
        ],
      );
    }

    final latest = nights.first;
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(HelioSpacing.lg),
      children: [
        SleepHero(snap: snap, dayKey: latest),
        const SizedBox(height: HelioSpacing.xl),
        SleepNightList(
          snap: snap,
          dayKeys: nights,
          onTap: (key) => context.push('/metric/$key/sleep'),
        ),
        const SizedBox(height: HelioSpacing.xxl),
      ],
    );
  }

  List<String> _nightKeys(CloudMetricsSnapshot snap) {
    final keys = <String>{};
    for (final d in snap.days) {
      if (_hasSleepData(snap, d)) keys.add(d.dayKey);
    }
    for (final s in snap.sleep) {
      keys.add(s.dayKey);
    }
    final sorted = keys.toList()..sort((a, b) => b.compareTo(a));
    return sorted;
  }

  bool _hasSleepData(CloudMetricsSnapshot snap, DayMetric d) {
    if (snap.mainSleepFor(d.dayKey) != null) return true;
    if (snap.napsFor(d.dayKey).isNotEmpty) return true;
    if (d.sleepScore != null) return true;
    if (d.sleepMins != null && d.sleepMins! > 0) return true;
    if (d.sleepDeepMins != null || d.sleepRemMins != null || d.sleepLightMins != null) {
      return true;
    }
    return false;
  }
}
