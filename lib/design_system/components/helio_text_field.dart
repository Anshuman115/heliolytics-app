import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:heliolytics/design_system/tokens/helio_colors.dart';
import 'package:heliolytics/design_system/tokens/helio_radii.dart';
import 'package:heliolytics/design_system/tokens/helio_spacing.dart';
import 'package:heliolytics/design_system/tokens/helio_typography.dart';

class HelioTextField extends StatelessWidget {
  final TextEditingController controller;
  final String? label;
  final String? hint;
  final String? errorText;
  final bool obscureText;
  final int? maxLength;
  final TextInputType? keyboardType;
  final Widget? suffix;
  final bool hexOnly;

  const HelioTextField({
    super.key,
    required this.controller,
    this.label,
    this.hint,
    this.errorText,
    this.obscureText = false,
    this.maxLength,
    this.keyboardType,
    this.suffix,
    this.hexOnly = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Text(label!.toUpperCase(), style: HelioTypography.capsLabel),
          const SizedBox(height: HelioSpacing.xs),
        ],
        TextField(
          controller: controller,
          obscureText: obscureText,
          maxLength: maxLength,
          keyboardType: keyboardType ?? (hexOnly ? TextInputType.text : null),
          autocorrect: false,
          enableSuggestions: false,
          inputFormatters: [
            if (hexOnly) FilteringTextInputFormatter.allow(RegExp(r'[0-9a-fA-F]')),
            if (maxLength != null) LengthLimitingTextInputFormatter(maxLength),
          ],
          style: HelioTypography.body,
          decoration: InputDecoration(
            hintText: hint,
            errorText: errorText,
            suffixIcon: suffix,
            filled: true,
            fillColor: HelioColors.surfaceElevated,
            counterText: '',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(HelioRadii.card),
              borderSide: const BorderSide(color: HelioColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(HelioRadii.card),
              borderSide: const BorderSide(color: HelioColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(HelioRadii.card),
              borderSide: const BorderSide(color: HelioColors.sleepBlue),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(HelioRadii.card),
              borderSide: const BorderSide(color: HelioColors.recoveryLow),
            ),
            hintStyle: HelioTypography.bodyMuted,
          ),
        ),
      ],
    );
  }
}
