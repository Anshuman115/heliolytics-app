import 'package:flutter/material.dart';
import 'package:heliolytics/design_system/tokens/helio_colors.dart';

class HelioTopBarStatus extends StatelessWidget {
  final List<Widget> actions;
  final bool strapConnected;
  final bool syncActive;
  final int? batteryPercent;

  const HelioTopBarStatus({
    super.key,
    required this.actions,
    required this.strapConnected,
    required this.syncActive,
    required this.batteryPercent,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ...actions,
        if (batteryPercent case final percent?) ...[
          Text(
            '$percent%',
            style: const TextStyle(
              fontSize: 14,
              color: HelioColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 10),
          _StrapIcon(connected: strapConnected),
        ],
      ],
    );
  }
}

class _StrapIcon extends StatelessWidget {
  final bool connected;

  const _StrapIcon({required this.connected});

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        const Icon(
          Icons.watch_outlined,
          size: 30,
          color: HelioColors.textPrimary,
        ),
        if (connected)
          Positioned(
            right: -2,
            top: 1,
            child: Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: HelioColors.optimalGreen,
                shape: BoxShape.circle,
              ),
            ),
          ),
      ],
    );
  }
}
