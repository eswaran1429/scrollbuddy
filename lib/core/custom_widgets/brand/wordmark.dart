import 'package:flutter/material.dart';
import 'package:scrollbuddy/core/custom_widgets/custom_text/custom_text.dart';
import 'package:scrollbuddy/core/themes/app_colors.dart';

class AppLogo extends StatelessWidget {
  const AppLogo({super.key, this.size = 40});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(size * 0.08),
      decoration: BoxDecoration(color: AppColors.lavenderSoft, shape: BoxShape.circle),
      child: Image.asset('assets/images/logo_mark.png', semanticLabel: 'ScrollBuddy logo'),
    );
  }
}

class Wordmark extends StatelessWidget {
  const Wordmark({super.key, this.size = 22});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        AppLogo(size: size * 1.6),
        SizedBox(width: size * 0.45),
        Flexible(
          child: CustomText(
            text: 'ScrollBuddy',
            fontSize: size,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.3,
            color: AppColors.textPrimary,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
