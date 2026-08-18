import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:heliolytics/design_system/components/helio_empty_state.dart';
import 'package:heliolytics/design_system/components/helio_bottom_nav.dart';
import 'package:heliolytics/design_system/components/helio_loading.dart';
import 'package:heliolytics/design_system/components/helio_top_bar.dart';
import 'package:heliolytics/constants/constants.dart';
import 'package:heliolytics/design_system/tokens/helio_colors.dart';
import 'package:heliolytics/design_system/tokens/helio_spacing.dart';
import 'package:heliolytics/design_system/tokens/helio_typography.dart';
import 'package:heliolytics/models/day_bundle.dart';
import 'package:heliolytics/models/metric_catalog.dart';
import 'package:heliolytics/providers/day_bundle_provider.dart';
import 'package:heliolytics/providers/detail_metrics_provider.dart';
import 'package:heliolytics/providers/health_data_refresh_coordinator.dart';
import 'package:heliolytics/utils/day_key.dart';
import 'package:heliolytics/utils/day_picker.dart';
import 'package:heliolytics/utils/formatters.dart';
import 'package:heliolytics/widgets/metric_detail_body.dart';
import 'package:heliolytics/widgets/metric_detail_hero.dart';
import 'package:heliolytics/widgets/metric_trend_header.dart';
import 'package:heliolytics/widgets/metric_trend_section.dart';
import 'package:heliolytics/widgets/sleep_hero.dart';

class MetricDetailScreen extends ConsumerWidget {
  final String dayKey;
  final String metricId;

  const MetricDetailScreen({
    super.key,
    required this.dayKey,
    required this.metricId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final definition = MetricCatalog.byId(metricId);
    if (definition == null) return _unknown(context);

    final bundle = ref.watch(dayBundleProvider(dayKey));
    final detail =
        ref.watch(detailMetricsProvider(dayKey)).valueOrNull ??
        const DetailMetrics();
    return bundle.when(
      loading: () =>
          Scaffold(appBar: _topBar(context), body: const HelioLoading()),
      error: (error, _) => Scaffold(
        appBar: _topBar(context),
        body: HelioEmptyState(
          icon: Icons.error_outline,
          title: 'Failed to load',
          message: error.toString(),
          actionLabel: 'Retry',
          onAction: () => ref
              .read(healthDataRefreshCoordinatorProvider)
              .retryDay(dayKey, details: true, trends: true),
        ),
      ),
      data: (data) => _loaded(context, definition, data, detail),
    );
  }

  Widget _loaded(
    BuildContext context,
    MetricDef definition,
    DayBundle bundle,
    DetailMetrics detail,
  ) {
    final day = bundle.day;
    final trendFirst = _trendFirst(definition.id);
    final showRing = const {
      'readiness',
      'sleep',
      'pai',
    }.contains(definition.id);
    return Scaffold(
      appBar: HelioTopBar(
        showBack: true,
        onBack: () => context.pop(),
        dayLabel: formatNavDayLabel(dayKey),
        onPrevDay: () => _openDay(context, -1),
        onNextDay: () => _openDay(context, 1),
        canGoNext: dayKey != todayDayKey(),
        onDateTap: () => _pickDay(context),
        actions: [
          Tooltip(
            message: definition.title,
            child: IconButton(
              icon: const Icon(Icons.info_outline, size: 30),
              color: HelioColors.textSecondary,
              onPressed: () => _showInfo(context, definition),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          HelioSpacing.lg,
          0,
          HelioSpacing.lg,
          shellContentBottomPadding,
        ),
        children: [
          if (trendFirst) ...[
            MetricTrendHeader(definition: definition),
            const SizedBox(height: HelioSpacing.xl),
            MetricTrendSection(definition: definition, anchorDayKey: dayKey),
            const SizedBox(height: HelioSpacing.xxl),
            Text(
              "DAY'S READINGS · ${formatDayLabel(dayKey)}".toUpperCase(),
              style: HelioTypography.sectionTitle,
            ),
            const SizedBox(height: HelioSpacing.md),
          ] else if (definition.id == 'sleep') ...[
            SleepHero(
              bundle: bundle,
              stressSamples: detail.seriesFor(dayKey, 'stress'),
            ),
            const SizedBox(height: HelioSpacing.xxl),
          ] else if (showRing) ...[
            MetricDetailHero(definition: definition, day: day),
            const SizedBox(height: HelioSpacing.lg),
          ],
          MetricDetailBody(
            definition: definition,
            bundle: bundle,
            detail: detail,
            dayKey: dayKey,
          ),
          if (!trendFirst && _supportsTrend(definition.id)) ...[
            const SizedBox(height: HelioSpacing.xxl),
            MetricTrendSection(definition: definition, anchorDayKey: dayKey),
          ],
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

  bool _trendFirst(String id) => const {
    'hrv',
    'rhr',
    'resp_rate',
    'spo2',
    'spo2_sleep',
    'temperature',
    'calories',
  }.contains(id);

  bool _supportsTrend(String id) => const {
    'readiness',
    'sleep',
    'stress',
    'hrv',
    'rhr',
    'spo2',
    'spo2_sleep',
    'resp_rate',
    'temperature',
    'pai',
    'steps',
    'calories',
  }.contains(id);

  void _openDay(BuildContext context, int delta) {
    final date = DateTime.parse(dayKey).add(Duration(days: delta));
    context.replace('/metric/${dayKeyFor(date)}/$metricId');
  }

  Future<void> _pickDay(BuildContext context) async {
    final selected = await pickDay(context, dayKey: dayKey);
    if (selected != null && context.mounted) {
      context.replace('/metric/$selected/$metricId');
    }
  }

  void _showInfo(BuildContext context, MetricDef definition) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: HelioColors.surface,
      builder: (_) => Padding(
        padding: const EdgeInsets.all(HelioSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(definition.title, style: HelioTypography.scoreMedium),
            const SizedBox(height: HelioSpacing.md),
            Text(definition.detail, style: HelioTypography.bodyMuted),
            const SizedBox(height: HelioSpacing.lg),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _topBar(BuildContext context) =>
      HelioTopBar(showBack: true, onBack: () => context.pop());

  Widget _unknown(BuildContext context) => Scaffold(
    appBar: _topBar(context),
    body: const Center(child: Text('Unknown metric')),
  );
}
