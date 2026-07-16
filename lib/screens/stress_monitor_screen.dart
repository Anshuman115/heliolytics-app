import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:heliolytics/design_system/components/helio_loading.dart';
import 'package:heliolytics/design_system/components/helio_top_bar.dart';
import 'package:heliolytics/providers/live_health_provider.dart';
import 'package:heliolytics/widgets/error_view.dart';
import 'package:heliolytics/widgets/stress/stress_day_body.dart';

class StressMonitorScreen extends ConsumerWidget {
  final String dayKey;

  const StressMonitorScreen({super.key, required this.dayKey});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final health = ref.watch(liveHealthProvider);
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
            child: health.when(
              loading: () => const HelioLoading(),
              error: (e, _) => ErrorView(
                error: e,
                onRetry: () => ref.invalidate(liveHealthProvider),
              ),
              data: (snap) => snap == null
                  ? const SizedBox.shrink()
                  : detail.when(
                      loading: () => const HelioLoading(),
                      error: (e, _) => ErrorView(
                        error: e,
                        onRetry: () => ref.invalidate(detailMetricsProvider),
                      ),
                      data: (d) => StressDayBody(
                        samples: d.seriesFor(dayKey, 'stress'),
                        snapshot: snap,
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
