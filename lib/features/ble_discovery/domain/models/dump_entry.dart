import 'package:heliolytics/core/ble/sync_page_anchor.dart';
import 'package:heliolytics/features/ble_discovery/domain/models/dump_status.dart';

class DumpEntry {
  final String code;
  final DumpStatus status;
  final int samples, bytes;
  final String? file;
  final String? errorByte;
  /// Device-reported roundStart from the first fetch round (round-relative types).
  final DateTime? roundStart;
  /// Per-page anchors from paged Huami activity-fetch.
  final List<SyncPageAnchor> roundSegments;

  const DumpEntry({
    required this.code,
    required this.status,
    required this.samples,
    required this.bytes,
    this.file,
    this.errorByte,
    this.roundStart,
    this.roundSegments = const [],
  });

  Map<String, dynamic> toJson() => {
        'schemaVersion': 1,
        'code': code,
        'status': status.label,
        'samples': samples,
        'bytes': bytes,
        if (file != null) 'file': file,
        if (errorByte != null) 'errorByte': errorByte,
        if (roundStart != null) 'roundStart': roundStart!.toIso8601String(),
        if (roundSegments.isNotEmpty)
          'roundSegments': roundSegments.map((s) => s.toJson()).toList(),
      };

  factory DumpEntry.fromJson(Map<String, dynamic> j) => DumpEntry(
        code: j['code'] as String,
        status: DumpStatusX.parse(j['status'] as String),
        samples: (j['samples'] as num).toInt(),
        bytes: (j['bytes'] as num).toInt(),
        file: j['file'] as String?,
        errorByte: j['errorByte'] as String?,
        roundStart: j['roundStart'] != null
            ? DateTime.parse(j['roundStart'] as String)
            : null,
        roundSegments: (j['roundSegments'] as List<dynamic>?)
                ?.map((e) => SyncPageAnchor.fromJson(
                    Map<String, dynamic>.from(e as Map)))
                .toList() ??
            const [],
      );
}
