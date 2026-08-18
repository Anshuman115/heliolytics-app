import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:heliolytics/design_system/tokens/helio_spacing.dart';
import 'package:heliolytics/utils/health_monitor_readings.dart';
import 'package:heliolytics/widgets/health/health_metric_card.dart';

/// Two-column grid of readings, each judged against the user's own baseline
/// where applicable. A trailing odd card keeps its column rather than stretching.
class HealthMetricGrid extends ConsumerWidget {
  final List<HealthReading> readings;
  final String dayKey;

  const HealthMetricGrid({
    super.key,
    required this.readings,
    required this.dayKey,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: HelioSpacing.md,
        mainAxisSpacing: HelioSpacing.md,
        childAspectRatio: 1.35,
      ),
      itemCount: readings.length,
      itemBuilder: (_, i) => _card(context, readings[i]),
    );
  }

  Widget _card(BuildContext context, HealthReading r) {
    return HealthMetricCard(
      label: r.label,
      icon: r.icon,
      value: r.value,
      unit: r.unit,
      assessment: r.assessment,
      onTap: r.metricId == null
          ? null
          : () => context.push('/metric/$dayKey/${r.metricId}'),
    );
  }
}
