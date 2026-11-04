import 'package:flutter/material.dart';
import 'package:scrollbuddy/core/custom_widgets/custom_text/custom_text.dart';
import 'package:scrollbuddy/core/themes/app_colors.dart';
import 'package:scrollbuddy/core/themes/app_tokens.dart';

/// List row used inside [AppTileGroup].
class AppTile extends StatelessWidget {
  const AppTile({
    super.key,
    required this.title,
    this.leading,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.enabled = true,
    this.titleColor,
  });

  final String title;
  final Widget? leading;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool enabled;
  final Color? titleColor;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: enabled ? onTap : null,
      child: Opacity(
        opacity: enabled ? 1 : 0.45,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          child: Row(
            children: [
              if (leading != null) ...[leading!, const SizedBox(width: 14)],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CustomText(text: title, fontWeight: FontWeight.w500, fontSize: 15, color: titleColor),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      CustomText(text: subtitle!, fontSize: 13, color: AppColors.textMuted),
                    ],
                  ],
                ),
              ),
              if (trailing != null) ...[const SizedBox(width: 12), trailing!],
            ],
          ),
        ),
      ),
    );
  }
}

/// White rounded group of [AppTile]s with an optional label above.
class AppTileGroup extends StatelessWidget {
  const AppTileGroup({super.key, required this.children, this.title});

  final List<Widget> children;
  final String? title;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title != null)
          Padding(
            padding: const EdgeInsets.only(left: 6, bottom: 10),
            child: CustomText(text: title!, fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textMuted),
          ),
        Container(
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(24), boxShadow: AppShadows.sm),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Material(
              color: AppColors.surface,
              child: Column(
                children: [
                  for (final (i, c) in children.indexed) ...[
                    if (i > 0) const Divider(height: 1, indent: 18, endIndent: 18),
                    c,
                  ],
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Soft tinted circle with an icon.
class IconBadge extends StatelessWidget {
  const IconBadge({super.key, required this.icon, required this.color, this.size = 36});

  final IconData icon;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color.withValues(alpha: 0.13), shape: BoxShape.circle),
      child: Icon(icon, color: color, size: size * 0.52),
    );
  }
}
