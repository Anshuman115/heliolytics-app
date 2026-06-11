import 'package:flutter/material.dart';

class SleepStageBar extends StatelessWidget {
  final int deep;
  final int rem;
  final int light;

  const SleepStageBar({
    super.key,
    required this.deep,
    required this.rem,
    required this.light,
  });

  @override
  Widget build(BuildContext context) {
    final total = (deep + rem + light).clamp(1, 99999);
    Widget seg(Color c, int mins, String name) {
      final w = mins / total;
      if (w <= 0) return const SizedBox.shrink();
      return Expanded(
        flex: mins,
        child: Tooltip(
          message: '$name $mins min',
          child: Container(color: c),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: SizedBox(
            height: 12,
            child: Row(
              children: [
                seg(const Color(0xFF5C6BC0), deep, 'Deep'),
                seg(const Color(0xFF7E57C2), rem, 'REM'),
                seg(const Color(0xFF29B6F6), light, 'Light'),
              ],
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Deep $deep · REM $rem · Light $light min',
          style: Theme.of(context).textTheme.labelSmall,
        ),
      ],
    );
  }
}
