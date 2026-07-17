import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:heliolytics/design_system/components/helio_surface_card.dart';
import 'package:heliolytics/design_system/tokens/helio_spacing.dart';
import 'package:heliolytics/design_system/tokens/helio_typography.dart';
import 'package:heliolytics/models/day_metric.dart';
import 'package:heliolytics/models/health_sample.dart';
import 'package:heliolytics/utils/stress_zones.dart';
import 'package:heliolytics/widgets/stress/stress_day_chart.dart';
import 'package:heliolytics/widgets/stress/stress_gauge.dart';
import 'package:heliolytics/widgets/stress/stress_zone_split.dart';

/// Everything below the top bar on the stress screen: gauge, day trace, and
/// the time-in-band breakdown.
class StressDayBody extends StatelessWidget {
  final List<HealthSample> samples;
  final List<SleepMetric> sleepEntries;
  final String dayKey;

  const StressDayBody({
    super.key,
    required this.samples,
    required this.sleepEntries,
    required this.dayKey,
  });

  @override
  Widget build(BuildContext context) {
    if (samples.isEmpty) {
      return Center(
        child: Text('No stress data for this day', style: HelioTypography.bodyMuted),
      );
    }

    final latest = latestStress(samples);
    final split = splitStressByZone(samples);

    return ListView(
      padding: const EdgeInsets.all(HelioSpacing.lg),
      children: [
        Center(
          child: StressGauge(
            value: latest?.value,
            atLabel: latest == null
                ? null
                : DateFormat.jm().format(latest.sampledAt),
          ),
        ),
        const SizedBox(height: HelioSpacing.xl),
        StressDayChart(samples: samples, spans: _sleepSpans()),
        const SizedBox(height: HelioSpacing.xl),
        _totalDayCard(split),
      ],
    );
  }

  /// Sleep windows for this day, shaded behind the trace.
  List<StressSpan> _sleepSpans() {
    return [
      for (final s in sleepEntries)
        StressSpan(
          start: s.startedAt,
          end: s.startedAt.add(Duration(minutes: s.totalMins)),
        ),
    ];
  }

  Widget _totalDayCard(StressSplit split) {
    return HelioSurfaceCard(
      padding: const EdgeInsets.all(HelioSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('TOTAL DAY', style: HelioTypography.sectionTitle),
          const SizedBox(height: HelioSpacing.lg),
          StressZoneSplit(split: split),
          const SizedBox(height: HelioSpacing.md),
          Text(
            'Stress across the whole day, including sleep and activities.',
            style: HelioTypography.bodyMuted,
          ),
        ],
      ),
    );
  }
}
