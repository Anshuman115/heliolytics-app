import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:heliolytics/models/day_metric.dart';
import 'package:heliolytics/providers/detail_metrics_provider.dart';
import 'package:heliolytics/providers/live_hr_provider.dart';
import 'package:heliolytics/widgets/heart_rate_bpm_hero.dart';

class HeartRateSummary extends ConsumerWidget {
  const HeartRateSummary({super.key, required this.day, required this.dayKey});

  final DayMetric day;
  final String dayKey;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final live = ref.watch(liveHrProvider);
    final detail = ref.watch(detailMetricsProvider(dayKey)).valueOrNull;
    final heartRate = detail?.heartRateFor(dayKey) ?? const [];
    final latest = heartRate.isEmpty ? null : heartRate.last;
    final isLive = live.isLive && live.bpm != null;
    final bpm = isLive ? live.bpm : (latest?.bpm ?? day.restingHr);

    return GestureDetector(
      onTap: () => context.push('/metric/$dayKey/continuous_hr'),
      child: HeartRateBpmHero(
        bpm: bpm,
        label: isLive
            ? 'LIVE BPM'
            : latest != null
            ? 'LATEST BPM'
            : day.restingHr != null
            ? 'RESTING BPM'
            : 'NO DATA',
        at: isLive ? live.sampledAt : latest?.sampledAt,
        isLive: isLive,
      ),
    );
  }
}
