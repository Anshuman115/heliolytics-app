import 'package:flutter/material.dart';
import 'package:heliolytics/core/ble/parsers/sleep_session.dart';
import 'package:heliolytics/features/health_data/domain/entities/day_health_row.dart';

class DayDetailScreen extends StatelessWidget {
  final DayHealthRow day;
  final List<SleepSession> sleep;

  const DayDetailScreen({super.key, required this.day, required this.sleep});

  @override
  Widget build(BuildContext context) {
    final daySleep = sleep.where((s) {
      final key = '${s.sessionStart.toLocal().year}-'
          '${s.sessionStart.toLocal().month.toString().padLeft(2, '0')}-'
          '${s.sessionStart.toLocal().day.toString().padLeft(2, '0')}';
      return key == day.dayKey;
    }).toList();

    return Scaffold(
      appBar: AppBar(title: Text(day.dayKey)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _metric('Steps', '${day.steps}'),
          if (day.avgHeartRate != null)
            _metric('Avg HR', '${day.avgHeartRate} bpm'),
          if (day.stressAvg != null) _metric('Avg stress', '${day.stressAvg}'),
          if (day.tempCelsiusAvg != null)
            _metric('Avg skin temp', '${day.tempCelsiusAvg!.toStringAsFixed(1)} °C'),
          const SizedBox(height: 16),
          const Text('Sleep', style: TextStyle(fontWeight: FontWeight.bold)),
          if (daySleep.isEmpty)
            const Text('No sleep session this day')
          else
            ...daySleep.map(_sleepTile),
        ],
      ),
    );
  }

  Widget _metric(String label, String value) => ListTile(
        title: Text(label),
        trailing: Text(value, style: const TextStyle(fontSize: 16)),
      );

  Widget _sleepTile(SleepSession s) => Card(
        child: ListTile(
          title: Text(s.sessionStart.toLocal().toString().substring(0, 16)),
          subtitle: Text(
            'deep ${s.deepMin} · light ${s.lightMin} · REM ${s.remMin} · '
            'wake ${s.wakeMin} min · score ${s.score}',
          ),
        ),
      );
}
