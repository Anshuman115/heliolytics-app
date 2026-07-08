import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:heliolytics/constants/constants.dart';
import 'package:heliolytics/services/config/band_alerts_app_patterns_storage.dart';
import 'package:heliolytics/utils/app_logger.dart';

class BandAlertsAppPatternsNotifier
    extends Notifier<Map<String, List<int>>> {
  void _log(String msg) =>
      AppLogger.instance.log(msg, tag: 'band_alerts_patterns');

  @override
  Map<String, List<int>> build() {
    ref.keepAlive();
    _bootstrap();
    return const {};
  }

  Future<void> _bootstrap() async {
    final storage = ref.read(bandAlertsAppPatternsStorageProvider);
    final loaded = await storage.load();
    state = Map<String, List<int>>.unmodifiable(loaded);
  }

  List<int> patternFor(String packageId) {
    final p = state[packageId];
    if (p == null || p.isEmpty) return bandAlertsDefaultAppPatternMs;
    return p;
  }

  Future<void> setPattern(String packageId, List<int> onOffMs) async {
    final next = Map<String, List<int>>.from(state);
    next[packageId] = List<int>.from(onOffMs);
    await ref.read(bandAlertsAppPatternsStorageProvider).save(next);
    state = Map<String, List<int>>.unmodifiable(next);
    _log('pattern saved $packageId (${onOffMs.length} items)');
  }

  Future<void> clearPattern(String packageId) async {
    final next = Map<String, List<int>>.from(state);
    next.remove(packageId);
    await ref.read(bandAlertsAppPatternsStorageProvider).save(next);
    state = Map<String, List<int>>.unmodifiable(next);
    _log('pattern cleared $packageId');
  }
}

final bandAlertsAppPatternsProvider = NotifierProvider<
    BandAlertsAppPatternsNotifier, Map<String, List<int>>>(
  BandAlertsAppPatternsNotifier.new,
);

