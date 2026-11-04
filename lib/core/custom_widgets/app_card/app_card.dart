import 'package:flutter/material.dart';
import 'package:scrollbuddy/core/themes/app_colors.dart';
import 'package:scrollbuddy/core/themes/app_tokens.dart';

/// Rounded card. White with a soft shadow by default; a tinted [color]
/// drops the shadow. Tappable when [onTap] is set.
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.color,
    this.border,
    this.onTap,
    this.radius = 28,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? color;
  final BoxBorder? border;
  final VoidCallback? onTap;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final r = BorderRadius.circular(radius);
    return Container(
      decoration: BoxDecoration(
        borderRadius: r,
        boxShadow: color == null ? AppShadows.sm : null,
      ),
      child: Material(
        color: color ?? AppColors.surface,
        borderRadius: r,
        clipBehavior: Clip.antiAlias,
        child: Ink(
          decoration: BoxDecoration(borderRadius: r, border: border),
          child: InkWell(onTap: onTap, borderRadius: r, child: Padding(padding: padding, child: child)),
        ),
      ),
    );
  }
}
