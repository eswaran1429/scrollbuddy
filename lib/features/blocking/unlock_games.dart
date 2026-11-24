import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:scrollbuddy/core/custom_widgets/custom_text/custom_text.dart';
import 'package:scrollbuddy/core/themes/app_colors.dart';

/// Unlocks used today, kept in memory. Each one makes the next game a bit harder.
class UnlockGames {
  static String _day = '';
  static int _played = 0;

  static String _today() => DateTime.now().toIso8601String().substring(0, 10);

  static int get playedToday => _day == _today() ? _played : 0;

  static void markPlayed() {
    final t = _today();
    _played = _day == t ? _played + 1 : 1;
    _day = t;
  }
}

/// Picks one of the two games at random and calls [onWin] when it is beaten.
class UnlockGame extends StatefulWidget {
  const UnlockGame({super.key, required this.onWin});

  final VoidCallback onWin;

  @override
  State<UnlockGame> createState() => _UnlockGameState();
}

class _UnlockGameState extends State<UnlockGame> {
  final _holdGame = Random().nextBool();

  @override
  Widget build(BuildContext context) {
    final level = UnlockGames.playedToday;
    return _holdGame
        ? _HoldToCalm(seconds: 8 + level * 3, onWin: widget.onWin)
        : _BubblePop(count: 15 + level * 5, onWin: widget.onWin);
  }
}

/// Keep a finger on the cat until the ring fills. Letting go starts over.
class _HoldToCalm extends StatefulWidget {
  const _HoldToCalm({required this.seconds, required this.onWin});

  final int seconds;
  final VoidCallback onWin;

  @override
  State<_HoldToCalm> createState() => _HoldToCalmState();
}

class _HoldToCalmState extends State<_HoldToCalm> with SingleTickerProviderStateMixin {
  late final _c =
      AnimationController(
        vsync: this,
        duration: Duration(seconds: widget.seconds),
      )..addStatusListener((s) {
        if (s == AnimationStatus.completed) {
          HapticFeedback.mediumImpact();
          widget.onWin();
        }
      });
  bool _holding = false;

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  void _down() {
    HapticFeedback.selectionClick();
    setState(() => _holding = true);
    _c.forward();
  }

  void _up() {
    if (_c.isCompleted) return;
    setState(() => _holding = false);
    _c.animateBack(0, duration: const Duration(milliseconds: 300));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CustomText(text: 'Calm the cat', fontWeight: FontWeight.w700, fontSize: 16),
        CustomText(
          text: 'Hold your finger on it for ${widget.seconds} seconds. Let go and it panics again.',
          fontSize: 12,
          color: AppColors.textMuted,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        GestureDetector(
          onTapDown: (_) => _down(),
          onTapUp: (_) => _up(),
          onTapCancel: _up,
          child: AnimatedBuilder(
            animation: _c,
            builder: (context, _) {
              final shake = _holding ? 0.0 : sin(DateTime.now().millisecondsSinceEpoch / 60) * 3;
              return SizedBox.square(
                dimension: 140,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox.expand(
                      child: CircularProgressIndicator(
                        value: _c.value,
                        strokeWidth: 8,
                        backgroundColor: AppColors.surfaceHigh,
                        color: AppColors.sage,
                      ),
                    ),
                    Transform.translate(
                      offset: Offset(shake, 0),
                      child: AnimatedScale(
                        scale: _holding ? 0.92 : 1,
                        duration: const Duration(milliseconds: 150),
                        child: Image.asset('assets/images/logo_mark.png', width: 100, cacheWidth: 300),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        CustomText(
          text: _holding ? 'Shhh... ${((1 - _c.value) * widget.seconds).ceil()}s' : 'Press and hold',
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppColors.sage,
        ),
      ],
    );
  }
}

/// Pop every bubble. They drift a little so it is not too easy.
class _BubblePop extends StatefulWidget {
  const _BubblePop({required this.count, required this.onWin});

  final int count;
  final VoidCallback onWin;

  @override
  State<_BubblePop> createState() => _BubblePopState();
}

class _Bubble {
  _Bubble(this.x, this.y, this.r, this.phase, this.color);

  final double x;
  final double y;
  final double r;
  final double phase;
  final Color color;
}

class _BubblePopState extends State<_BubblePop> with SingleTickerProviderStateMixin {
  static const _colors = [AppColors.lavender, AppColors.lilac, AppColors.sage, AppColors.amber, AppColors.coral];
  final _rand = Random();
  late final _bubbles = [
    for (var i = 0; i < widget.count; i++)
      _Bubble(
        0.08 + _rand.nextDouble() * 0.84,
        0.1 + _rand.nextDouble() * 0.8,
        14 + _rand.nextDouble() * 10,
        _rand.nextDouble() * 2 * pi,
        _colors[_rand.nextInt(_colors.length)],
      ),
  ];
  late final _ticker = AnimationController(vsync: this, duration: const Duration(seconds: 4))..repeat();

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  Offset _pos(_Bubble b, Size size) {
    final t = _ticker.value * 2 * pi;
    return Offset(b.x * size.width + sin(t + b.phase) * 8, b.y * size.height + cos(t + b.phase) * 6);
  }

  void _tap(Offset p, Size size) {
    for (final b in _bubbles.reversed) {
      if ((_pos(b, size) - p).distance <= b.r + 6) {
        HapticFeedback.lightImpact();
        setState(() => _bubbles.remove(b));
        if (_bubbles.isEmpty) widget.onWin();
        return;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CustomText(text: 'Pop them all', fontWeight: FontWeight.w700, fontSize: 16),
        CustomText(
          text: '${_bubbles.length} bubbles between you and more reels.',
          fontSize: 12,
          color: AppColors.textMuted,
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, c) {
            final size = Size(c.maxWidth, 200);
            return GestureDetector(
              onTapDown: (d) => _tap(d.localPosition, size),
              child: Container(
                width: size.width,
                height: size.height,
                decoration: BoxDecoration(color: AppColors.surfaceHigh, borderRadius: BorderRadius.circular(16)),
                child: AnimatedBuilder(
                  animation: _ticker,
                  builder: (context, _) => CustomPaint(painter: _BubblePainter(_bubbles, _pos, size)),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _BubblePainter extends CustomPainter {
  _BubblePainter(this.bubbles, this.pos, this.area);

  final List<_Bubble> bubbles;
  final Offset Function(_Bubble, Size) pos;
  final Size area;

  @override
  void paint(Canvas canvas, Size size) {
    final fill = Paint();
    final shine = Paint()..color = Colors.white.withValues(alpha: 0.7);
    for (final b in bubbles) {
      final p = pos(b, area);
      fill.shader = RadialGradient(
        colors: [b.color.withValues(alpha: 0.35), b.color.withValues(alpha: 0.85)],
      ).createShader(Rect.fromCircle(center: p, radius: b.r));
      canvas.drawCircle(p, b.r, fill);
      canvas.drawCircle(p + Offset(-b.r * 0.35, -b.r * 0.35), b.r * 0.22, shine);
    }
  }

  @override
  bool shouldRepaint(_BubblePainter old) => true;
}
