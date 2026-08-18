import 'package:flutter/material.dart';
import 'package:heliolytics/utils/day_key.dart';

Future<String?> pickDay(BuildContext context, {required String dayKey}) async {
  final current = DateTime.parse(dayKey);
  final picked = await showDatePicker(
    context: context,
    initialDate: current,
    firstDate: DateTime(2020),
    lastDate: DateTime.now(),
  );
  return picked == null ? null : dayKeyFor(picked);
}
