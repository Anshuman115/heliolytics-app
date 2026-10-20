import 'package:heliolytics/utils/ist_time.dart';

/// Optional profile inputs. Every field may be unset.
class UserProfile {
  const UserProfile({
    this.name,
    this.birthDate,
    this.sex,
    this.heightCm,
    this.weightKg,
  });

  static const String male = 'male';
  static const String female = 'female';

  final String? name;

  /// Date only, local calendar date with no time component.
  final DateTime? birthDate;

  /// [male], [female] or null. Never guessed from a name.
  final String? sex;
  final double? heightCm;
  final double? weightKg;

  /// Full-replacement C3 payload: every key present, nulls explicit.
  Map<String, dynamic> toWireJson() => {
    'name': name,
    'birthDate': birthDate == null ? null : formatDateOnly(birthDate!),
    'sex': sex,
    'heightCm': heightCm,
    'weightKg': weightKg,
  };

  Map<String, dynamic> toJson() => toWireJson();

  factory UserProfile.fromJson(Map<String, dynamic> j) => UserProfile(
    name: j['name'] as String?,
    birthDate: j['birthDate'] is String
        ? parseDateOnly(j['birthDate'] as String)
        : null,
    sex: _sex(j['sex']),
    heightCm: (j['heightCm'] as num?)?.toDouble(),
    weightKg: (j['weightKg'] as num?)?.toDouble(),
  );

  UserProfile copyWith({
    String? name,
    DateTime? birthDate,
    String? sex,
    double? heightCm,
    double? weightKg,
    bool clearName = false,
    bool clearBirthDate = false,
    bool clearSex = false,
    bool clearHeight = false,
    bool clearWeight = false,
  }) => UserProfile(
    name: clearName ? null : (name ?? this.name),
    birthDate: clearBirthDate ? null : (birthDate ?? this.birthDate),
    sex: clearSex ? null : (sex ?? this.sex),
    heightCm: clearHeight ? null : (heightCm ?? this.heightCm),
    weightKg: clearWeight ? null : (weightKg ?? this.weightKg),
  );
}

String? _sex(Object? raw) {
  if (raw == UserProfile.male) return UserProfile.male;
  if (raw == UserProfile.female) return UserProfile.female;
  return null;
}

String formatDateOnly(DateTime date) {
  final y = date.year.toString().padLeft(4, '0');
  final m = date.month.toString().padLeft(2, '0');
  final d = date.day.toString().padLeft(2, '0');
  return '$y-$m-$d';
}

/// Parses `YYYY-MM-DD`, rejecting rollover dates such as 2026-02-30.
DateTime parseDateOnly(String raw) {
  final match = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch(raw);
  if (match == null) throw FormatException('Invalid date: $raw');
  final year = int.parse(match.group(1)!);
  final month = int.parse(match.group(2)!);
  final day = int.parse(match.group(3)!);
  final date = DateTime(year, month, day);
  if (date.year != year || date.month != month || date.day != day) {
    throw FormatException('Invalid date: $raw');
  }
  return date;
}

/// Returns an error message, or null when [raw] is an acceptable birth date.
String? birthDateError(String raw) {
  final value = raw.trim();
  if (value.isEmpty) return null;
  final DateTime date;
  try {
    date = parseDateOnly(value);
  } on FormatException {
    return 'Enter the date as YYYY-MM-DD.';
  }
  final earliest = DateTime(1900, 1, 1);
  if (!date.isAfter(earliest)) return 'Enter a date after 1900-01-01.';
  if (date.isAfter(istToday())) {
    return 'The birth date cannot be in the future.';
  }
  return null;
}
