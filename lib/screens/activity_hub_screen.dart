import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:heliolytics/design_system/components/helio_loading.dart';
import 'package:heliolytics/design_system/components/helio_top_bar.dart';
import 'package:heliolytics/providers/day_bundle_provider.dart';
import 'package:heliolytics/providers/detail_metrics_provider.dart';
import 'package:heliolytics/providers/health_data_refresh_coordinator.dart';
import 'package:heliolytics/providers/selected_day_provider.dart';
import 'package:heliolytics/design_system/tokens/helio_colors.dart';
import 'package:heliolytics/design_system/tokens/helio_spacing.dart';
import 'package:heliolytics/utils/day_key.dart';
import 'package:heliolytics/utils/day_picker.dart';
import 'package:heliolytics/utils/formatters.dart';
import 'package:heliolytics/widgets/activity/activity_overview_body.dart';
import 'package:heliolytics/widgets/error_view.dart';

class ActivityHubScreen extends ConsumerWidget {
  const ActivityHubScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dayKey = ref.watch(selectedDayKeyProvider) ?? todayDayKey();
    final day = ref.watch(dayBundleProvider(dayKey));
    final detail = ref.watch(detailMetricsProvider(dayKey));

    return Column(
      children: [
        HelioTopBar(
          safeTop: false,
          dayLabel: formatNavDayLabel(dayKey),
          onPrevDay: () => shiftSelectedDay(ref, -1),
          onNextDay: dayKey == todayDayKey()
              ? null
              : () => shiftSelectedDay(ref, 1),
          canGoNext: dayKey != todayDayKey(),
          onDateTap: () async {
            final selected = await pickDay(context, dayKey: dayKey);
            if (selected != null) selectDay(ref, selected);
          },
          actions: [
            Tooltip(
              message: 'Strain details',
              child: IconButton(
                icon: const Icon(Icons.info_outline, size: 30),
                color: HelioColors.textSecondary,
                onPressed: () => _showInfo(context),
              ),
            ),
          ],
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () => _refresh(ref, dayKey),
            child: day.when(
              loading: _loading,
              error: (error, _) => _error(ref, error, dayKey),
              data: (bundle) => ActivityOverviewBody(
                bundle: bundle,
                heartRate: detail.valueOrNull?.heartRateFor(dayKey) ?? const [],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _loading() => ListView(
    physics: const AlwaysScrollableScrollPhysics(),
    children: const [SizedBox(height: 160), HelioLoading()],
  );

  Widget _error(WidgetRef ref, Object error, String dayKey) => ListView(
    physics: const AlwaysScrollableScrollPhysics(),
    children: [
      ErrorView(
        error: error,
        onRetry: () => ref
            .read(healthDataRefreshCoordinatorProvider)
            .retryDay(dayKey, details: true),
      ),
    ],
  );

  Future<void> _refresh(WidgetRef ref, String dayKey) async {
    await ref
        .read(healthDataRefreshCoordinatorProvider)
        .refreshDay(dayKey, details: true);
  }

  void _showInfo(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: HelioColors.surface,
      builder: (_) => const Padding(
        padding: EdgeInsets.all(HelioSpacing.xl),
        child: Text(
          'Strain reflects cardiovascular load from elevated heart rate and movement. Use the zone split and weekly pattern together.',
          style: TextStyle(color: HelioColors.textPrimary, fontSize: 16),
        ),
      ),
    );
  }
}
