import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:heliolytics/constants/constants.dart';
import 'package:heliolytics/services/config/band_alerts_call_pattern_storage.dart';
import 'package:heliolytics/utils/app_logger.dart';

class BandAlertsCallPatternNotifier extends Notifier<List<int>> {
  void _log(String msg) =>
      AppLogger.instance.log(msg, tag: 'band_alerts_call_pattern');

  @override
  List<int> build() {
    ref.keepAlive();
    _bootstrap();
    return bandAlertsDefaultCallPatternMs;
  }

  Future<void> _bootstrap() async {
    final loaded =
        await ref.read(bandAlertsCallPatternStorageProvider).load();
    state = List<int>.unmodifiable(loaded);
  }

  Future<void> setPattern(List<int> onOffMs) async {
    final next = List<int>.from(onOffMs);
    await ref.read(bandAlertsCallPatternStorageProvider).save(next);
    state = List<int>.unmodifiable(next);
    _log('call pattern saved (${next.length} items)');
  }

  Future<void> resetToDefault() async {
    await setPattern(bandAlertsDefaultCallPatternMs);
  }
}

final bandAlertsCallPatternProvider =
    NotifierProvider<BandAlertsCallPatternNotifier, List<int>>(
  BandAlertsCallPatternNotifier.new,
);
