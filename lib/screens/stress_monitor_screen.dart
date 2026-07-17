import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:heliolytics/design_system/components/helio_loading.dart';
import 'package:heliolytics/design_system/components/helio_top_bar.dart';
import 'package:heliolytics/providers/day_bundle_provider.dart';
import 'package:heliolytics/providers/detail_metrics_provider.dart';
import 'package:heliolytics/widgets/error_view.dart';
import 'package:heliolytics/widgets/stress/stress_day_body.dart';

class StressMonitorScreen extends ConsumerWidget {
  final String dayKey;

  const StressMonitorScreen({super.key, required this.dayKey});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bundleAsync = ref.watch(dayBundleProvider(dayKey));
    // Per-minute stress lives in the lazy detail tier, not the day rollups.
    final detail = ref.watch(detailMetricsProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          HelioTopBar(
            showBack: true,
            onBack: () => context.pop(),
            title: 'Stress Monitor',
          ),
          Expanded(
            child: bundleAsync.when(
              loading: () => const HelioLoading(),
              error: (e, _) => ErrorView(
                error: e,
                onRetry: () => ref.invalidate(dayBundleProvider(dayKey)),
              ),
              data: (bundle) => detail.when(
                loading: () => const HelioLoading(),
                error: (e, _) => ErrorView(
                  error: e,
                  onRetry: () => ref.invalidate(detailMetricsProvider),
                ),
                data: (d) => StressDayBody(
                  samples: d.seriesFor(dayKey, 'stress'),
                  sleepEntries: bundle.sleep,
                  dayKey: dayKey,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
