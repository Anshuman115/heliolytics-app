import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:heliolytics/models/activity_detail_payload.dart';
import 'package:heliolytics/models/activity_metric.dart';
import 'package:heliolytics/providers/detail_metrics_provider.dart';
import 'package:heliolytics/screens/activity_detail_screen.dart';

ActivityMetric _activity({
  bool hasDetail = true,
  int? minHr = 58,
  int? steps = 5400,
  int? calories = 320,
}) => ActivityMetric(
  kind: ActivityKind.workout,
  dayKey: '2026-08-01',
  startedAt: DateTime.utc(2026, 8, 1, 6),
  endedAt: DateTime.utc(2026, 8, 1, 6, 45),
  durationSec: 2700,
  sportType: 1,
  sportName: 'Outdoor Run',
  hasDetail: hasDetail,
  calories: calories,
  avgHr: 142,
  maxHr: 171,
  minHr: minHr,
  steps: steps,
);

Future<void> _pump(WidgetTester tester, ActivityMetric activity) async {
  final container = ProviderContainer(
    overrides: [
      detailMetricsProvider.overrideWith(
        (ref, key) async => const DetailMetrics(),
      ),
    ],
  );
  addTearDown(container.dispose);
  tester.view.physicalSize = const Size(1200, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        home: ActivityDetailScreen(extra: ActivityDetailPayload(activity)),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('renders every supplied statistic for a workout', (tester) async {
    await _pump(tester, _activity());

    expect(find.text('142'), findsOneWidget);
    expect(find.text('45:00'), findsOneWidget);
    expect(find.text('MIN HR'), findsOneWidget);
    expect(find.text('STEPS'), findsOneWidget);
    expect(find.text('CALORIES'), findsOneWidget);
    expect(
      find.text('No recorded workout detail for this activity.'),
      findsNothing,
    );
  });

  testWidgets('missing statistics stay absent instead of showing zero', (
    tester,
  ) async {
    await _pump(
      tester,
      _activity(hasDetail: false, minHr: null, steps: null, calories: null),
    );

    expect(find.text('MIN HR'), findsNothing);
    expect(find.text('STEPS'), findsNothing);
    expect(find.text('CALORIES'), findsNothing);
    expect(
      find.text('No recorded workout detail for this activity.'),
      findsOneWidget,
    );
    expect(find.text('0'), findsNothing);
  });

  testWidgets('an auto activity keeps its kind label', (tester) async {
    final auto = ActivityMetric(
      kind: ActivityKind.auto,
      dayKey: '2026-08-01',
      startedAt: DateTime.utc(2026, 8, 1, 9),
      endedAt: DateTime.utc(2026, 8, 1, 9, 30),
      durationSec: 1800,
      sportType: 0,
      sportName: 'Walk',
      hasDetail: false,
      steps: 2100,
    );
    await _pump(tester, auto);

    expect(find.textContaining('Auto-detected'), findsOneWidget);
    expect(find.text('2100'), findsOneWidget);
  });
}
