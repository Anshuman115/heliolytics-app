import 'package:flutter/material.dart';
import 'package:heliolytics/design_system/tokens/helio_colors.dart';
import 'package:heliolytics/utils/stress_zones.dart';

/// The one place a stress band maps to a colour — gauge, trace, and split bar
/// all read from here so they can never drift apart.
Color stressZoneColor(StressZone z) => switch (z) {
      StressZone.low => HelioColors.stressLow,
      StressZone.medium => HelioColors.tierOptimal,
      StressZone.high => HelioColors.tierCaution,
    };

/// Cool → warm sweep used by the gauge arc, in band order.
const stressGaugeColors = [
  HelioColors.stressLow,
  HelioColors.tierOptimal,
  HelioColors.tierCaution,
];
