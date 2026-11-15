import 'dart:math';

import 'package:flutter/material.dart';
import 'package:scrollbuddy/core/custom_widgets/custom_text/custom_text.dart';
import 'package:scrollbuddy/core/themes/app_colors.dart';

import '../../core/brain_state.dart';
import '../../core/brain_state_colors.dart';
import '../../core/format.dart';
import '../../core/models.dart';

class _DayCaption extends StatelessWidget {
  const _DayCaption({required this.day, required this.limit, required this.isToday});

  final DayCounts day;
  final int? limit;
  final bool isToday;

  @override
  Widget build(BuildContext context) {
    final state = brainStateFor(day.total, limit: limit);
    final color = stateColors(state).first;
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      child: Row(
        key: ValueKey(day.date),
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          CustomText(text: '${isToday ? 'Today' : shortDate(day.date)} · ', fontSize: 12, color: AppColors.textMuted),
          CustomText(text: '${day.total} reels', fontSize: 12, fontWeight: FontWeight.w700),
          CustomText(text: ' · ${watchTime(day.totalSeconds)}', fontSize: 12, color: AppColors.textMuted),
        ],
      ),
    );
  }
}

class DayBars extends StatefulWidget {
  const DayBars({super.key, required this.days, required this.limit});

  final List<DayCounts> days;
  final int? limit;

  @override
  State<DayBars> createState() => _DayBarsState();
}

class _DayBarsState extends State<DayBars> {
  late int _selected = widget.days.length - 1;

  static const _barArea = 150.0;

  @override
  void didUpdateWidget(DayBars old) {
    super.didUpdateWidget(old);
    if (_selected >= widget.days.length) _selected = widget.days.length - 1;
  }

  @override
  Widget build(BuildContext context) {
    final days = widget.days;
    final limit = widget.limit;
    final top = max(days.fold(0, (a, d) => max(a, d.total)), limit ?? 0).toDouble() * 1.12;
    final scale = top <= 0 ? 0.0 : _barArea / top;
    final thin = days.length > 10;

    return Column(
      children: [
        SizedBox(
          height: _barArea + 24,
          child: Stack(
            children: [
              if (limit != null)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: limit * scale,
                  child: _LimitLine(limit: limit),
                ),
              Positioned.fill(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    for (final (i, d) in days.indexed)
                      Expanded(
                        child: _Bar(
                          height: max(d.total * scale, 6),
                          colors: stateColors(brainStateFor(d.total, limit: limit)),
                          value: d.total,
                          selected: i == _selected,
                          isToday: i == days.length - 1,
                          thin: thin,
                          onTap: () => setState(() => _selected = i),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            for (final (i, d) in days.indexed)
              Expanded(child: Center(child: _label(i, d, thin) ?? const SizedBox.shrink())),
          ],
        ),
        const SizedBox(height: 14),
        _DayCaption(day: days[_selected], limit: limit, isToday: _selected == days.length - 1),
      ],
    );
  }

  Widget? _label(int i, DayCounts d, bool thin) {
    final isToday = i == widget.days.length - 1;
    if (thin && !isToday && i % 5 != 4) return null;
    final sel = i == _selected;
    return CustomText(
      text: isToday ? 'Today' : (thin ? '${d.date.day}' : weekdayLetter(d.date)),
      fontSize: 11,
      maxLines: 1,
      fontWeight: sel || isToday ? FontWeight.w700 : FontWeight.w500,
      color: sel ? AppColors.textPrimary : AppColors.textMuted,
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({
    required this.height,
    required this.colors,
    required this.value,
    required this.selected,
    required this.isToday,
    required this.thin,
    required this.onTap,
  });

  final double height;
  final List<Color> colors;
  final int value;
  final bool selected;
  final bool isToday;
  final bool thin;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final dim = !selected;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: thin ? 1.5 : 7),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            AnimatedOpacity(
              duration: const Duration(milliseconds: 150),
              opacity: selected && !thin ? 1 : 0,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: CustomText(text: '$value', fontSize: 11, fontWeight: FontWeight.w700, maxLines: 1),
              ),
            ),
            TweenAnimationBuilder<double>(
              tween: Tween(end: height),
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeOutCubic,
              builder: (context, h, _) => AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                height: h,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(thin ? 4 : 10),
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [for (final c in colors) dim ? c.withValues(alpha: AppColors.isDark ? 0.45 : 0.4) : c],
                  ),
                  border: isToday && !selected ? Border.all(color: colors.first, width: 1.5) : null,
                  boxShadow: selected && AppColors.isDark
                      ? [BoxShadow(color: colors.last.withValues(alpha: 0.35), blurRadius: 12)]
                      : null,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LimitLine extends StatelessWidget {
  const _LimitLine({required this.limit});

  final int limit;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: CustomPaint(size: const Size.fromHeight(1.5), painter: _DashPainter(AppColors.coral)),
        ),
      ],
    );
  }
}

