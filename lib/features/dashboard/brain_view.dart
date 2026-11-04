import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/brain_state.dart';
import 'package:scrollbuddy/core/custom_widgets/custom_text/custom_text.dart';

/// Placeholder brain visual (D-17). Swap the painter for Rive artwork later;
/// the widget API (count, limit, reducedMotion) stays the same.
class BrainView extends StatefulWidget {
  const BrainView({
    super.key,
    required this.count,
    this.limit,
    this.reducedMotion = false,
    this.size = 220,
    this.showLabel = true,
  });

  final int count;
  final int? limit;
  final bool reducedMotion;
  final double size;
  final bool showLabel;

  @override
  State<BrainView> createState() => _BrainViewState();
}

class _BrainViewState extends State<BrainView> with SingleTickerProviderStateMixin {
  late final AnimationController _breath = AnimationController(vsync: this, duration: const Duration(seconds: 3));

  @override
  void initState() {
    super.initState();
    if (!widget.reducedMotion) _breath.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(BrainView old) {
    super.didUpdateWidget(old);
    if (brainStateFor(old.count, limit: old.limit) != brainStateFor(widget.count, limit: widget.limit)) {
      HapticFeedback.mediumImpact();
    }
    if (widget.reducedMotion && _breath.isAnimating) {
      _breath.stop();
      _breath.value = 0;
    } else if (!widget.reducedMotion && !_breath.isAnimating) {
      _breath.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _breath.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final damage = brainDamage(widget.count, limit: widget.limit);
    final state = brainStateFor(widget.count, limit: widget.limit);
    final text = Theme.of(context).textTheme;
    return Semantics(
      label: 'Brain visual: ${state.label}. ${state.description}.',
      excludeSemantics: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(end: damage),
            duration: widget.reducedMotion ? Duration.zero : const Duration(milliseconds: 700),
            curve: Curves.easeOutCubic,
            builder: (context, d, _) => AnimatedBuilder(
              animation: _breath,
              builder: (context, _) => CustomPaint(
                size: Size.square(widget.size),
                painter: BrainPainter(damage: d, breath: _breath.value),
              ),
            ),
          ),
          if (widget.showLabel) ...[
            CustomText(
              text: state.label,
              style: text.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            CustomText(
              text: 'A visualization, not a diagnosis',
              style: text.labelSmall?.copyWith(color: Theme.of(context).colorScheme.outline),
            ),
          ],
        ],
      ),
    );
  }
}

/// Draws the brain for a continuous [damage] in 0..3 (see [brainDamage]).
class BrainPainter extends CustomPainter {
  BrainPainter({required this.damage, required this.breath});

  final double damage;

  /// 0..1 idle breathing phase.
  final double breath;

  static const _stops = [
    Color(0xFFFF8FB8), // healthy
    Color(0xFFDDA0B4), // tired
    Color(0xFFB08894), // cracking
    Color(0xFF7D7576), // fried
  ];

  Color get _color {
    final d = damage.clamp(0.0, 3.0);
    final i = d.floor().clamp(0, 2);
    return Color.lerp(_stops[i], _stops[i + 1], d - i)!;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final c = Offset(w / 2, size.height * 0.56);
    final r = w * 0.32;
    final body = _color;
    final ink = Color.lerp(body, Colors.black, 0.45)!;

    canvas.save();
    final s = 1 + breath * 0.025;
    canvas
      ..translate(c.dx, c.dy)
      ..scale(s)
      ..translate(-c.dx, -c.dy);

    // Glow when healthy.
    final glow = (1 - damage).clamp(0.0, 1.0);
    if (glow > 0) {
      canvas.drawCircle(
        c,
        r * 1.3,
        Paint()
          ..color = body.withValues(alpha: 0.15 * glow)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, r * 0.3),
      );
    }

    // Bumpy outline: ellipse plus ring of circles.
    var shape = Path()..addOval(Rect.fromCenter(center: c, width: r * 1.8, height: r * 1.35));
    for (var k = 0; k < 10; k++) {
      final a = 2 * pi * k / 10;
      final bump = Path()
        ..addOval(Rect.fromCircle(center: c + Offset(cos(a) * r * 0.72, sin(a) * r * 0.5), radius: r * 0.4));
      shape = Path.combine(PathOperation.union, shape, bump);
    }
    canvas.drawPath(shape, Paint()..color = body);
    final line = Paint()
      ..color = ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.016
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(shape, line);

