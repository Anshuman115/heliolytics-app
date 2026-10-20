import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:heliolytics/models/day_bundle.dart';
import 'package:heliolytics/models/day_metric.dart';
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

  test('a written bundle reads back', () async {
    final bundle = DayBundle(
      day: DayMetric(dayKey: '2026-08-01', updatedAt: DateTime.utc(2026, 8, 2)),
    );

    await storage.write('2026-08-01', bundle);

    final loaded = await storage.read('2026-08-01');
    expect(loaded?.day?.dayKey, '2026-08-01');
    expect((await storage.readAllCachedDays()).single.dayKey, '2026-08-01');
  });

  test('an undecodable entry is a cache miss', () async {
    await box.put('2026-08-01', 'not json');

    expect(await storage.read('2026-08-01'), isNull);
    expect(await storage.readAllCachedDays(), isEmpty);
  });

  test('clear drops every entry', () async {
    await box.put('2026-08-01', 'not json');

    await storage.clear();

    expect(box.isEmpty, isTrue);
  });
}
