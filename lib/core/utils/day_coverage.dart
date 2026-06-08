/// Minute windows on an IST calendar day (0 = midnight, 1439 = 23:59).
///
/// Strap data may cover only part of a day (e.g. 20:34–23:59) or several
/// disjoint ranges if the watch was off. Sum metrics only inside these windows.
class MinuteWindow {
  final int startMin;
  final int endMin;
  const MinuteWindow(this.startMin, this.endMin);

  int get lengthMinutes => endMin - startMin + 1;
}

/// Merge sorted minute indices into contiguous [MinuteWindow]s.
List<MinuteWindow> mergeMinuteWindows(List<int> minutesOfDay) {
  if (minutesOfDay.isEmpty) return [];
  final mins = minutesOfDay.toSet().toList()..sort();
  final out = <MinuteWindow>[];
  var start = mins.first;
  var prev = start;
  for (var i = 1; i < mins.length; i++) {
    if (mins[i] == prev + 1) {
      prev = mins[i];
      continue;
    }
    out.add(MinuteWindow(start, prev));
    start = prev = mins[i];
  }
  out.add(MinuteWindow(start, prev));
  return out;
}

int minuteOfDayLocal(DateTime local) => local.hour * 60 + local.minute;
