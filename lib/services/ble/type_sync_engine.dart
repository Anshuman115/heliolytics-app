import 'dart:async';
import 'dart:typed_data';

import 'package:heliolytics/services/ble/parsers/activity_parser.dart';
import 'package:heliolytics/services/ble/sync_page_anchor.dart';
import 'package:heliolytics/utils/huami_time.dart';

/// Huami activity-fetch over plaintext GATT (control 0x0004, data 0x0005).
/// Protocol: [0x01,type]+HuamiTime → meta reply [0x10,0x01,status,expected,date]
/// → [0x02] fetch → data on 0x0005 [counter,payload..] → [0x03,0x09] ack (keep).
class TypeSyncEngine {
  static const int _response = 0x10;
  static const int _cmdStartDate = 0x01;
  static const int _cmdFetchData = 0x02;
  static const int _cmdAck = 0x03;
  static const int _ackKeep = 0x09;

  final Future<void> Function(List<int>) writeControl;
  final void Function(String)? log;

  _FetchJob? _job;
  int lastExpected = 0;
  Uint8List lastRaw = Uint8List(0);
  DateTime? firstRoundStart;
  final List<SyncPageAnchor> roundSegments = [];

  TypeSyncEngine(this.writeControl, {this.log});

  Future<Uint8List> fetchType(
    int code,
    DateTime since, {
    bool probeOnly = false,
    int maxRounds = 20,
    Duration timeout = const Duration(seconds: 30),
  }) {
    lastExpected = -1;
    firstRoundStart = null;
    roundSegments.clear();
    final job = _FetchJob(code, since)
      ..probeOnly = probeOnly
      ..maxRounds = maxRounds;
    _job = job;
    _startRound();
    return job.completer.future.timeout(timeout, onTimeout: () {
      if (!probeOnly) log?.call('  fetch 0x${code.toRadixString(16)} timed out');
      lastRaw = job.allRaw.toBytes();
      _job = null;
      // Tell the strap we're done so it's ready for the next code.
      writeControl([_cmdAck, _ackKeep]);
      return lastRaw;
    });
  }

  void _startRound() {
    final job = _job;
    if (job == null) return;
    job.data.clear();
    job.lastCounter = -1;
    job.rounds++;
    final cmd = <int>[_cmdStartDate, job.code, ...HuamiTime.fromDateTime(job.since)];
    writeControl(cmd);
  }

  void onControl(Uint8List p) {
    final job = _job;
    if (job == null) return;
    if (p.length < 3 || p[0] != _response) {
      log?.call('  control non-response: ${_hex(p)}');
      return;
    }
    final cmd = p[1];
    final status = p[2];
    if (cmd == _cmdStartDate) {
      if (status != 0x01) {
        _finish('start rejected 0x${status.toRadixString(16)}');
        return;
      }
      final parsed = HuamiTime.parseStartDate(p);
      if (parsed == null) {
        _finish('bad start reply');
        return;
      }
      job.roundStart = parsed.start;
      firstRoundStart ??= parsed.start;
      lastExpected = parsed.expected;
      if (!job.probeOnly) {
        log?.call('  round ${job.rounds}: expect ${parsed.expected} pkts '
            'since ${parsed.start.toIso8601String()}');
      }
      if (parsed.expected == 0 || job.probeOnly) {
        _ackThenFinish();
        return;
      }
      writeControl([_cmdFetchData]);
    } else if (cmd == _cmdFetchData) {
      if (status != 0x01) {
        _finish('fetch failed 0x${status.toRadixString(16)}');
        return;
      }
      _ackAndPage();
    }
  }

  void onData(Uint8List value) {
    final job = _job;
    if (job == null || value.isEmpty) return;
    final counter = value[0];
    if (job.lastCounter >= 0 && counter != ((job.lastCounter + 1) & 0xFF)) {
      log?.call('  counter gap got=$counter exp=${(job.lastCounter + 1) & 0xFF}');
    }
    job.lastCounter = counter;
    job.data.add(value.sublist(1));
  }

  void _ackAndPage() {
    final job = _job;
    if (job == null) return;
    writeControl([_cmdAck, _ackKeep]);
    final raw = job.data.toBytes();
    if (raw.isNotEmpty) {
      roundSegments.add(SyncPageAnchor(
        byteOffset: job.allRaw.length,
        roundStart: job.roundStart,
      ));
    }
    job.allRaw.add(raw);
    log?.call('  round ${job.rounds}: ${raw.length}B raw');

    if (job.rounds < job.maxRounds) {
      final last = ActivityParser.lastSampleTime(
        job.code,
        job.code == 0x05 ? job.allRaw.toBytes() : raw,
        job.roundStart,
      );
      if (last != null) {
        final nextSince = last.add(const Duration(minutes: 1));
        final now = DateTime.now();
        if (nextSince.isBefore(now.subtract(const Duration(seconds: 30))) &&
            nextSince.isAfter(job.since)) {
          if (job.code == 0x05) {
            log?.call('  workouts paging from ${nextSince.toIso8601String()}');
          }
          job.since = nextSince;
          _startRound();
          return;
        }
      }
    }
    _finishOk();
  }

  void _ackThenFinish() {
    writeControl([_cmdAck, _ackKeep]);
    _finishOk();
  }

  void _finishOk() {
    final job = _job;
    if (job == null) return;
    lastRaw = job.allRaw.toBytes();
    _job = null;
    if (!job.completer.isCompleted) job.completer.complete(lastRaw);
  }

  void _finish(String reason) {
    final job = _job;
    if (job == null) return;
    if (!job.probeOnly) log?.call('  finish 0x${job.code.toRadixString(16)}: $reason');
    lastRaw = job.allRaw.toBytes();
    _job = null;
    if (!job.completer.isCompleted) job.completer.complete(lastRaw);
  }

  static String _hex(Uint8List b) =>
      b.map((x) => x.toRadixString(16).padLeft(2, '0')).join();
}

class _FetchJob {
  final int code;
  DateTime since;
  DateTime roundStart;
  final BytesBuilder data = BytesBuilder();
  final BytesBuilder allRaw = BytesBuilder();
  bool probeOnly = false;
  int maxRounds = 20;
  int lastCounter = -1;
  int rounds = 0;
  final Completer<Uint8List> completer = Completer<Uint8List>();
  _FetchJob(this.code, this.since) : roundStart = since;
}