    // Middle fissure and folds.
    final fold = Paint()
      ..color = ink.withValues(alpha: 0.45)
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.012
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(
      Path()
        ..moveTo(c.dx, c.dy - r * 0.88)
        ..quadraticBezierTo(c.dx - r * 0.08, c.dy - r * 0.55, c.dx, c.dy - r * 0.3),
      fold,
    );
    for (final side in [-1.0, 1.0]) {
      canvas.drawArc(
        Rect.fromCircle(center: c + Offset(side * r * 0.62, -r * 0.48), radius: r * 0.22),
        side < 0 ? pi * 0.1 : pi * 0.4,
        pi * 0.5,
        false,
        fold,
      );
      canvas.drawArc(
        Rect.fromCircle(center: c + Offset(side * r * 0.95, r * 0.05), radius: r * 0.18),
        side < 0 ? -pi * 0.3 : pi * 0.8,
        pi * 0.5,
        false,
        fold,
      );
    }

    // Cracks fade in from the cracking band.
    final crack = (damage - 1.4).clamp(0.0, 1.0);
    if (crack > 0) {
      final p = Paint()
        ..color = ink.withValues(alpha: crack)
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.014
        ..strokeJoin = StrokeJoin.round;
      canvas.drawPath(
        Path()
          ..moveTo(c.dx - r * 0.55, c.dy - r * 0.7)
          ..lineTo(c.dx - r * 0.42, c.dy - r * 0.5)
          ..lineTo(c.dx - r * 0.56, c.dy - r * 0.38)
          ..lineTo(c.dx - r * 0.44, c.dy - r * 0.22),
        p,
      );
      if (damage > 2.2) {
        canvas.drawPath(
          Path()
            ..moveTo(c.dx + r * 0.9, c.dy - r * 0.35)
            ..lineTo(c.dx + r * 0.72, c.dy - r * 0.25)
            ..lineTo(c.dx + r * 0.8, c.dy - r * 0.08)
            ..lineTo(c.dx + r * 0.62, c.dy + r * 0.02),
          p,
        );
      }
    }

    _drawFace(canvas, c, r, w, ink);

    // Smoke when fried.
    final smoke = ((damage - 2.4) / 0.6).clamp(0.0, 1.0);
    if (smoke > 0) {
      final puff = Paint()..color = Colors.grey.withValues(alpha: 0.45 * smoke);
      for (var k = 0; k < 3; k++) {
        final rise = (breath + k / 3) % 1;
        canvas.drawCircle(
          Offset(c.dx + (k - 1) * r * 0.45, c.dy - r * 1.05 - rise * r * 0.35),
          r * (0.1 + 0.06 * rise),
          puff,
        );
      }
    }

    canvas.restore();
  }

  void _drawFace(Canvas canvas, Offset c, double r, double w, Color ink) {
    final p = Paint()
      ..color = ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.02
      ..strokeCap = StrokeCap.round;
    final fill = Paint()..color = ink;
    final eyeY = c.dy + r * 0.05;
    final eyes = [Offset(c.dx - r * 0.32, eyeY), Offset(c.dx + r * 0.32, eyeY)];
    final mouth = Offset(c.dx, c.dy + r * 0.38);
    final e = r * 0.1;

    switch (BrainState.values[damage.floor().clamp(0, 3)]) {
      case BrainState.healthy:
        for (final o in eyes) {
          canvas.drawArc(Rect.fromCircle(center: o, radius: e), pi, pi, false, p);
        }
        canvas.drawArc(
          Rect.fromCircle(center: mouth - Offset(0, r * 0.12), radius: r * 0.2),
          pi * 0.15,
          pi * 0.7,
          false,
          p,
        );
      case BrainState.tired:
        for (final o in eyes) {
          canvas.drawLine(o - Offset(e, 0), o + Offset(e, 0), p);
          canvas.drawArc(Rect.fromCircle(center: o, radius: e), 0, pi, false, p);
        }
        canvas.drawOval(Rect.fromCenter(center: mouth, width: r * 0.16, height: r * 0.22), fill);
      case BrainState.cracking:
        for (final (i, o) in eyes.indexed) {
          canvas.drawCircle(o, e * 0.6, fill);
          final dir = i == 0 ? 1 : -1;
          canvas.drawLine(o + Offset(-e * dir, -e * 2.0), o + Offset(e * dir, -e * 1.4), p);
        }
        final wave = Path()..moveTo(mouth.dx - r * 0.2, mouth.dy);
        for (var k = 1; k <= 4; k++) {
          wave.lineTo(mouth.dx - r * 0.2 + k * r * 0.1, mouth.dy + (k.isOdd ? -1 : 1) * r * 0.05);
        }
        canvas.drawPath(wave, p);
      case BrainState.fried:
        for (final o in eyes) {
          canvas.drawLine(o - Offset(e, e), o + Offset(e, e), p);
          canvas.drawLine(o + Offset(-e, e), o + Offset(e, -e), p);
        }
        canvas.drawLine(mouth - Offset(r * 0.18, 0), mouth + Offset(r * 0.18, 0), p);
    }
  }

  @override
  bool shouldRepaint(BrainPainter old) => old.damage != damage || old.breath != breath;
}
