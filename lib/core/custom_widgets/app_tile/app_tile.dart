import 'package:flutter/material.dart';
import 'package:scrollbuddy/core/custom_widgets/custom_text/custom_text.dart';
import 'package:scrollbuddy/core/custom_widgets/page_header/page_header.dart';
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
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              if (leading != null) ...[leading!, const SizedBox(width: 12)],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CustomText(text: title, fontWeight: FontWeight.w500, fontSize: 14, color: titleColor),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      CustomText(text: subtitle!, fontSize: 12, color: AppColors.textMuted),
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
        if (title != null) Padding(padding: const EdgeInsets.only(left: 4, bottom: 8), child: SectionLabel(title!)),
        Container(
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(22), boxShadow: AppShadows.sm),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: Material(
              color: AppColors.surface,
              child: Column(
                children: [
                  for (final (i, c) in children.indexed) ...[
                    if (i > 0) const Divider(height: 1, indent: 16, endIndent: 16),
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

/// Soft tinted rounded square with an icon.
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
      decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(size * 0.3)),
      child: Icon(icon, color: color, size: size * 0.5),
    );
  }
}

/// Label on the left, value on the right. Used in key/value cards.
class InfoRow extends StatelessWidget {
  const InfoRow({super.key, required this.label, required this.value, this.valueColor});

  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: CustomText(text: label, fontSize: 13, color: AppColors.textMuted),
          ),
          CustomText(text: value, fontSize: 13, fontWeight: FontWeight.w600, color: valueColor),
        ],
      ),
    );
  }
}
