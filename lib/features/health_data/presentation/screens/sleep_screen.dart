import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:heliolytics/core/theme/app_spacing.dart';
import 'package:heliolytics/core/theme/app_theme.dart';
import 'package:heliolytics/core/utils/formatters.dart';
import 'package:heliolytics/features/health_data/domain/entities/day_metric.dart';
import 'package:heliolytics/features/health_data/presentation/providers/live_health_provider.dart';
import 'package:heliolytics/features/health_data/presentation/widgets/sleep_hypnogram_chart.dart';
import 'package:heliolytics/features/health_data/presentation/widgets/sleep_stage_bar.dart';
import 'package:heliolytics/shared/widgets/empty_state_view.dart';
import 'package:heliolytics/shared/widgets/error_view.dart';

class SleepScreen extends ConsumerWidget {
  const SleepScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final health = ref.watch(liveHealthProvider);
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () => ref.read(liveHealthProvider.notifier).reload(),
        child: health.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => ErrorView(error: e, onRetry: () => ref.invalidate(liveHealthProvider)),
          data: (snap) => _body(context, snap),
        ),
      ),
    );
  }

  Widget _body(BuildContext context, snap) {
    if (snap == null || snap.days.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [
          SizedBox(height: 120),
          EmptyStateView(icon: Icons.bedtime_outlined, title: 'No sleep data', message: 'Sync your strap to load sleep.'),
        ],
      );
    }
    final days = snap.days.map((d) => d.dayKey).toList()..sort((a, b) => b.compareTo(a));
    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverAppBar(
          expandedHeight: 120,
          pinned: true,
          flexibleSpace: FlexibleSpaceBar(
            title: const Text('Sleep'),
            background: DecoratedBox(decoration: BoxDecoration(gradient: headerGradient())),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.all(AppSpacing.md),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (_, i) => _nightCard(context, snap, days[i]),
              childCount: days.length,
            ),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 80)),
      ],
    );
  }

  Widget _nightCard(BuildContext context, snap, String dayKey) {
    DayMetric? day;
    for (final d in snap.days) {
      if (d.dayKey == dayKey) {
        day = d;
        break;
      }
    }
    final sleep = snap.mainSleepFor(dayKey);
    final naps = snap.napsFor(dayKey);
    if (sleep == null && (day?.sleepMins == null)) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final deep = day?.sleepDeepMins ?? sleep?.deepMins ?? 0;
    final rem = day?.sleepRemMins ?? sleep?.remMins ?? 0;
    final light = day?.sleepLightMins ?? sleep?.lightMins ?? 0;

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      child: InkWell(
        onTap: () => context.push('/metric/$dayKey/sleep'),
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(formatDayLabel(dayKey), style: theme.textTheme.titleMedium),
              Text(
                'Score ${day?.sleepScore ?? sleep?.score ?? '—'} · '
                '${formatSleepMins(day?.sleepMins ?? sleep?.totalMins)}',
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(height: AppSpacing.sm),
              SleepStageBar(deep: deep, rem: rem, light: light),
              if (sleep != null && sleep.stages.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.sm),
                SleepHypnogramChart(stages: sleep.stages),
              ],
              if (naps.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.sm),
                Text('Naps (${naps.length})', style: theme.textTheme.labelLarge),
                ...naps.map((n) => Padding(
                      padding: const EdgeInsets.only(top: AppSpacing.sm),
                      child: Text(
                        '${formatWorkoutTime(n.startedAt)} · ${formatSleepMins(n.totalMins)}',
                        style: theme.textTheme.bodySmall,
                      ),
                    )),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
