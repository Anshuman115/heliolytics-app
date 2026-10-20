import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:heliolytics/models/user_profile.dart';
import 'package:heliolytics/screens/profile_screen.dart';
import 'package:heliolytics/services/ble/auth/auth_key_storage.dart';
import 'package:heliolytics/services/ble/auth/auth_key_store.dart';

void main() {
  test('an empty profile sends every nullable key', () {
    final wire = const UserProfile().toWireJson();
    expect(wire.keys.toSet(), {
      'name',
      'birthDate',
      'sex',
      'heightCm',
      'weightKg',
    });
    expect(wire.values.every((v) => v == null), isTrue);
  });

  test('clearing fields sends nulls, never a synthesized age', () {
    final filled = UserProfile(
      name: 'Ada',
      birthDate: DateTime(1995, 4, 12),
      sex: UserProfile.female,
      heightCm: 171.5,
      weightKg: 62,
    );
    final cleared = filled.copyWith(
      clearName: true,
      clearBirthDate: true,
      clearSex: true,
      clearHeight: true,
      clearWeight: true,
    );
    expect(cleared.toWireJson().values.every((v) => v == null), isTrue);
    expect(filled.toWireJson().containsKey('age'), isFalse);
  });

  test('birth date validation rejects rollover and future dates', () {
    expect(birthDateError('1995-04-12'), isNull);
    expect(birthDateError('2000-02-29'), isNull);
    expect(birthDateError('2026-02-30'), isNotNull);
    expect(birthDateError('2026-13-01'), isNotNull);
    expect(birthDateError('12-04-1995'), isNotNull);
    expect(birthDateError('1800-01-01'), isNotNull);
    final future = DateTime.now().add(const Duration(days: 2));
    expect(birthDateError(formatDateOnly(future)), isNotNull);
    expect(birthDateError(''), isNull);
  });

  test('a valid birth date round-trips as a date-only string', () {
    final wire = UserProfile(
      birthDate: parseDateOnly('1995-04-12'),
    ).toWireJson();
    expect(wire['birthDate'], '1995-04-12');
    expect(UserProfile.fromJson(wire).birthDate, DateTime(1995, 4, 12));
  });

  testWidgets('the profile form labels every field optional', (tester) async {
    final container = ProviderContainer(
      overrides: [authKeyStoreProvider.overrideWithValue(_MemoryStore())],
    );
    addTearDown(container.dispose);
    tester.view.physicalSize = const Size(1000, 2000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: ProfileScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('NAME (OPTIONAL)'), findsOneWidget);
    expect(find.text('BIRTH DATE (OPTIONAL)'), findsOneWidget);
    expect(find.text('HEIGHT IN CM (OPTIONAL)'), findsOneWidget);
    expect(find.text('WEIGHT IN KG (OPTIONAL)'), findsOneWidget);
    expect(find.text('Not set'), findsOneWidget);
    expect(
      find.textContaining('Banister training-load estimate stays unavailable'),
      findsOneWidget,
    );
  });
}

class _MemoryStore implements AuthKeyStore {
  final Map<String, String> values = {};

  @override
  Future<void> delete(String key) async => values.remove(key);

  @override
  Future<String?> read(String key) async => values[key];

  @override
  Future<void> write(String key, String value) async => values[key] = value;
}
