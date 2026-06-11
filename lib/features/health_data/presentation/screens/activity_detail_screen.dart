import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/sport_icons.dart';
import '../../../../core/utils/sport_labels.dart';
import '../../domain/entities/day_metric.dart';

class ActivityDetailPayload {
  const ActivityDetailPayload.workout(this.workout) : session = null;
  const ActivityDetailPayload.session(this.session) : workout = null;

  final WorkoutMetric? workout;
  final ActivitySessionMetric? session;
}

class ActivityDetailScreen extends StatelessWidget {
  const ActivityDetailScreen({super.key, this.extra});

  final Object? extra;

  @override
  Widget build(BuildContext context) {
    final payload = extra ?? GoRouterState.of(context).extra;
    if (payload is! ActivityDetailPayload) {
      return Scaffold(
        appBar: AppBar(title: const Text('Activity')),
        body: const Center(child: Text('Activity data unavailable')),
      );
    }
    final w = payload.workout;
    final s = payload.session;
    if (w != null) return _body(context, _WorkoutView(w));
    if (s != null) return _body(context, _SessionView(s));
    return Scaffold(
      appBar: AppBar(title: const Text('Activity')),
      body: const Center(child: Text('Activity not found')),
    );
  }

  Widget _body(BuildContext context, _ActivityView view) {
    return Scaffold(
      appBar: AppBar(title: Text(view.title)),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          Icon(view.icon, size: 48, color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: AppSpacing.md),
          ...view.rows.map((r) => _row(context, r.$1, r.$2)),
        ],
      ),
    );
  }

  Widget _row(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(label, style: Theme.of(context).textTheme.labelMedium),
          ),
          Expanded(child: Text(value)),
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
        ('Type ID', '${w.sportType}'),
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
        ('Type ID', '${s.sportType}'),
        ('Source', 'Auto-detected'),
        ('Start', formatWorkoutTime(s.startedAt)),
        ('Duration', formatDurationSec(s.durationSec)),
        if (s.calories != null) ('Calories', '${s.calories} kcal'),
        if (s.avgHr != null) ('Avg HR', '${s.avgHr} bpm'),
        if (s.maxHr != null) ('Max HR', '${s.maxHr} bpm'),
      ];
}
