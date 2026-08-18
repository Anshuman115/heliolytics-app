import 'package:flutter/material.dart';
import 'package:heliolytics/design_system/components/helio_surface_card.dart';
import 'package:heliolytics/design_system/tokens/helio_spacing.dart';
import 'package:heliolytics/design_system/tokens/helio_typography.dart';
import 'package:heliolytics/models/day_bundle.dart';
import 'package:heliolytics/models/health_sample.dart';
import 'package:heliolytics/models/metric_catalog.dart';
import 'package:heliolytics/utils/formatters.dart';
import 'package:heliolytics/widgets/sleep_naps_section.dart';
import 'package:heliolytics/widgets/sleep_night_detail_card.dart';

class SleepMetricBody extends StatelessWidget {
  const SleepMetricBody({
    super.key,
    required this.bundle,
    required this.dayKey,
    this.stressSamples = const [],
  });

  final DayBundle bundle;
  final String dayKey;
  final List<HealthSample> stressSamples;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          "Last Night's Sleep",
          style: HelioTypography.scoreMedium.copyWith(fontSize: 26),
        ),
        const SizedBox(height: HelioSpacing.xs),
        Text(
          '${formatSleepComparisonDay(dayKey)} vs. prior 30 days',
          style: HelioTypography.bodyMuted.copyWith(fontSize: 15),
        ),
        const SizedBox(height: HelioSpacing.sm),
        SleepNightDetailCard(bundle: bundle, stressSamples: stressSamples),
        if (bundle.naps.isNotEmpty) ...[
          const SizedBox(height: HelioSpacing.lg),
          SleepNapsSection(naps: bundle.naps),
        ],
        const SizedBox(height: HelioSpacing.sm),
        HelioSurfaceCard(
          padding: const EdgeInsets.all(HelioSpacing.lg),
          child: Text(
            MetricCatalog.byId('sleep')!.detail,
            style: HelioTypography.bodyMuted,
          ),
        ),
      ],
    );
  }
}
