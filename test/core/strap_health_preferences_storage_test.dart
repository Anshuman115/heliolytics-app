import 'package:flutter_test/flutter_test.dart';
import 'package:heliolytics/services/ble/auth/auth_key_store.dart';
import 'package:heliolytics/services/config/strap_health_preferences_storage.dart';

class MemoryKeyStore implements AuthKeyStore {
  final values = <String, String>{};

  @override
  Future<void> write(String key, String value) async => values[key] = value;

  @override
  Future<String?> read(String key) async => values[key];

  @override
  Future<void> delete(String key) async => values.remove(key);
}

void main() {
  test('desired choices stay unset until the user makes one', () async {
    final prefs = StrapHealthPreferencesStorage(MemoryKeyStore());

    final initial = await prefs.load();
    expect(initial.allDay, isNull);
    expect(initial.lowAlert, isNull);

    await prefs.saveAllDay(true);
    await prefs.saveLowAlert(85);
    final saved = await prefs.load();
    expect(saved.allDay, isTrue);
    expect(saved.lowAlert, 85);
  });

  test('off is retained as an explicit choice', () async {
    final prefs = StrapHealthPreferencesStorage(MemoryKeyStore());
    await prefs.saveAllDay(false);
    await prefs.saveLowAlert(0);

    final desired = await prefs.load();
    expect(desired.allDay, isFalse);
    expect(desired.lowAlert, 0);
  });
}
