/// Phase 2 — one parsed dump type ready for Hive / UI.
class ParsedTypeBatch {
  final String typeCode;
  final int sampleCount;
  final DateTime parsedAt;

  const ParsedTypeBatch({
    required this.typeCode,
    required this.sampleCount,
    required this.parsedAt,
  });
}
