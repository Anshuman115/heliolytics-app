class UnsolicitedEntry {
  final String code, kind, file;
  final int count;
  final String? firstBytesHex;

  const UnsolicitedEntry({
    required this.code,
    required this.kind,
    required this.count,
    required this.file,
    this.firstBytesHex,
  });

  Map<String, dynamic> toJson() => {
        'code': code,
        'kind': kind,
        'count': count,
        'file': file,
        if (firstBytesHex != null) 'firstBytesHex': firstBytesHex,
      };

  factory UnsolicitedEntry.fromJson(Map<String, dynamic> j) =>
      UnsolicitedEntry(
        code: j['code'] as String,
        kind: j['kind'] as String,
        count: (j['count'] as num).toInt(),
        file: j['file'] as String,
        firstBytesHex: j['firstBytesHex'] as String?,
      );
}
