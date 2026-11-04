import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:scrollbuddy/core/custom_widgets/custom_text/custom_text.dart';
import 'package:scrollbuddy/core/themes/app_colors.dart';

class CustomTextField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final TextInputType keyboardType;
  final ValueChanged<String>? onChanged;
  final int? maxLength;
  final String? Function(String?)? validator;
  final Widget? suffix;
  final Widget? prefix;
  final List<TextInputFormatter>? inputFormatters;
  final bool? readOnly;
  final String? errorText;
  final AutovalidateMode? autovalidateMode;
  final TextCapitalization textCapitalization;
  final VoidCallback? onTap;
  final bool obscureText;
  final bool autofocus;

  /// Typed text style; defaults to the theme (readable in light and dark).
  final TextStyle? textStyle;

  /// Background fill; null means no fill.
  final Color? fillColor;

  const CustomTextField({
    super.key,
    required this.label,
    required this.controller,
    this.keyboardType = TextInputType.text,
    this.onChanged,
    this.maxLength,
    this.validator,
    this.suffix,
    this.prefix,
    this.inputFormatters,
    this.readOnly,
    this.errorText,
    this.autovalidateMode = AutovalidateMode.onUserInteraction,
    this.textCapitalization = TextCapitalization.none,
    this.onTap,
    this.obscureText = false,
    this.autofocus = false,
    this.textStyle,
    this.fillColor,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      onChanged: onChanged,
      maxLength: maxLength,
      validator: validator,
      inputFormatters: inputFormatters,
      readOnly: readOnly ?? false,
      onTap: onTap,
      obscureText: obscureText,
      autofocus: autofocus,
      autovalidateMode: autovalidateMode,
      textCapitalization: textCapitalization,
      style: (textStyle ?? const TextStyle()).copyWith(fontFamily: CustomText.fontFamily),
      decoration: InputDecoration(
        suffixIcon: suffix,
        prefixIcon: prefix,
        hintText: label,
        isDense: true,
        counterText: "",
        errorText: errorText,
        filled: fillColor != null,
        fillColor: fillColor,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        hintStyle: const TextStyle(fontFamily: CustomText.fontFamily, fontSize: 12, color: AppColors.grey),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: AppColors.grey),
          borderRadius: BorderRadius.circular(12),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: AppColors.grey, width: 2),
          borderRadius: BorderRadius.circular(12),
        ),
        errorBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: AppColors.redAccent),
          borderRadius: BorderRadius.circular(12),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: AppColors.redAccent, width: 2),
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}
