import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:heliolytics/models/strap_health_config.dart';
import 'package:heliolytics/providers/strap_health_config_provider.dart';
import 'package:heliolytics/services/ble/zepp/health_config_service.dart';
import 'package:heliolytics/widgets/settings/strap_health_card.dart';

import '../core/health_config_service_test.dart' show FakeHealthPort, response;

class UiNotifier extends StrapHealthConfigNotifier {
  final StrapHealthConfigState initial;
  final allDayChanges = <bool>[];
  final lowAlertChanges = <int>[];
  var reads = 0;
  UiNotifier(this.initial);
  @override
  StrapHealthConfigState build() => initial;
  @override
  Future<void> load() async => reads++;
  @override
  Future<void> setAllDay(bool on) async {
    allDayChanges.add(on);
    state = state.copyWith(
      desired: StrapHealthDesiredState(
        allDay: on,
        lowAlert: state.desired.lowAlert,
      ),
    );
  }

  @override
  Future<void> setLowAlert(int value) async {
    lowAlertChanges.add(value);
  }
}

StrapHealthConfigState uiState({
  bool? allDay = true,
  int? low = 0,
  bool hasConfig = true,
  StrapHealthDesiredState desired = const StrapHealthDesiredState(),
  StrapHealthConfigPhase phase = StrapHealthConfigPhase.ready,
  String? error,
}) => StrapHealthConfigState(
  phase: phase,
  config: hasConfig
      ? HealthConfigSnapshot(
          version: 3,
          spo2AllDay: allDay,
          sleepBreathing: false,
          spo2LowAlert: low,
        )
      : null,
  desired: desired,
  error: error,
);

