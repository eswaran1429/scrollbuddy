import 'package:flutter/material.dart';

class CustomText extends StatelessWidget {
  final String text;
  final double? fontSize;
  final FontWeight? fontWeight;
  final Color? color;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;
  final double? letterSpacing;
  final TextDecoration? textDecoration;
  final double? height;
  final TextStyle? style;
  static const fontFamily = 'Poppins';

  const CustomText({
    super.key,
    required this.text,
    this.fontSize,
    this.fontWeight,
    this.color,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.letterSpacing,
    this.textDecoration,
    this.height,
    this.style,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final base = fontSize ?? style?.fontSize ?? DefaultTextStyle.of(context).style.fontSize ?? 14;
    final responsiveSize = base * (screenWidth / 375).clamp(0.95, 1.15);

    return Text(
      text,
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
      style: (style ?? const TextStyle()).copyWith(
        fontSize: responsiveSize,
        fontWeight: fontWeight,
        color: color,
        fontFamily: fontFamily,
        decoration: textDecoration,
        letterSpacing: letterSpacing,
        height: height,
      ),
    );
  }
}
