import 'dart:typed_data';

import 'package:heliolytics/features/ble_discovery/domain/models/dump_entry.dart';
import 'package:heliolytics/features/health_data/data/pipeline/type_parser_dispatch.dart';
import 'package:heliolytics/features/health_data/domain/entities/parsed_type_batch.dart';
import 'package:heliolytics/features/health_data/domain/repositories/health_parser_repository.dart';

class HealthParserRepositoryImpl implements HealthParserRepository {
  final TypeParserDispatch _dispatch;

  HealthParserRepositoryImpl({TypeParserDispatch? dispatch})
      : _dispatch = dispatch ?? TypeParserDispatch();

  @override
  Future<ParsedTypeBatch> parseType(DumpEntry entry, Uint8List raw) async {
    final count = _dispatch.countSamples(entry, raw);
    return ParsedTypeBatch(
      typeCode: entry.code,
      sampleCount: count,
      parsedAt: DateTime.now(),
    );
  }
}
