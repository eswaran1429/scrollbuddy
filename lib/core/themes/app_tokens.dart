import 'package:flutter/material.dart';
import 'package:scrollbuddy/core/themes/app_colors.dart';

class AppShadows {
  AppShadows._();

  static final List<BoxShadow> sm = [
    BoxShadow(color: AppColors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 3)),
  ];

  static final List<BoxShadow> md = [
    BoxShadow(color: AppColors.black.withValues(alpha: 0.06), blurRadius: 16, offset: const Offset(0, 6)),
  ];
  static final List<BoxShadow> lg = [
    BoxShadow(color: AppColors.black.withValues(alpha: 0.10), blurRadius: 24, offset: const Offset(0, 10)),
  ];
}

class AppRadius {
  AppRadius._();

  static const double sm = 12;
  static const double md = 20;
  static const double lg = 30;

  static const BorderRadius rSm = BorderRadius.all(Radius.circular(sm));
  static const BorderRadius rMd = BorderRadius.all(Radius.circular(md));
  static const BorderRadius rLg = BorderRadius.all(Radius.circular(lg));

  static const BorderRadius sheetTop = BorderRadius.vertical(top: Radius.circular(lg));
}

class AppSpacing {
  AppSpacing._();

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
}

class AppTextTokens {
  AppTextTokens._();

  static const double displaySize = 30;
  static const FontWeight displayWeight = FontWeight.bold;

  static const double titleSize = 20;
  static const FontWeight titleWeight = FontWeight.bold;

  static const double titleSmSize = 18;
  static const FontWeight titleSmWeight = FontWeight.w600;

  static const double bodySize = 15;
  static const FontWeight bodyWeight = FontWeight.normal;

  static const double bodySmSize = 14;
  static const FontWeight bodySmWeight = FontWeight.normal;

  static const double captionSize = 12;
  static const FontWeight captionWeight = FontWeight.normal;

  static const double overlineSize = 10;
  static const FontWeight overlineWeight = FontWeight.bold;
}
