import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:heliolytics/constants/constants.dart';
import 'package:heliolytics/services/cache/daily_bundle_cache_storage.dart';
import 'package:hive/hive.dart';

void main() {
  late Directory directory;
  late Box<String> box;
  late DailyBundleCacheStorage storage;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp(
      'heliolytics-cache-test-',
    );
    Hive.init(directory.path);
    box = await Hive.openBox<String>('bundle-cache');
    storage = DailyBundleCacheStorage(box: box);
  });

  tearDown(() async {
    await box.close();
    await directory.delete(recursive: true);
  });

  test('old bundle cache is purged once and then preserved', () async {
    await box.put('2026-08-01', '{"partial":true}');

    expect(await storage.migrateSchemaIfNeeded(), isTrue);
    expect(box.get('2026-08-01'), isNull);
    expect(
      box.get(dailyBundleCacheSchemaKey),
      dailyBundleCacheSchemaVersion.toString(),
    );

    await box.put('2026-08-02', '{"current":true}');
    expect(await storage.migrateSchemaIfNeeded(), isFalse);
    expect(box.get('2026-08-02'), '{"current":true}');
  });

  test('routine cache clearing preserves the schema marker', () async {
    await storage.migrateSchemaIfNeeded();
    await box.put('2026-08-01', '{"cached":true}');

    await storage.clear();

    expect(box.get('2026-08-01'), isNull);
    expect(await storage.migrateSchemaIfNeeded(), isFalse);
  });
}
