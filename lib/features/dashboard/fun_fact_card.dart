import 'package:flutter/material.dart';
import 'package:scrollbuddy/core/custom_widgets/app_card/app_card.dart';
import 'package:scrollbuddy/core/custom_widgets/custom_text/custom_text.dart';
import 'package:scrollbuddy/core/themes/app_colors.dart';

/// Silly-but-true comparisons for today's reels. Tap for the next one.
List<(IconData, String)> funFacts(int reels, int seconds) {
  final metres = reels * 0.12;
  final minutes = seconds / 60;
  String n(double v) => v >= 10 ? v.round().toString() : v.toStringAsFixed(1);
  return [
    (Icons.straighten, 'Thumb mileage: ${metres.round()} m. ${_distance(metres)}'),
    if (minutes >= 3) (Icons.music_note_outlined, 'That time = ${n(minutes / 3.5)} songs you could have sung badly.'),
    if (minutes >= 10) (Icons.egg_outlined, 'You could have boiled ${n(minutes / 10)} eggs. Perfectly.'),
    if (minutes >= 22) (Icons.tv_outlined, 'Equal to ${n(minutes / 22)} sitcom episodes. With laugh track.'),
    if (minutes >= 2) (Icons.menu_book_outlined, 'Or about ${(minutes / 2).round()} pages of a book.'),
    if (minutes >= 20) (Icons.directions_walk, 'Or a ${n(minutes / 60 * 5)} km walk. Just saying.'),
    (Icons.swipe_up_outlined, '$reels swipes. Your thumb deserves a tiny medal.'),
  ];
}

String _distance(double m) {
  if (m >= 828) return "That's taller than the Burj Khalifa.";
  if (m >= 330) return "That's taller than the Eiffel Tower.";
  if (m >= 105) return "That's longer than a football pitch.";
  if (m >= 50) return "That's an Olympic pool. Swim it next time?";
  if (m >= 10) return "That's a city bus, end to end.";
  return 'Barely a stroll. Keep it that way.';
}

class FunFactCard extends StatefulWidget {
  const FunFactCard({super.key, required this.reels, required this.seconds});

  final int reels;
  final int seconds;

  @override
  State<FunFactCard> createState() => _FunFactCardState();
}

class _FunFactCardState extends State<FunFactCard> {
  /// Starts on a different fact each day.
  int _i = DateTime.now().day;

  @override
  Widget build(BuildContext context) {
    final facts = funFacts(widget.reels, widget.seconds);
    final (icon, text) = facts[_i % facts.length];
    return AppCard(
      padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
      onTap: () => setState(() => _i++),
      child: Row(
        children: [
          Icon(icon, color: AppColors.lavender, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Align(
                key: ValueKey(text),
                alignment: Alignment.centerLeft,
                child: CustomText(text: text, fontSize: 13, fontWeight: FontWeight.w500, height: 1.35),
              ),
            ),
          ),
          Icon(Icons.refresh_rounded, size: 18, color: AppColors.textMuted),
        ],
      ),
    );
  }
}
