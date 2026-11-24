import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:scrollbuddy/core/custom_widgets/custom_text/custom_text.dart';
import 'package:scrollbuddy/core/themes/app_colors.dart';

/// Grade for the day: share of the limit used (or of 100 reels when there is no limit).
(String, Color, String) gradeFor(int reels, int? limit) {
  final r = reels / ((limit != null && limit > 0) ? limit : 100);
  if (r < 0.3) return ('A+', AppColors.sage, 'Barely scrolled. Are you even human? Proud of you.');
  if (r < 0.5) return ('A', AppColors.sage, 'Solid day. Your thumb is well rested.');
  if (r < 0.8) return ('B', AppColors.lavender, 'Not bad. A few reels, no regrets. Mostly.');
  if (r < 1.0) return ('C', AppColors.amber, 'Cutting it close. Tomorrow, a little less?');
  if (r < 1.3) return ('D', AppColors.coral, 'Over the limit. The algorithm says thanks.');
  return ('F', AppColors.coral, 'Spectacular. In the worst way. Fresh start tomorrow.');
}

/// Evening grade stamped on the cat (from 6 pm). Thumps in once; tap to read the verdict.
class GradeStamp extends StatelessWidget {
  const GradeStamp({super.key, required this.reels, required this.limit, this.reducedMotion = false});

  final int reels;
  final int? limit;
  final bool reducedMotion;

  static bool get isEvening => DateTime.now().hour >= 18;

  void _show(BuildContext context, String grade, String line) {
    HapticFeedback.selectionClick();
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: CustomText(text: "Tonight's grade: $grade. $line", color: AppColors.onInverse),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final (grade, color, line) = gradeFor(reels, limit);
    return Semantics(
      button: true,
      label: "Tonight's grade $grade",
      child: GestureDetector(
        onTap: () => _show(context, grade, line),
        child: TweenAnimationBuilder<double>(
          key: ValueKey(grade),
          tween: Tween(begin: reducedMotion ? 1 : 0, end: 1),
          duration: const Duration(milliseconds: 650),
          curve: Curves.easeOutBack,
          builder: (context, t, child) => Opacity(
            opacity: t.clamp(0.0, 1.0),
            child: Transform.rotate(
              angle: -0.22,
              child: Transform.scale(scale: 1 + (1 - t) * 1.4, child: child),
            ),
          ),
          child: Container(
            width: 54,
            height: 54,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.surface,
              border: Border.all(color: color, width: 3),
              boxShadow: [BoxShadow(color: color.withValues(alpha: 0.35), blurRadius: 12, offset: const Offset(0, 3))],
            ),
            child: Container(
              margin: const EdgeInsets.all(4),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: color.withValues(alpha: 0.5), width: 1.2),
              ),
              child: CustomText(text: grade, fontSize: 19, fontWeight: FontWeight.w800, color: color),
            ),
          ),
        ),
      ),
    );
  }
}
