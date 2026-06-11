import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:heliolytics/core/theme/app_spacing.dart';
import 'package:heliolytics/core/theme/app_theme.dart';
import 'package:heliolytics/core/theme/metric_colors.dart';
import 'package:heliolytics/core/utils/formatters.dart';
import 'package:heliolytics/features/health_data/domain/entities/day_metric.dart';
import 'package:heliolytics/features/health_data/domain/entities/health_sample.dart';
import 'package:heliolytics/features/health_data/domain/entities/temp_sample.dart';
import 'package:heliolytics/features/health_data/presentation/widgets/day_series_section.dart';
import 'package:heliolytics/features/health_data/presentation/widgets/metric_tile.dart';
import 'package:heliolytics/features/health_data/presentation/widgets/temperature_chart.dart';
import 'package:heliolytics/features/health_data/presentation/widgets/workout_tile.dart';

class DayDetailBody extends StatelessWidget {
  final DayMetric day;
  final List<WorkoutMetric> workouts;
  final int totalCalories;
  final List<TempSample> temps;
  final Map<String, List<HealthSample>> series;

  const DayDetailBody({
    super.key,
    required this.day,
    required this.workouts,
    this.totalCalories = 0,
    required this.temps,
    required this.series,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 140,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(formatDayLabel(day.dayKey), style: const TextStyle(fontSize: 16)),
              background: DecoratedBox(
                decoration: BoxDecoration(gradient: headerGradient()),
                child: Align(
                  alignment: Alignment.bottomLeft,
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Text(
                      formatSteps(day.steps),
                      style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(AppSpacing.md),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _summaryGrid(),
                const SizedBox(height: AppSpacing.lg),
                DaySeriesSection(dayKey: day.dayKey, byMetric: series),
                const SizedBox(height: AppSpacing.lg),
                Text('Skin temperature', style: theme.textTheme.titleMedium),
                Text('${temps.length} minute readings', style: theme.textTheme.bodySmall),
                const SizedBox(height: AppSpacing.sm),
                TemperatureChart(samples: temps),
                const SizedBox(height: AppSpacing.lg),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Sleep & naps'),
                  subtitle: Text(formatSleepMins(day.sleepMins)),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/metric/${day.dayKey}/sleep'),
                ),
                const SizedBox(height: AppSpacing.lg),
                Text('Workouts', style: theme.textTheme.titleMedium),
                if (workouts.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
                    child: Text('No workouts this day'),
                  )
                else
                  ...workouts.map((w) => WorkoutTile(workout: w, dayKey: day.dayKey)),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryGrid() {
    final kcal = totalCalories > 0 ? '$totalCalories kcal' : '—';
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: AppSpacing.sm,
      crossAxisSpacing: AppSpacing.sm,
      childAspectRatio: 1.5,
      children: [
        MetricTile(label: 'Readiness', value: _v(day.readiness), icon: Icons.self_improvement, color: MetricColors.readiness),
        MetricTile(label: 'Calories', value: kcal, icon: Icons.local_fire_department, color: MetricColors.workout),
        MetricTile(label: 'PAI', value: _v(day.paiScore), icon: Icons.bolt, color: MetricColors.pai),
        MetricTile(label: 'RHR latest', value: day.restingHr != null ? '${day.restingHr} bpm' : '—', icon: Icons.monitor_heart, color: MetricColors.restingHr),
        MetricTile(label: 'Stress latest', value: _v(day.stressAvg), icon: Icons.psychology, color: MetricColors.stress),
        MetricTile(label: 'HRV sleep', value: day.hrvRmssd != null ? '${day.hrvRmssd} ms' : '—', icon: Icons.favorite, color: MetricColors.hrv),
        MetricTile(label: 'SpO₂ sleep', value: day.spo2Avg != null ? '${day.spo2Avg}%' : '—', icon: Icons.air, color: MetricColors.spo2),
        MetricTile(label: 'Workouts', value: '${day.workoutCount}', icon: Icons.sports, color: MetricColors.workout),
      ],
    );
  }

  String _v(int? n) => n?.toString() ?? '—';
}
