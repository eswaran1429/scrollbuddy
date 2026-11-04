import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:scrollbuddy/core/custom_widgets/app_button/app_button.dart';
import 'package:scrollbuddy/core/custom_widgets/custom_text/custom_text.dart';
import 'package:scrollbuddy/core/themes/app_colors.dart';

/// Screen header: optional square back button, bold title with a small
/// subtitle, and square action buttons on the right.
class PageHeader extends StatelessWidget {
  const PageHeader({super.key, required this.title, this.subtitle, this.showBack = false, this.actions = const []});

  final String title;
  final String? subtitle;
  final bool showBack;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (showBack) ...[
          AppIconButton(icon: Icons.arrow_back, tooltip: 'Back', onPressed: () => context.pop()),
          const SizedBox(width: 14),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CustomText(
                text: title,
                fontSize: 20,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.3,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (subtitle != null) CustomText(text: subtitle!, fontSize: 12, color: AppColors.textMuted, maxLines: 1),
            ],
          ),
        ),
        for (final (i, a) in actions.indexed) ...[if (i > 0) const SizedBox(width: 8), a],
      ],
    );
  }
}

/// Small uppercase label above a group, e.g. "TRACKED APPS".
class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return CustomText(
      text: text.toUpperCase(),
      fontSize: 11,
      fontWeight: FontWeight.w600,
      letterSpacing: 1.1,
      color: AppColors.textMuted,
    );
  }
}

/// Small rounded pill with an optional leading icon.
class StatusPill extends StatelessWidget {
  const StatusPill({super.key, required this.text, required this.color, required this.background, this.icon});

  final String text;
  final Color color;
  final Color background;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(10)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[Icon(icon, size: 14, color: color), const SizedBox(width: 5)],
          Flexible(
            child: CustomText(text: text, fontSize: 11, fontWeight: FontWeight.w600, color: color, maxLines: 1),
          ),
        ],
      ),
    );
  }
}
