import 'dart:async';
import 'dart:typed_data';

import 'package:heliolytics/core/utils/huami_time.dart';

// ─── Activity Fetcher ─────────────────────────────────────────────────────
// Implements the Huami activity-fetch protocol over GATT chars
// 0x0004 (control) and 0x0005 (data).
//
// Protocol flow per type code:
//   1. Write [0x01, typeCode, HuamiTime(since)] to control char.
//   2. Device replies [0x10, 0x01, 0x01, expectedPkts, date...] (start ok)
//      or [0x10, 0x01, <non-01>] (nothing / rejected).
//   3. Write [0x02] to control char to start the transfer.
//   4. Device streams packets on data char: [counter, payload...].
//   5. After all data, write [0x03, 0x09] to control to ACK and keep history.
//   6. If data returned, advance the since timestamp and repeat from step 1
//      to page forward (pagination). Stop when device returns 0 packets.
//
// No timeouts — the device always sends a control reply when done.
// Known codes use up to 9999 pagination rounds; probe codes use 1 round.
class TypeSyncEngine {
  static const int _response     = 0x10;
  static const int _cmdStartDate = 0x01;
  static const int _cmdFetchData = 0x02;
  static const int _cmdAck       = 0x03;
  static const int _ackKeep      = 0x09;

  final Future<void> Function(List<int>) writeControl;
  final void Function(String)? log;

  _FetchJob? _job;
  int lastExpected = 0;
  Uint8List lastRaw = Uint8List(0);

  TypeSyncEngine(this.writeControl, {this.log});

  /// Fetch [code] since [since]. No timeout — the device always sends a
  /// control reply when done, so the completer always fires naturally.
  /// [maxRounds] caps pagination (400 is plenty for 30 days of any metric).
  Future<Uint8List> fetchType(
    int code,
    DateTime since, {
    bool probeOnly = false,
    int maxRounds = 400,
  }) {
    lastExpected = -1;
    final job = _FetchJob(code, since)
      ..probeOnly = probeOnly
      ..maxRounds = maxRounds;
    _job = job;
    _startRound();
    return job.completer.future;
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

  // Called when the control char receives a notification.
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
        // Device says nothing here (empty / rejected code).
        _finish('start rejected 0x${status.toRadixString(16)}');
        return;
      }
      final parsed = HuamiTime.parseStartDate(p);
      if (parsed == null) { _finish('bad start reply'); return; }
      job.roundStart = parsed.start;
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
      if (status != 0x01) { _finish('fetch failed 0x${status.toRadixString(16)}'); return; }
      _ackAndPage();
    } else if (cmd == _cmdAck) {
      // Device ack reply — ignore.
    }
  }

  // Called when the data char receives a notification.
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
    job.allRaw.add(raw);
    log?.call('  round ${job.rounds}: ${raw.length}B raw');

    // Pagination for 0x01 (activity) only — its records are fixed 16 bytes each
    // with a LE unix timestamp at bytes 0-3, so the last record's timestamp is
    // reliable as the next "since". For all other codes we don't know the record
    // format, so we just ACK-finish. The device signals "no more data" via
    // expected==0 on the next connect anyway.
    if (job.code == 0x01 && raw.isNotEmpty && job.rounds < job.maxRounds) {
      if (raw.length >= 4) {
        final ts = ByteData.sublistView(raw, raw.length - 4)
            .getUint32(0, Endian.little);
        if (ts > 0) {
          final next = DateTime.fromMillisecondsSinceEpoch(ts * 1000, isUtc: true)
              .add(const Duration(minutes: 1));
          final now = DateTime.now();
          if (next.isBefore(now.subtract(const Duration(seconds: 30))) &&
              next.isAfter(job.since)) {
            job.since = next;
            _startRound();
            return;
          }
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
  DateTime since;       // advances each pagination round (the "from" timestamp sent to device)
  DateTime roundStart;  // what the device confirmed as the actual start of this round
  final BytesBuilder data   = BytesBuilder(); // accumulates raw payload bytes for the current round only
  final BytesBuilder allRaw = BytesBuilder(); // accumulates raw bytes across ALL rounds (the final result)
  bool probeOnly = false; // if true, just read expectedPkts and immediately ACK without fetching data
  int maxRounds  = 20;    // hard cap on pagination rounds (9999 = effectively unlimited for known codes)
  int lastCounter = -1;   // last data-packet counter seen; -1 means none yet this round
  int rounds = 0;
  final Completer<Uint8List> completer = Completer<Uint8List>();
  _FetchJob(this.code, this.since) : roundStart = since;
}
