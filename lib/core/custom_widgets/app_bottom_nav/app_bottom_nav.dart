import 'package:flutter/material.dart';
import 'package:scrollbuddy/core/custom_widgets/custom_text/custom_text.dart';
import 'package:scrollbuddy/core/themes/app_colors.dart';
import 'package:scrollbuddy/core/themes/app_tokens.dart';

class AppNavItem {
  const AppNavItem({required this.icon, required this.activeIcon, required this.label});

  final IconData icon;
  final IconData activeIcon;
  final String label;
}

/// Floating white pill nav. The selected item gets a sage capsule.
class AppBottomNav extends StatelessWidget {
  const AppBottomNav({super.key, required this.items, required this.currentIndex, required this.onTap});

  final List<AppNavItem> items;
  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.fromLTRB(20, 0, 20, 12),
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(32),
          boxShadow: AppShadows.lg,
        ),
        child: Row(
          children: [
            for (final (i, item) in items.indexed)
              Expanded(
                child: Semantics(
                  selected: i == currentIndex,
                  button: true,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => onTap(i),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 220),
                      curve: Curves.easeOut,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: i == currentIndex ? AppColors.sageSoft : Colors.transparent,
                        borderRadius: BorderRadius.circular(26),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            i == currentIndex ? item.activeIcon : item.icon,
                            size: 22,
                            color: i == currentIndex ? AppColors.sage : AppColors.textMuted,
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: CustomText(
                              text: item.label,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              maxLines: 1,
                              overflow: TextOverflow.fade,
                              color: i == currentIndex ? AppColors.sage : AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
