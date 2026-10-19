import 'package:flutter_test/flutter_test.dart';
import 'package:heliolytics/models/session_catalog.dart';
import 'package:heliolytics/models/strap_health_config.dart';
import 'package:heliolytics/services/ble/health_config_catalog.dart';

void main() {
  test('catalog freezes actual state and omits unverified state', () {
    const base = SessionCatalog(
      sessionId: 'session-a',
      chunked: [],
      unsolicited: [],
    );
    const actual = HealthConfigSnapshot(
      version: 3,
      spo2AllDay: false,
      spo2LowAlert: 0,
      sleepBreathing: true,
    );
    final frozen = catalogWithHealthConfig(base, actual);
    final json = frozen.toJson();

    final later = catalogWithHealthConfig(
      base,
      const HealthConfigSnapshot(
        version: 3,
        spo2AllDay: true,
        sleepBreathing: true,
        spo2LowAlert: 0,
      ),
    );

    expect(json['strapConfig'], {
      'spo2AllDay': false,
      'spo2LowAlert': 0,
      'sleepBreathing': true,
      'version': 3,
    });
    expect(
      catalogWithHealthConfig(base, null).toJson().containsKey('strapConfig'),
      isFalse,
    );
    expect(later.toJson()['strapConfig']['spo2AllDay'], isTrue);
    expect(
      frozen.toJson(),
      json,
      reason: 'Later observations cannot mutate a previous upload/retry',
    );
  });

  test('round trip keeps nullable actual fields distinct from false', () {
    const catalog = SessionCatalog(
      sessionId: 'session-b',
      chunked: [],
      unsolicited: [],
      strapConfig: HealthConfigSnapshot(
        version: 4,
        spo2AllDay: null,
        spo2LowAlert: null,
        sleepBreathing: false,
      ),
    );
    final restored = SessionCatalog.fromJson(catalog.toJson());
    expect(restored.strapConfig!.spo2AllDay, isNull);
    expect(restored.strapConfig!.sleepBreathing, isFalse);
    expect(restored.strapConfig!.spo2LowAlert, isNull);
    expect(restored.strapConfig!.version, 4);
  });
}
