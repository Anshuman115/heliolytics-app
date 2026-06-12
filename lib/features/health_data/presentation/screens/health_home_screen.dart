import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:heliolytics/core/theme/app_spacing.dart';
import 'package:heliolytics/core/theme/metric_colors.dart';
import 'package:heliolytics/core/utils/formatters.dart';
import 'package:heliolytics/features/health_data/domain/entities/day_metric.dart';
import 'package:heliolytics/features/health_data/domain/entities/temp_sample.dart';
import 'package:heliolytics/features/health_data/domain/metric_catalog.dart';
import 'package:heliolytics/features/health_data/presentation/providers/live_health_provider.dart';
import 'package:heliolytics/features/health_data/presentation/providers/selected_day_provider.dart';
import 'package:heliolytics/features/health_data/presentation/widgets/day_selector.dart';
import 'package:heliolytics/features/health_data/presentation/widgets/home_status_bar.dart';
import 'package:heliolytics/features/health_data/presentation/widgets/metric_overview_card.dart';
import 'package:heliolytics/features/health_data/presentation/widgets/metric_rings_row.dart';
import 'package:heliolytics/features/health_data/presentation/widgets/recovery_hero.dart';
import 'package:heliolytics/features/health_data/presentation/widgets/rollup_metric_card.dart';
import 'package:heliolytics/features/health_data/presentation/widgets/temperature_chart.dart';
import 'package:heliolytics/features/health_data/presentation/widgets/week_heatmap.dart';
import 'package:heliolytics/features/health_data/presentation/widgets/week_trend_panel.dart';
import 'package:heliolytics/shared/providers/shell_tab_provider.dart';
import 'package:heliolytics/shared/widgets/empty_state_view.dart';
import 'package:heliolytics/shared/widgets/error_view.dart';

class HealthHomeScreen extends ConsumerWidget {
  const HealthHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final health = ref.watch(liveHealthProvider);
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () => ref.read(liveHealthProvider.notifier).reload(),
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: health.when(
            loading: () => [
              const SliverFillRemaining(child: Center(child: CircularProgressIndicator())),
            ],
            error: (e, _) => [
              SliverFillRemaining(
                child: ErrorView(error: e, onRetry: () => ref.invalidate(liveHealthProvider)),
              ),
            ],
            data: (data) => _dataSlivers(context, ref, data),
          ),
        ),
      ),
    );
  }

  List<Widget> _dataSlivers(BuildContext context, WidgetRef ref, data) {
    if (data == null || data.days.isEmpty) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: EmptyStateView(
            icon: Icons.insights_outlined,
            title: 'No metrics yet',
            message: 'Sync your strap in Settings to load health data.',
            actionLabel: 'Open Settings',
            onAction: () => goToSettingsTab(ref),
          ),
        ),
      ];
    }

    final day = ref.watch(selectedDayProvider) ?? data.days.first;
    final snap = data;
    final series = snap.seriesByMetric(day.dayKey);
    final kcal = snap.caloriesFor(day.dayKey);
    void open(String id) => context.push('/metric/${day.dayKey}/$id');

    return [
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.lg, AppSpacing.md, 0),
          child: Text('Your day', style: Theme.of(context).textTheme.labelSmall),
        ),
      ),
      const SliverToBoxAdapter(child: DaySelector()),
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: WeekHeatmap(
            days: snap.days,
            selectedDayKey: day.dayKey,
            onDaySelected: (k) => selectDay(ref, k),
          ),
        ),
      ),
      SliverToBoxAdapter(
        child: HomeStatusBar(
          lastSyncedAt: snap.lastSyncedAt,
          batteryPercent: snap.batteryPercent,
        ),
      ),
      SliverPadding(
        padding: const EdgeInsets.all(AppSpacing.md),
        sliver: SliverList(
          delegate: SliverChildListDelegate([
            WeekTrendPanel(days: snap.days),
            const SizedBox(height: AppSpacing.md),
            RecoveryHero(day: day, onTap: () => open('readiness')),
            if (kcal > 0) ...[
              const SizedBox(height: AppSpacing.sm),
              Card(
                child: ListTile(
                  leading: Icon(Icons.local_fire_department, color: MetricColors.workout),
                  title: Text('$kcal kcal'),
                  subtitle: const Text('Workout + activity calories'),
                  onTap: () => context.push('/day/${day.dayKey}'),
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.md),
            MetricRingsRow(day: day, onRingTap: open),
            const SizedBox(height: AppSpacing.lg),
            Text('Metrics', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: AppSpacing.sm),
            RollupMetricCard(
              def: MetricCatalog.byId('sleep')!,
              valueLabel: day.sleepScore?.toString() ?? '—',
              subtitle: formatSleepMins(day.sleepMins),
              onTap: () => goToSleepTab(ref),
            ),
            ...MetricCatalog.homeOrder.where((id) {
              final d = MetricCatalog.byId(id);
              return d?.seriesKey != null && id != 'sleep';
            }).map((id) {
              final def = MetricCatalog.byId(id)!;
              return MetricOverviewCard(
                def: def,
                valueLabel: def.summaryValue(day),
                samples: series[def.seriesKey] ?? [],
                onOpenDetail: () => open(id),
              );
            }),
            _tempCard(context, day, snap.tempFor(day.dayKey), () => open('temperature')),
            RollupMetricCard(
              def: MetricCatalog.byId('pai')!,
              valueLabel: defSummary(day, 'pai'),
              onTap: () => open('pai'),
            ),
            RollupMetricCard(
              def: MetricCatalog.byId('steps')!,
              valueLabel: formatSteps(day.steps),
              onTap: () => open('steps'),
            ),
            const SizedBox(height: AppSpacing.md),
            Text('More series', style: Theme.of(context).textTheme.titleSmall),
            ...['spo2_sleep', 'resp_rate', 'max_hr'].map((id) {
              final def = MetricCatalog.byId(id)!;
              return MetricOverviewCard(
                def: def,
                valueLabel: '—',
                samples: series[def.seriesKey] ?? [],
                onOpenDetail: () => open(id),
              );
            }),
          ]),
        ),
      ),
      const SliverToBoxAdapter(child: SizedBox(height: 80)),
    ];
  }

  String defSummary(day, String id) => MetricCatalog.byId(id)!.summaryValue(day);

  Widget _tempCard(BuildContext ctx, DayMetric day, List<TempSample> temps, VoidCallback onTap) {
    final def = MetricCatalog.byId('temperature')!;
    final value = def.summaryValue(day);
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    backgroundColor: def.color.withValues(alpha: 0.15),
                    child: Icon(def.icon, color: def.color, size: 20),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(def.title, style: Theme.of(ctx).textTheme.titleMedium),
                        Text(value, style: Theme.of(ctx).textTheme.titleMedium?.copyWith(color: def.color)),
                      ],
                    ),
                  ),
                ],
              ),
              Text(def.note, style: Theme.of(ctx).textTheme.bodySmall),
              if (temps.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.sm),
                TemperatureChart(samples: temps, height: 72),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
