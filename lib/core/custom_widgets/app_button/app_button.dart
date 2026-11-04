import 'package:flutter/material.dart';
import 'package:scrollbuddy/core/custom_widgets/custom_text/custom_text.dart';
import 'package:scrollbuddy/core/themes/app_colors.dart';
import 'package:scrollbuddy/core/themes/app_tokens.dart';

enum AppButtonVariant { primary, secondary, text }

/// Pill button. Primary is solid sage; disabled when [onPressed] is null.
class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.variant = AppButtonVariant.primary,
    this.expand = true,
    this.compact = false,
  });

  const AppButton.secondary({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.expand = true,
    this.compact = false,
  }) : variant = AppButtonVariant.secondary;

  const AppButton.text({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.expand = true,
    this.compact = false,
  }) : variant = AppButtonVariant.text;

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final AppButtonVariant variant;
  final bool expand;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    final (bg, fg) = switch (variant) {
      AppButtonVariant.primary =>
        enabled ? (AppColors.sage, Colors.white) : (AppColors.surfaceHigh, AppColors.textMuted),
      AppButtonVariant.secondary =>
        enabled ? (AppColors.sageSoft, AppColors.sage) : (AppColors.surfaceHigh, AppColors.textMuted),
      AppButtonVariant.text => (Colors.transparent, enabled ? AppColors.sage : AppColors.textMuted),
    };

    return Semantics(
      button: true,
      enabled: enabled,
      child: SizedBox(
        width: expand ? double.infinity : null,
        height: compact ? 40 : 56,
        child: Material(
          color: bg,
          shape: const StadiumBorder(),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onPressed,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: compact ? 16 : 24),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                    Icon(icon, color: fg, size: compact ? 18 : 20),
                    const SizedBox(width: 8),
                  ],
                  Flexible(
                    child: CustomText(
                      text: label,
                      color: fg,
                      fontWeight: FontWeight.w600,
                      fontSize: compact ? 14 : 16,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Round white icon button with a soft shadow.
class AppIconButton extends StatelessWidget {
  const AppIconButton({super.key, required this.icon, required this.onPressed, required this.tooltip});

  final IconData icon;
  final VoidCallback? onPressed;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(shape: BoxShape.circle, boxShadow: onPressed == null ? null : AppShadows.sm),
      child: IconButton(
        tooltip: tooltip,
        onPressed: onPressed,
        icon: Icon(icon),
        style: IconButton.styleFrom(
          backgroundColor: AppColors.surface,
          foregroundColor: AppColors.textPrimary,
          disabledBackgroundColor: Colors.transparent,
          disabledForegroundColor: AppColors.textMuted.withValues(alpha: 0.4),
          fixedSize: const Size(44, 44),
        ),
      ),
    );
  }
}
