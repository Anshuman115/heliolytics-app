import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:heliolytics/core/utils/formatters.dart';
import 'package:heliolytics/features/health_data/domain/entities/day_metric.dart';
import 'package:heliolytics/features/health_data/presentation/providers/live_health_provider.dart';
import 'package:heliolytics/features/health_data/presentation/screens/day_detail_body.dart';
import 'package:heliolytics/shared/widgets/error_view.dart';

class DayDetailScreen extends ConsumerWidget {
  final String dayKey;
  const DayDetailScreen({super.key, required this.dayKey});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final health = ref.watch(liveHealthProvider);
    return health.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(
        appBar: AppBar(title: Text(formatDayLabel(dayKey))),
        body: ErrorView(error: e, onRetry: () => ref.invalidate(liveHealthProvider)),
      ),
      data: (snap) {
        if (snap == null) {
          return Scaffold(
            appBar: AppBar(title: Text(formatDayLabel(dayKey))),
            body: const Center(child: Text('No data')),
          );
        }
        DayMetric? day;
        for (final d in snap.days) {
          if (d.dayKey == dayKey) {
            day = d;
            break;
          }
        }
        if (day == null) {
          return Scaffold(
            appBar: AppBar(title: Text(formatDayLabel(dayKey))),
            body: const Center(child: Text('Day not found')),
          );
        }
        return DayDetailBody(
          day: day,
          workouts: snap.workoutsFor(dayKey),
          totalCalories: snap.caloriesFor(dayKey),
          temps: snap.tempFor(dayKey),
          series: snap.seriesByMetric(dayKey),
        );
      },
    );
  }
}