class _DashPainter extends CustomPainter {
  _DashPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = color.withValues(alpha: 0.7)
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;
    for (var x = 0.0; x < size.width; x += 9) {
      canvas.drawLine(Offset(x, 0), Offset(min(x + 4, size.width), 0), p);
    }
  }

  @override
  bool shouldRepaint(_DashPainter old) => old.color != color;
}

class DayHeatmap extends StatefulWidget {
  const DayHeatmap({super.key, required this.days, required this.limit});

  final List<DayCounts> days;
  final int? limit;

  @override
  State<DayHeatmap> createState() => _DayHeatmapState();
}

class _DayHeatmapState extends State<DayHeatmap> {
  late int _selected = widget.days.length - 1;

  @override
  void didUpdateWidget(DayHeatmap old) {
    super.didUpdateWidget(old);
    if (_selected >= widget.days.length) _selected = widget.days.length - 1;
  }

  @override
  Widget build(BuildContext context) {
    final days = widget.days;
    final limit = widget.limit;
    final lead = days.first.date.weekday - 1;
    final cells = <int?>[for (var i = 0; i < lead; i++) null, for (var i = 0; i < days.length; i++) i];
    final top = max(days.fold(0, (a, d) => max(a, d.total)), 1);

    return Column(
      children: [
        Row(
          children: [
            for (final w in const ['M', 'T', 'W', 'T', 'F', 'S', 'S'])
              Expanded(
                child: Center(
                  child: CustomText(text: w, fontSize: 11, color: AppColors.textMuted),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        for (var r = 0; r < cells.length; r += 7)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              children: [
                for (var c = 0; c < 7; c++)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                      child: AspectRatio(
                        aspectRatio: 1,
                        child: r + c < cells.length && cells[r + c] != null
                            ? _cell(cells[r + c]!, top)
                            : const SizedBox.shrink(),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        const SizedBox(height: 8),
        _DayCaption(day: days[_selected], limit: limit, isToday: _selected == days.length - 1),
        const SizedBox(height: 12),
        const _StateLegend(),
      ],
    );
  }

  Widget _cell(int i, int top) {
    final d = widget.days[i];
    final isToday = i == widget.days.length - 1;
    final sel = i == _selected;
    final colors = stateColors(brainStateFor(d.total, limit: widget.limit));
    final strength = d.total == 0 ? 0.0 : 0.45 + 0.55 * (d.total / top);
    return GestureDetector(
      onTap: () => setState(() => _selected = i),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: d.total == 0 ? AppColors.surfaceHigh : null,
          gradient: d.total == 0
              ? null
              : LinearGradient(
                  begin: Alignment.bottomLeft,
                  end: Alignment.topRight,
                  colors: [for (final c in colors) c.withValues(alpha: strength)],
                ),
          border: sel
              ? Border.all(color: AppColors.textPrimary, width: 2)
              : isToday
              ? Border.all(color: colors.first, width: 1.5)
              : null,
        ),
        alignment: Alignment.center,
        child: CustomText(
          text: '${d.date.day}',
          fontSize: 10,
          fontWeight: sel ? FontWeight.w700 : FontWeight.w500,
          color: d.total == 0 ? AppColors.textMuted : Colors.white,
        ),
      ),
    );
  }
}

class _StateLegend extends StatelessWidget {
  const _StateLegend();

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 12,
      runSpacing: 6,
      children: [
        for (final s in BrainState.values)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(3),
                  gradient: LinearGradient(colors: stateColors(s)),
                ),
              ),
              const SizedBox(width: 5),
              CustomText(text: s.label, fontSize: 10, color: AppColors.textMuted),
            ],
          ),
      ],
    );
  }
}
