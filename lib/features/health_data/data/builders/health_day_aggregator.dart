import 'package:heliolytics/core/ble/parsers/activity.dart';
import 'package:heliolytics/core/ble/parsers/stress.dart';
import 'package:heliolytics/core/ble/parsers/temperature.dart';
import 'package:heliolytics/core/utils/ist_time.dart';
import 'package:heliolytics/features/ble_discovery/data/session_store.dart';
import 'package:heliolytics/features/ble_discovery/domain/models/dump_entry.dart';
import 'package:heliolytics/features/health_data/domain/entities/day_health_row.dart';

class HealthDayAggregator {
  final SessionStore store;
  HealthDayAggregator(this.store);

  Future<Map<String, DayHealthRow>> build(
    String sessionId,
    List<DumpEntry> entries,
    DateTime cutoff,
  ) async {
    final acc = <String, _DayAcc>{};
    await _activity(sessionId, entries, cutoff, acc);
    await _stress(sessionId, entries, cutoff, acc);
    await _temperature(sessionId, entries, cutoff, acc);
    return {for (final e in acc.entries) e.key: e.value.toRow(e.key)};
  }

  DumpEntry? _find(List<DumpEntry> entries, String code) {
    for (final e in entries) {
      if (e.code.toLowerCase() == code) return e;
    }
    return null;
  }

  Future<void> _activity(
    String sessionId,
    List<DumpEntry> entries,
    DateTime cutoff,
    Map<String, _DayAcc> acc,
  ) async {
    final entry = _find(entries, '0x01');
    if (entry == null) return;
    final raw = await store.readTypeBytes(sessionId, '0x01');
    if (raw == null || raw.isEmpty) return;
    final samples = entry.roundSegments.isNotEmpty
        ? ActivityParser.parseTimedMulti(raw, entry.roundSegments)
        : entry.roundStart != null
            ? ActivityParser.parseTimed(raw, entry.roundStart!)
            : <ActivityTimedSample>[];
    for (final s in samples) {
      if (!isOnOrAfterIstDay(s.timestamp, cutoff)) continue;
      final a = acc.putIfAbsent(istDayKey(s.timestamp), _DayAcc.new);
      a.steps += s.sample.steps;
      if (s.sample.heartRate > 0 && s.sample.heartRate < 0xFF) {
        a.hrSum += s.sample.heartRate;
        a.hrCount++;
      }
    }
  }

  Future<void> _stress(
    String sessionId,
    List<DumpEntry> entries,
    DateTime cutoff,
    Map<String, _DayAcc> acc,
  ) async {
    final entry = _find(entries, '0x13');
    if (entry == null) return;
    final raw = await store.readTypeBytes(sessionId, '0x13');
    if (raw == null || raw.isEmpty) return;
    final rs = entry.roundStart ?? DateTime.now().toUtc();
    final samples = entry.roundSegments.isNotEmpty
        ? StressParser.parseMulti(raw, entry.roundSegments)
        : StressParser.parse(raw, rs);
    for (final s in samples) {
      if (!isOnOrAfterIstDay(s.timestamp, cutoff)) continue;
      final a = acc.putIfAbsent(istDayKey(s.timestamp), _DayAcc.new);
      a.stressSum += s.value;
      a.stressCount++;
    }
  }

  Future<void> _temperature(
    String sessionId,
    List<DumpEntry> entries,
    DateTime cutoff,
    Map<String, _DayAcc> acc,
  ) async {
    final entry = _find(entries, '0x2e');
    if (entry == null) return;
    final raw = await store.readTypeBytes(sessionId, '0x2e');
    if (raw == null || raw.isEmpty) return;
    final rs = entry.roundStart ?? DateTime.now().toUtc();
    final samples = entry.roundSegments.isNotEmpty
        ? TemperatureParser.parseMulti(raw, entry.roundSegments)
        : TemperatureParser.parse(raw, rs);
    for (final s in samples) {
      if (!isOnOrAfterIstDay(s.timestamp, cutoff)) continue;
      final a = acc.putIfAbsent(istDayKey(s.timestamp), _DayAcc.new);
      a.tempSum += s.celsius;
      a.tempCount++;
    }
  }
}

class _DayAcc {
  int steps = 0, hrSum = 0, hrCount = 0, stressSum = 0, stressCount = 0;
  double tempSum = 0;
  int tempCount = 0;

  DayHealthRow toRow(String dayKey) => DayHealthRow(
        dayKey: dayKey,
        steps: steps,
        avgHeartRate: hrCount > 0 ? hrSum ~/ hrCount : null,
        stressAvg: stressCount > 0 ? stressSum ~/ stressCount : null,
        tempCelsiusAvg: tempCount > 0 ? tempSum / tempCount : null,
      );
}
