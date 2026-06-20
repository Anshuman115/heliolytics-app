import 'package:flutter/material.dart';
import 'package:heliolytics/design_system/tokens/helio_radii.dart';
import 'package:heliolytics/design_system/tokens/helio_typography.dart';

class HelioPrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool loading;

  const HelioPrimaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: FilledButton(
        onPressed: loading ? null : onPressed,
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(HelioRadii.card),
          ),
        ),
        child: loading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Text(label.toUpperCase(), style: HelioTypography.capsLabel),
      ),
    );
  }
}
