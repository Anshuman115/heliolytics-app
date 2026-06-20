import 'dart:typed_data';

import 'package:heliolytics/services/ble/sync_page_anchor.dart';

typedef TypeFetchResult = ({
  Uint8List raw,
  int expected,
  bool skipped,
  DateTime? roundStart,
  List<SyncPageAnchor> roundSegments,
});

abstract class BandLinkPort {
  Future<bool> connectAndAuth({
    required String mac,
    required Uint8List authKey,
  });

  Future<TypeFetchResult> fetchCode(int code, DateTime since);

  Future<void> startLiveHeartRate();

  Future<void> stopLiveHeartRate();

  Stream<int>? get liveBpmStream;

  bool get isLiveHeartRateActive;

  Future<void> disconnect();

  int? get batteryPercent;
}
