import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:heliolytics/design_system/components/helio_loading.dart';
import 'package:heliolytics/design_system/components/helio_bottom_nav.dart';
import 'package:heliolytics/design_system/components/helio_date_nav.dart';
import 'package:heliolytics/design_system/components/helio_top_bar.dart';
import 'package:heliolytics/design_system/tokens/helio_colors.dart';
import 'package:heliolytics/design_system/tokens/helio_spacing.dart';
import 'package:heliolytics/design_system/tokens/helio_typography.dart';
import 'package:heliolytics/utils/day_key.dart';
import 'package:heliolytics/utils/day_picker.dart';
import 'package:heliolytics/utils/formatters.dart';
import 'package:heliolytics/providers/day_bundle_provider.dart';
import 'package:heliolytics/providers/detail_metrics_provider.dart';
import 'package:heliolytics/providers/health_data_refresh_coordinator.dart';
import 'package:heliolytics/widgets/error_view.dart';
import 'package:heliolytics/widgets/stress/stress_day_body.dart';

class StressMonitorScreen extends ConsumerWidget {
  final String dayKey;

  const StressMonitorScreen({super.key, required this.dayKey});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bundleAsync = ref.watch(dayBundleProvider(dayKey));
    // Per-minute stress lives in the lazy detail tier, not the day rollups.
    final detail = ref.watch(detailMetricsProvider(dayKey));

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          HelioTopBar(
            showBack: true,
            onBack: () => context.pop(),
            title: 'Stress Monitor',
            actions: [
              Tooltip(
                message: 'Stress settings',
                child: IconButton(
                  icon: const Icon(Icons.settings_outlined, size: 29),
                  color: HelioColors.textSecondary,
                  onPressed: () => _showSettings(context),
                ),
              ),
            ],
          ),
          Expanded(
            child: bundleAsync.when(
              loading: () => const HelioLoading(),
              error: (e, _) => ErrorView(
                error: e,
                onRetry: () => ref
                    .read(healthDataRefreshCoordinatorProvider)
                    .retryDay(dayKey, details: true),
              ),
              data: (bundle) => detail.when(
                loading: () => const HelioLoading(),
                error: (e, _) => ErrorView(
                  error: e,
                  onRetry: () => ref
                      .read(healthDataRefreshCoordinatorProvider)
                      .retryDay(dayKey, details: true),
                ),
                data: (d) => Column(
                  children: [
                    _dateNavigator(context),
                    Expanded(
                      child: StressDayBody(
                        samples: d.seriesFor(dayKey, 'stress'),
                        sleepEntries: bundle.sleep,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: HelioBottomNav(
        index: 1,
        showTabs: false,
        onChanged: (_) {},
        onOrbTap: () => context.push('/profile/view'),
      ),
    );
  }

  Widget _dateNavigator(BuildContext context) {
    final date = DateTime.parse(dayKey);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: HelioSpacing.lg),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          HelioDateNav(
            label: formatNavDayLabel(dayKey),
            onPrev: () => context.replace(
              '/stress/${dayKeyFor(date.subtract(const Duration(days: 1)))}',
            ),
            onNext: dayKey == todayDayKey()
                ? null
                : () => context.replace(
                    '/stress/${dayKeyFor(date.add(const Duration(days: 1)))}',
                  ),
            canGoNext: dayKey != todayDayKey(),
            onDateTap: () async {
              final selected = await pickDay(context, dayKey: dayKey);
              if (selected != null && context.mounted) {
                context.replace('/stress/$selected');
              }
            },
          ),
        ],
      ),
    );
  }

  void _showSettings(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: HelioColors.surface,
      builder: (_) => Padding(
        padding: const EdgeInsets.all(HelioSpacing.xl),
        child: Text(
          'Stress is shown on a 0-100 scale. Lower readings indicate less physiological activation.',
          style: HelioTypography.body,
        ),
      ),
    );
  }
}
