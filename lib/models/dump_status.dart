enum DumpStatus { ok, empty, rejected, unknown }

extension DumpStatusX on DumpStatus {
  String get label => switch (this) {
        DumpStatus.ok => 'ok',
        DumpStatus.empty => 'empty',
        DumpStatus.rejected => 'rejected',
        DumpStatus.unknown => 'unknown',
      };
  static DumpStatus parse(String s) => switch (s) {
        'ok' => DumpStatus.ok,
        'empty' => DumpStatus.empty,
        'rejected' => DumpStatus.rejected,
        'unknown' => DumpStatus.unknown,
        _ => throw FormatException('Unknown DumpStatus: $s'),
      };
}
