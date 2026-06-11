import 'package:flutter/material.dart';

import 'package:heliolytics/core/utils/sport_labels.dart';

IconData sportIconForName(String name) {
  final n = name.toLowerCase();
  if (n.contains('run') || n.contains('marathon') || n.contains('treadmill')) {
    return Icons.directions_run;
  }
  if (n.contains('walk') || n.contains('hik')) return Icons.directions_walk;
  if (n.contains('cycl') || n.contains('bik') || n.contains('bmx')) {
    return Icons.directions_bike;
  }
  if (n.contains('swim') || n.contains('snorkel') || n.contains('polo')) {
    return Icons.pool;
  }
  if (n.contains('badminton') || n.contains('tennis') || n.contains('squash') ||
      n.contains('ping') || n.contains('racquet')) {
    return Icons.sports_tennis;
  }
  if (n.contains('football') || n.contains('soccer') || n.contains('rugby')) {
    return Icons.sports_soccer;
  }
  if (n.contains('basket')) return Icons.sports_basketball;
  if (n.contains('yoga') || n.contains('pilates') || n.contains('stretch')) {
    return Icons.self_improvement;
  }
  if (n.contains('strength') || n.contains('hiit') || n.contains('gym') ||
      n.contains('train') || n.contains('core')) {
    return Icons.fitness_center;
  }
  if (n.contains('skat')) return Icons.skateboarding;
  if (n.contains('ski') || n.contains('snow')) return Icons.downhill_skiing;
  if (n.contains('climb')) return Icons.terrain;
  if (n.contains('row') || n.contains('kayak') || n.contains('boat')) {
    return Icons.rowing;
  }
  return Icons.sports;
}

IconData sportIcon(int sportType, {String? name}) {
  final label = name?.isNotEmpty == true ? name! : sportLabel(sportType);
  return sportIconForName(label);
}
