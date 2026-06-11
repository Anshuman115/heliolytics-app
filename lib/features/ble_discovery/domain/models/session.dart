import 'package:heliolytics/features/ble_discovery/domain/models/dump_entry.dart';
import 'package:heliolytics/features/ble_discovery/domain/models/session_mode.dart';
import 'package:heliolytics/features/ble_discovery/domain/models/unsolicited_entry.dart';

class Session {
  final String sessionId;
  final DateTime startedAt;
  final DateTime? endedAt;
  final String? deviceMac;
  final int fetchWindowHours, listenDurationSec;
  final SessionMode mode;
  final List<DumpEntry> entries;
  final List<UnsolicitedEntry> unsolicited;
  final int? batteryPercent;

  const Session({
    required this.sessionId,
    required this.startedAt,
    this.endedAt,
    this.deviceMac,
    required this.fetchWindowHours,
    required this.listenDurationSec,
    required this.mode,
    required this.entries,
    required this.unsolicited,
    this.batteryPercent,
  });

  Map<String, dynamic> toJson() => {
        'schemaVersion': 1,
        'sessionId': sessionId,
        'startedAt': startedAt.toIso8601String(),
        if (endedAt != null) 'endedAt': endedAt!.toIso8601String(),
        if (deviceMac != null) 'deviceMac': deviceMac,
        'fetchWindowHours': fetchWindowHours,
        'listenDurationSec': listenDurationSec,
        'mode': mode.label,
        if (batteryPercent != null) 'batteryPercent': batteryPercent,
      };

  factory Session.fromJson(Map<String, dynamic> j) => Session(
        sessionId: j['sessionId'] as String,
        startedAt: DateTime.parse(j['startedAt'] as String),
        endedAt: j['endedAt'] != null
            ? DateTime.parse(j['endedAt'] as String)
            : null,
        deviceMac: j['deviceMac'] as String?,
        fetchWindowHours: (j['fetchWindowHours'] as num).toInt(),
        listenDurationSec: (j['listenDurationSec'] as num).toInt(),
        mode: SessionModeX.parse(j['mode'] as String),
        entries: (j['entries'] as List<dynamic>? ?? [])
            .map((e) => DumpEntry.fromJson(e as Map<String, dynamic>))
            .toList(),
        unsolicited: (j['unsolicited'] as List<dynamic>? ?? [])
            .map((e) => UnsolicitedEntry.fromJson(e as Map<String, dynamic>))
            .toList(),
        batteryPercent: (j['batteryPercent'] as num?)?.toInt(),
      );
}
