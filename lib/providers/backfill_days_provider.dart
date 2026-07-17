import 'package:flutter_riverpod/flutter_riverpod.dart';

/// User's chosen backfill window from the setup wizard's days-picker step.
/// Null until chosen; consumed once by the first sync, then reset to null
/// by the sync engine (sub-project 2) after a successful first sync.
final backfillDaysProvider = StateProvider<int?>((ref) => null);
