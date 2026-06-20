import 'package:flutter/material.dart';
import 'package:heliolytics/design_system/tokens/helio_radii.dart';
import 'package:heliolytics/design_system/tokens/helio_typography.dart';

class HelioSecondaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool loading;

  const HelioSecondaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: OutlinedButton.icon(
        onPressed: loading ? null : onPressed,
        icon: loading
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Icon(icon ?? Icons.chevron_right, size: 18),
        label: Text(label.toUpperCase(), style: HelioTypography.capsLabel),
        style: OutlinedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(HelioRadii.card),
          ),
        ),
      ),
    );
  }
}
