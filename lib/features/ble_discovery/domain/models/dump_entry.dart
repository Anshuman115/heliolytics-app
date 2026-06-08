import 'package:heliolytics/features/ble_discovery/domain/models/dump_status.dart';

class DumpEntry {
  final String code;
  final DumpStatus status;
  final int samples, bytes;
  final String? file;
  final String? errorByte;

  const DumpEntry({
    required this.code,
    required this.status,
    required this.samples,
    required this.bytes,
    this.file,
    this.errorByte,
  });

  Map<String, dynamic> toJson() => {
        'schemaVersion': 1,
        'code': code,
        'status': status.label,
        'samples': samples,
        'bytes': bytes,
        if (file != null) 'file': file,
        if (errorByte != null) 'errorByte': errorByte,
      };

  factory DumpEntry.fromJson(Map<String, dynamic> j) => DumpEntry(
        code: j['code'] as String,
        status: DumpStatusX.parse(j['status'] as String),
        samples: (j['samples'] as num).toInt(),
        bytes: (j['bytes'] as num).toInt(),
        file: j['file'] as String?,
        errorByte: j['errorByte'] as String?,
      );
}