Future<void> showCard(WidgetTester tester, UiNotifier notifier) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [strapHealthConfigProvider.overrideWith(() => notifier)],
      child: const MaterialApp(
        home: Scaffold(body: SingleChildScrollView(child: StrapHealthCard())),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Finder allDaySwitch() =>
    find.widgetWithText(SwitchListTile, 'All-day blood oxygen');
Finder alertDropdown() => find.byType(DropdownButtonFormField<int>);

void main() {
  testWidgets(
    'card shows the all-day switch and Off/80/85/90 low-alert choices',
    (tester) async {
      final actual = await HealthConfigService(
        log: (_) {},
      ).read(FakeHealthPort([response(low: 0)]));
      expect(actual.spo2AllDay, isTrue);
      expect(actual.spo2LowAlert, 0);
      final notifier = UiNotifier(
        StrapHealthConfigState(
          phase: StrapHealthConfigPhase.ready,
          config: actual,
        ),
      );
      await showCard(tester, notifier);
      expect(find.text('Strap health'), findsOneWidget);
      expect(find.text('All-day blood oxygen'), findsOneWidget);
      expect(
        find.textContaining(
          'The app sends your choice when the strap connects',
        ),
        findsOneWidget,
      );
      final selector = tester.widget<DropdownButton<int>>(
        find.byType(DropdownButton<int>),
      );
      expect(selector.items!.map((item) => item.value), [0, 80, 85, 90]);
      expect(selector.items!.map((item) => (item.child as Text).data), [
        'Off',
        '80%',
        '85%',
        '90%',
      ]);
      expect(
        tester.widget<DropdownButtonFormField<int>>(alertDropdown()).onChanged,
        isNotNull,
      );
      expect(find.textContaining('Save'), findsNothing);
      expect(find.textContaining('Apply'), findsNothing);
      expect(find.textContaining('require all-day'), findsNothing);
      expect(notifier.allDayChanges, isEmpty);
      expect(notifier.lowAlertChanges, isEmpty);
    },
  );

  testWidgets('choosing 85 calls setLowAlert(85) once', (tester) async {
    final notifier = UiNotifier(uiState());
    await showCard(tester, notifier);
    await tester.tap(alertDropdown());
    await tester.pumpAndSettle();
    await tester.tap(find.text('85%').last);
    await tester.pumpAndSettle();
    expect(notifier.lowAlertChanges, [85]);
    expect(notifier.allDayChanges, isEmpty);
  });

  testWidgets('choosing Off calls setLowAlert(0) once', (tester) async {
    final notifier = UiNotifier(uiState(low: 85));
    await showCard(tester, notifier);
    await tester.tap(alertDropdown());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Off').last);
    await tester.pumpAndSettle();
    expect(notifier.lowAlertChanges, [0]);
    expect(notifier.allDayChanges, isEmpty);
  });

  testWidgets('choosing low alert works while all-day is off', (tester) async {
    final notifier = UiNotifier(uiState(allDay: false));
    await showCard(tester, notifier);
    await tester.tap(alertDropdown());
    await tester.pumpAndSettle();
    await tester.tap(find.text('80%').last);
    await tester.pumpAndSettle();
    expect(notifier.lowAlertChanges, [80]);
    expect(notifier.allDayChanges, isEmpty);
    expect(
      tester.widget<DropdownButtonFormField<int>>(alertDropdown()).onChanged,
      isNotNull,
    );
  });

  testWidgets('no actual state disables both controls and shows the error', (
    tester,
  ) async {
    final notifier = UiNotifier(
      uiState(
        hasConfig: false,
        phase: StrapHealthConfigPhase.error,
        error: 'Strap disconnected.',
      ),
    );
    await showCard(tester, notifier);
    expect(tester.widget<SwitchListTile>(allDaySwitch()).onChanged, isNull);
    expect(
      tester.widget<DropdownButtonFormField<int>>(alertDropdown()).onChanged,
      isNull,
    );
    expect(find.text('Strap disconnected.'), findsOneWidget);
    expect(find.textContaining('Your choice: not set'), findsNWidgets(2));
    expect(find.textContaining('· unknown'), findsNWidgets(2));
    expect(notifier.allDayChanges, isEmpty);
    expect(notifier.lowAlertChanges, isEmpty);
  });

  testWidgets(
    'applying disables controls even with previously valid actual values',
    (tester) async {
      final notifier = UiNotifier(
        uiState(phase: StrapHealthConfigPhase.applying, low: 85),
      );
      await showCard(tester, notifier);
      expect(tester.widget<SwitchListTile>(allDaySwitch()).onChanged, isNull);
      expect(
        tester.widget<DropdownButtonFormField<int>>(alertDropdown()).onChanged,
        isNull,
      );
      expect(find.textContaining('· applying'), findsNWidgets(2));
      expect(notifier.allDayChanges, isEmpty);
      expect(notifier.lowAlertChanges, isEmpty);
    },
  );

  testWidgets('saved choice and different actual value show mismatch', (
    tester,
  ) async {
    final notifier = UiNotifier(
      uiState(
        allDay: false,
        low: 90,
        desired: const StrapHealthDesiredState(allDay: true, lowAlert: 85),
      ),
    );
    await showCard(tester, notifier);
    expect(
      find.text('Your choice: on · mismatch · strap reports off'),
      findsOneWidget,
    );
    expect(
      find.text('Your choice: 85% · mismatch · strap reports 90%'),
      findsOneWidget,
    );
    expect(notifier.allDayChanges, isEmpty);
    expect(notifier.lowAlertChanges, isEmpty);
  });

  testWidgets('out-of-list actual value stays visible on mismatch', (
    tester,
  ) async {
    final notifier = UiNotifier(
      uiState(low: 75, desired: const StrapHealthDesiredState(lowAlert: 85)),
    );
    await showCard(tester, notifier);
    expect(
      find.text('Your choice: 85% · mismatch · strap reports 75%'),
      findsOneWidget,
    );
    expect(find.textContaining('mismatch · strap reports 75%'), findsOneWidget);
    expect(
      tester.widget<DropdownButtonFormField<int>>(alertDropdown()).initialValue,
      isNull,
    );
    expect(notifier.lowAlertChanges, isEmpty);
    expect(notifier.allDayChanges, isEmpty);
  });

  testWidgets('reported low alert outside the choices is shown as a number', (
    tester,
  ) async {
    final notifier = UiNotifier(uiState(low: 75));
    await showCard(tester, notifier);
    expect(
      tester.widget<DropdownButtonFormField<int>>(alertDropdown()).initialValue,
      isNull,
    );
    expect(
      find.text('Your choice: not set · strap reports 75%'),
      findsOneWidget,
    );
    expect(notifier.lowAlertChanges, isEmpty);
  });
}
