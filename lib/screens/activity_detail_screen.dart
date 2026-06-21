import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:heliolytics/utils/formatters.dart';
import 'package:heliolytics/utils/sport_icons.dart';
import 'package:heliolytics/utils/sport_labels.dart';
import 'package:heliolytics/design_system/components/helio_surface_card.dart';
import 'package:heliolytics/design_system/components/helio_top_bar.dart';
import 'package:heliolytics/design_system/tokens/helio_colors.dart';
import 'package:heliolytics/design_system/tokens/helio_spacing.dart';
import 'package:heliolytics/design_system/tokens/helio_typography.dart';
import 'package:heliolytics/models/day_metric.dart';
import 'package:heliolytics/models/activity_detail_payload.dart';

class ActivityDetailScreen extends StatelessWidget {
  const ActivityDetailScreen({super.key, this.extra});

  final Object? extra;

  @override
  Widget build(BuildContext context) {
    final payload = extra ?? GoRouterState.of(context).extra;
    if (payload is! ActivityDetailPayload) {
      return Scaffold(
        appBar: HelioTopBar(showBack: true, onBack: () => context.pop()),
        body: const Center(child: Text('Activity data unavailable')),
      );
    }
    final w = payload.workout;
    final s = payload.session;
    if (w != null) return _scaffold(context, _WorkoutView(w));
    if (s != null) return _scaffold(context, _SessionView(s));
    return Scaffold(
      appBar: HelioTopBar(showBack: true, onBack: () => context.pop()),
      body: const Center(child: Text('Activity not found')),
    );
  }

  Widget _scaffold(BuildContext context, _ActivityView view) {
    return Scaffold(
      backgroundColor: HelioColors.canvas,
      appBar: HelioTopBar(
        showBack: true,
        onBack: () => context.pop(),
        title: view.title,
      ),
      body: ListView(
        padding: const EdgeInsets.all(HelioSpacing.lg),
        children: [
          // Hero icon with glow
          Center(
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: HelioColors.strainBlue.withValues(alpha: 0.12),
                shape: BoxShape.circle,
                border: Border.all(
                  color: HelioColors.strainBlue.withValues(alpha: 0.3),
                  width: 1.5,
                ),
              ),
              child: Icon(view.icon, size: 38, color: HelioColors.strainBlue),
            ),
          ),
          const SizedBox(height: HelioSpacing.xl),

          // Stats card
          HelioSurfaceCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                for (int i = 0; i < view.rows.length; i++) ...[
                  if (i > 0)
                    const Divider(height: 1, color: Color(0x14FFFFFF)),
                  _statRow(view.rows[i].$1, view.rows[i].$2),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: HelioSpacing.lg,
        vertical: HelioSpacing.md,
      ),
      child: Row(
        children: [
          Text(label.toUpperCase(), style: HelioTypography.capsLabel),
          const Spacer(),
          Text(
            value,
            style: HelioTypography.body.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

abstract class _ActivityView {
  String get title;
  IconData get icon;
  List<(String, String)> get rows;
}

class _WorkoutView implements _ActivityView {
  _WorkoutView(this.w);
  final WorkoutMetric w;

  @override
  String get title => w.sportName.isNotEmpty ? w.sportName : sportLabel(w.sportType);

  @override
  IconData get icon => sportIcon(w.sportType, name: title);

  @override
  List<(String, String)> get rows => [
        ('Sport', title),
        ('Start', formatWorkoutTime(w.startedAt)),
        ('Duration', formatDurationSec(w.durationSec)),
        if (w.calories != null) ('Calories', '${w.calories} kcal'),
        if (w.avgHr != null) ('Avg HR', '${w.avgHr} bpm'),
        if (w.maxHr != null) ('Max HR', '${w.maxHr} bpm'),
      ];
}

class _SessionView implements _ActivityView {
  _SessionView(this.s);
  final ActivitySessionMetric s;

  @override
  String get title => s.sportName.isNotEmpty ? s.sportName : sportLabel(s.sportType);

  @override
  IconData get icon => sportIcon(s.sportType, name: title);

  @override
  List<(String, String)> get rows => [
        ('Sport', title),
        ('Source', 'Auto-detected'),
        ('Start', formatWorkoutTime(s.startedAt)),
        ('Duration', formatDurationSec(s.durationSec)),
        if (s.calories != null) ('Calories', '${s.calories} kcal'),
        if (s.avgHr != null) ('Avg HR', '${s.avgHr} bpm'),
        if (s.maxHr != null) ('Max HR', '${s.maxHr} bpm'),
      ];
}
