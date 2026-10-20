import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:heliolytics/models/strap_health_config.dart';
import 'package:heliolytics/services/ble/auth/auth_key_store.dart';
import 'package:heliolytics/services/ble/auth/auth_key_storage.dart';

/// Saved health choices for the single strap this install uses.
class StrapHealthPreferencesStorage {
  static const _allDayKey = 'heliolytics.strap_health.all_day';
  static const _lowAlertKey = 'heliolytics.strap_health.low_alert';

  final AuthKeyStore store;

  const StrapHealthPreferencesStorage(this.store);

  Future<StrapHealthDesiredState> load() async {
    final allDay = await store.read(_allDayKey);
    final lowAlert = await store.read(_lowAlertKey);
    return StrapHealthDesiredState(
      allDay: allDay == null ? null : allDay == '1',
      lowAlert: lowAlert == null ? null : int.tryParse(lowAlert),
    );
  }

  Future<void> saveAllDay(bool value) =>
      store.write(_allDayKey, value ? '1' : '0');

  Future<void> saveLowAlert(int value) => store.write(_lowAlertKey, '$value');
}

final strapHealthPreferencesStorageProvider =
    Provider<StrapHealthPreferencesStorage>((ref) {
      return StrapHealthPreferencesStorage(ref.watch(authKeyStoreProvider));
    });
