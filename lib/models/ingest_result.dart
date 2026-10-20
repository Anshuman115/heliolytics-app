import 'package:heliolytics/models/protocol_exception.dart';

/// Final per-type outcome of an accepted C2 upload.
enum IngestStatus {
  accepted,
  partial,
  rawOnly;

  static IngestStatus? parse(Object? raw) => switch (raw) {
    'accepted' => accepted,
    'partial' => partial,
    'raw_only' => rawOnly,
    _ => null,
  };

  String get wire => switch (this) {
    IngestStatus.accepted => 'accepted',
    IngestStatus.partial => 'partial',
    IngestStatus.rawOnly => 'raw_only',
  };

  /// True when raw-only placeholders are expected and not a measurement.
  bool get isMeasurement => this != IngestStatus.rawOnly;
}

/// One `types[code]` entry from the C2 response.
class IngestTypeResult {
  const IngestTypeResult({
    required this.code,
    required this.status,
    required this.rows,
    required this.dropped,
    required this.trailingBytes,
    this.warnings = const [],
    this.dataThrough,
  });

  final String code;
  final IngestStatus status;
  final int rows;
  final int dropped;
  final int trailingBytes;
  final List<String> warnings;
  final DateTime? dataThrough;

  factory IngestTypeResult.fromJson(String code, Object? raw) {
    if (raw is! Map) {
      throw ProtocolException('Ingest type $code is not an object');
    }
    final map = Map<String, dynamic>.from(raw);
    final status = IngestStatus.parse(map['status']);
    if (status == null) {
      throw ProtocolException('Ingest type $code has an unknown status');
    }
    final rows = map['rows'];
    final dropped = map['dropped'];
    final trailing = map['trailingBytes'];
    if (rows is! num || dropped is! num || trailing is! num) {
      throw ProtocolException('Ingest type $code has non-numeric counts');
    }
    final warnings = map['warnings'];
    if (warnings is! List) {
      throw ProtocolException('Ingest type $code has no warnings list');
    }
    final dataThrough = map['dataThrough'];
    return IngestTypeResult(
      code: code,
      status: status,
      rows: rows.toInt(),
      dropped: dropped.toInt(),
      trailingBytes: trailing.toInt(),
      warnings: warnings.map((e) => e.toString()).toList(),
      dataThrough: dataThrough is String
          ? DateTime.parse(dataThrough).toUtc()
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'status': status.wire,
    'rows': rows,
    'dropped': dropped,
    'trailingBytes': trailingBytes,
    'warnings': warnings,
    'dataThrough': dataThrough?.toUtc().toIso8601String(),
  };
}

/// Typed result of one ingest attempt. A transport 200 alone is not success.
class IngestResult {
  const IngestResult({
    required this.sessionId,
    required this.complete,
    this.types = const {},
    this.warnings = const [],
  });

  final String sessionId;
  final bool complete;
  final Map<String, IngestTypeResult> types;
  final List<String> warnings;

  /// Types whose rows were stored as measurements in this session.
  Iterable<IngestTypeResult> get measured =>
      types.values.where((t) => t.status.isMeasurement);

  List<String> get partialCodes => types.values
      .where((t) => t.status == IngestStatus.partial)
      .map((t) => t.code)
      .toList();

  bool get hasPartial => partialCodes.isNotEmpty;

  int get droppedRows => types.values.fold(0, (sum, t) => sum + t.dropped);

  /// Parses a C2 response, rejecting shapes the contract does not allow.
  factory IngestResult.fromJson(
    Map<String, dynamic> j, {
    String? expectedSessionId,
  }) {
    final sessionId = j['sessionId'];
    if (sessionId is! String || sessionId.isEmpty) {
      throw const ProtocolException('Ingest response has no sessionId');
    }
    if (expectedSessionId != null && sessionId != expectedSessionId) {
      throw ProtocolException(
        'Ingest response is for $sessionId, expected $expectedSessionId',
      );
    }
    final complete = j['complete'];
    if (complete is! bool) {
      throw const ProtocolException('Ingest response has no complete flag');
    }
    final rawTypes = j['types'];
    if (rawTypes is! Map) {
      throw const ProtocolException('Ingest response has no types map');
    }
    final warnings = j['warnings'];
    if (warnings is! List) {
      throw const ProtocolException('Ingest response has no warnings list');
    }
    final types = <String, IngestTypeResult>{};
    rawTypes.forEach((key, value) {
      types[key.toString()] = IngestTypeResult.fromJson(key.toString(), value);
    });
    return IngestResult(
      sessionId: sessionId,
      complete: complete,
      types: types,
      warnings: warnings.map((e) => e.toString()).toList(),
    );
  }
}
