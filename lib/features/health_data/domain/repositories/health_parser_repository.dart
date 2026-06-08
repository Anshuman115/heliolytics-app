import 'dart:typed_data';

import 'package:heliolytics/features/ble_discovery/domain/models/dump_entry.dart';
import 'package:heliolytics/features/health_data/domain/entities/parsed_type_batch.dart';

/// Phase 2 — turn raw .bin + dump metadata into typed samples.
abstract class HealthParserRepository {
  Future<ParsedTypeBatch> parseType(DumpEntry entry, Uint8List raw);
}
