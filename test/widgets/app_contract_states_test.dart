import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:heliolytics/models/day_bundle.dart';
import 'package:heliolytics/models/day_metric.dart';
import 'package:heliolytics/providers/day_bundle_provider.dart';
import 'package:heliolytics/services/network/metrics_api_transport.dart';
import 'package:heliolytics/widgets/error_view.dart';

const _dayKey = '2026-08-01';

void main() {
  testWidgets('an error bundle shows the failure and a retry, not zero steps', (
    tester,
  ) async {
    final container = _container(
      (ref, key) async => throw const MetricsApiException(
        type: MetricsApiFailureType.serverError,
        path: '/api/v1/daily-metrics',
        statusCode: 500,
      ),
    );

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: _Probe(dayKey: _dayKey)),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(ErrorView), findsOneWidget);
    expect(find.text('0'), findsNothing);
  });

  testWidgets('an unconfigured API is reported as configuration, not data', (
    tester,
  ) async {
    final container = _container(
      (ref, key) async => throw const MetricsApiException(
        type: MetricsApiFailureType.notConfigured,
        path: '/api/v1/daily-metrics',
        message: 'Configure Cloud API in Settings before syncing.',
      ),
    );

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: _Probe(dayKey: _dayKey)),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.textContaining('Configure Cloud API in Settings'),
      findsOneWidget,
    );
    expect(find.byType(ErrorView), findsOneWidget);
  });

  testWidgets('a valid empty bundle is shown as no data', (tester) async {
    final container = _container((ref, key) async => const DayBundle());

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: _Probe(dayKey: _dayKey)),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('NO DATA'), findsOneWidget);
    expect(find.byType(ErrorView), findsNothing);
  });

  testWidgets('a day with metrics renders values and not the empty state', (
    tester,
  ) async {
    final container = _container(
      (ref, key) async => DayBundle(
        day: DayMetric(
          dayKey: key,
          updatedAt: DateTime.utc(2026, 8, 2),
          steps: 4321,
          avgHr: 61.4,
        ),
      ),
    );

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: _Probe(dayKey: _dayKey)),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('4321'), findsOneWidget);
    expect(find.text('NO DATA'), findsNothing);
  });
}

ProviderContainer _container(
  Future<DayBundle> Function(Ref ref, String key) load,
) {
  return ProviderContainer(
    overrides: [dayBundleProvider.overrideWith((ref, key) => load(ref, key))],
  );
}

class _Probe extends ConsumerWidget {
  const _Probe({required this.dayKey});

  final String dayKey;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bundle = ref.watch(dayBundleProvider(dayKey));
    return bundle.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => ErrorView(error: error, onRetry: () {}),
      data: (data) => Center(
        child: Text(data.day == null ? 'NO DATA' : '${data.day!.steps}'),
      ),
    );
  }
}
