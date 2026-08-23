import 'package:hive_flutter/hive_flutter.dart';
import 'package:heliolytics/constants/constants.dart';

typedef CacheBoxOpen = Future<void> Function();
typedef CacheBoxDelete = Future<void> Function();

Future<bool> ensureDailyBundleCacheBox({
  CacheBoxOpen? openBox,
  CacheBoxDelete? deleteBox,
  void Function(String)? log,
}) async {
  final open =
      openBox ??
      () async {
        await Hive.openBox<String>(cachedDaysBoxName);
      };
  final delete = deleteBox ?? () => Hive.deleteBoxFromDisk(cachedDaysBoxName);
  try {
    await open();
    return true;
  } catch (error) {
    log?.call('Metrics cache open failed: $error');
  }

  try {
    await delete();
    await open();
    log?.call('Metrics cache recreated');
    return true;
  } catch (error) {
    log?.call('Metrics cache disabled for this launch: $error');
    return false;
  }
}
