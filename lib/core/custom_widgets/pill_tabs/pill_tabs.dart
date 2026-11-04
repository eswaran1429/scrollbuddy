import 'package:flutter/material.dart';
import 'package:scrollbuddy/core/custom_widgets/custom_text/custom_text.dart';
import 'package:scrollbuddy/core/themes/app_colors.dart';
import 'package:scrollbuddy/core/themes/app_tokens.dart';

/// Segmented control: white track, selected tab is a solid sage block.
class PillTabs extends StatelessWidget {
  const PillTabs({super.key, required this.labels, required this.selected, required this.onChanged});

  final List<String> labels;
  final int selected;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.stroke),
      ),
      child: Row(
        children: [
          for (final (i, label) in labels.indexed)
            Expanded(
              child: Semantics(
                selected: i == selected,
                button: true,
                child: GestureDetector(
                  onTap: () => onChanged(i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(vertical: 9),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: i == selected ? AppColors.sage : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: i == selected ? AppShadows.sm : null,
                    ),
                    child: CustomText(
                      text: label,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: i == selected ? Colors.white : AppColors.textMuted,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
