part 'sport_labels_a.dart';
part 'sport_labels_b.dart';

/// Zepp OS workout subType label — mirrors backend sport_names.
String sportLabel(int id) {
  if (id == 0) return 'Workout';
  return _labelsA[id] ?? _labelsB[id] ?? 'Activity $id';
}
