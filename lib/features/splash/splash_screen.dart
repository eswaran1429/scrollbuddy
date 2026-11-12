import 'dart:math';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:scrollbuddy/core/custom_widgets/blob/soft_blob.dart';
import 'package:scrollbuddy/core/custom_widgets/custom_text/custom_text.dart';
import 'package:scrollbuddy/core/themes/app_colors.dart';

import '../../data/counts_controller.dart';
import '../../data/settings.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  static const duration = Duration(milliseconds: 3400);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  // preserve: otherwise Flutter cuts the duration to 5% when the phone has animations off.
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: SplashScreen.duration,
    animationBehavior: AnimationBehavior.preserve,
  );

  late final _logoScale = TweenSequence<double>([
    TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.15).chain(CurveTween(curve: Curves.easeOutCubic)), weight: 24),
    TweenSequenceItem(tween: Tween(begin: 1.15, end: 0.94).chain(CurveTween(curve: Curves.easeInOut)), weight: 6),
    TweenSequenceItem(tween: Tween(begin: 0.94, end: 1.0).chain(CurveTween(curve: Curves.easeOut)), weight: 6),
    TweenSequenceItem(tween: ConstantTween(1.0), weight: 64),
  ]).animate(_c);
  late final _blob = CurvedAnimation(
    parent: _c,
    curve: const Interval(0.05, 0.3, curve: Curves.easeOutBack),
  );
  late final _sparks = CurvedAnimation(
    parent: _c,
    curve: const Interval(0.3, 0.45, curve: Curves.easeOut),
  );
  late final _title = CurvedAnimation(
    parent: _c,
    curve: const Interval(0.38, 0.55, curve: Curves.easeOutCubic),
  );
  late final _tagline = CurvedAnimation(
    parent: _c,
    curve: const Interval(0.48, 0.62, curve: Curves.easeOut),
  );

  final _burst = _BurstParticle.generate(44);
  final _floaters = _FloatParticle.generate(30);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _c.forward().whenComplete(_done));
  }

  Future<void> _done() async {
    // Opened by the service at a reel limit: go straight to the block screen.
    final block = await Get.find<CountsController>().bridge.takeBlockRequest();
    if (!mounted) return;
    final onboarded = Get.find<SettingsController>().settings.value.onboardingDone;
    context.go(!onboarded ? '/onboarding' : (block ? '/block' : '/'));
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: RepaintBoundary(child: CustomPaint(painter: _FloatPainter(_c, _floaters))),
          ),
          Center(child: _content()),
        ],
      ),
    );
  }

  Widget _content() {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        final t = _c.value;
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox.square(
              dimension: 240,
              child: Stack(
                alignment: Alignment.center,
                clipBehavior: Clip.none,
                children: [
                  Opacity(
                    opacity: _blob.value.clamp(0.0, 1.0),
                    child: Transform.scale(
                      scale: 0.6 + 0.4 * _blob.value,
                      child: SoftBlob(size: 220, color: AppColors.lavenderSoft),
                    ),
                  ),
                  Transform.scale(
                    scale: _logoScale.value,
                    child: Image.asset(
                      'assets/images/logo_mark.png',
                      width: 160,
                      height: 160,
                      semanticLabel: 'ScrollBuddy',
                    ),
                  ),
                  Positioned(
                    top: 30,
                    right: 34,
                    child: CustomPaint(size: const Size(34, 34), painter: _SparksPainter(_sparks.value)),
                  ),
                  Positioned.fill(child: CustomPaint(painter: _BurstPainter(t, _burst))),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Opacity(
              opacity: _title.value,
              child: Transform.translate(
                offset: Offset(0, 18 * (1 - _title.value)),
                child: const CustomText(
                  text: 'ScrollBuddy',
                  fontSize: 30,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Opacity(
              opacity: _tagline.value,
              child: CustomText(text: 'Every reel, counted.', color: AppColors.textMuted),
            ),
          ],
        );
      },
    );
  }
}

const _particleColors = [AppColors.lavender, AppColors.lilac, AppColors.sage, AppColors.amber400, AppColors.coral];

enum _Shape { dot, star, square }

/// One piece of confetti thrown out from the logo when it lands.
class _BurstParticle {
  const _BurstParticle(this.dir, this.distance, this.size, this.color, this.delay, this.shape, this.spin);

  final Offset dir;
  final double distance;
  final double size;
  final Color color;
  final double delay;
  final _Shape shape;
  final double spin;

  static List<_BurstParticle> generate(int n) {
    final r = Random(7);
    return [
      for (var i = 0; i < n; i++)
        () {
          final a = (i / n) * 2 * pi + r.nextDouble() * 0.3;
          return _BurstParticle(
            Offset(cos(a), sin(a)),
            110 + r.nextDouble() * 120,
            4 + r.nextDouble() * 6,
            _particleColors[r.nextInt(_particleColors.length)],
            r.nextDouble() * 0.04,
            _Shape.values[r.nextInt(_Shape.values.length)],
            (r.nextBool() ? 1 : -1) * (4 + r.nextDouble() * 6) * pi,
          );
        }(),
    ];
  }
}

/// Confetti flies out, spins, falls a little, then shrinks and fades.
class _BurstPainter extends CustomPainter {
  _BurstPainter(this.t, this.particles);

  final double t;
  final List<_BurstParticle> particles;

  static const _start = 0.22;
  static const _length = 0.36;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final paint = Paint();
    for (final p in particles) {
      final k = ((t - _start - p.delay) / _length).clamp(0.0, 1.0);
      if (k <= 0 || k >= 1) continue;
      final travel = Curves.easeOutCubic.transform(k);
      final pos = c + p.dir * (50 + p.distance * travel) + Offset(0, 40 * k * k);
      final s = p.size * (1 - 0.6 * k);
      paint.color = p.color.withValues(alpha: (1 - k * k).clamp(0.0, 1.0));
      canvas
        ..save()
        ..translate(pos.dx, pos.dy)
        ..rotate(p.spin * k);
      switch (p.shape) {
        case _Shape.dot:
          canvas.drawCircle(Offset.zero, s / 2, paint);
        case _Shape.square:
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromCenter(center: Offset.zero, width: s, height: s * 0.6),
              Radius.circular(s * 0.15),
            ),
            paint,
          );
        case _Shape.star:
          canvas.drawPath(_sparkle(s * 0.8), paint);
      }
      canvas.restore();
    }
  }

  /// Four-point sparkle centred on the origin.
  static Path _sparkle(double r) {
    final i = r * 0.3;
    return Path()
      ..moveTo(0, -r)
      ..quadraticBezierTo(i * 0.3, -i * 0.3, r, 0)
      ..quadraticBezierTo(i * 0.3, i * 0.3, 0, r)
      ..quadraticBezierTo(-i * 0.3, i * 0.3, -r, 0)
      ..quadraticBezierTo(-i * 0.3, -i * 0.3, 0, -r)
      ..close();
  }

  @override
  bool shouldRepaint(_BurstPainter old) => old.t != t;
}

/// Soft dot drifting upward in the background.
class _FloatParticle {
  const _FloatParticle(this.x, this.y, this.rise, this.sway, this.phase, this.radius, this.color);

  final double x;
  final double y;
  final double rise;
  final double sway;
  final double phase;
  final double radius;
  final Color color;

  static List<_FloatParticle> generate(int n) {
    final r = Random(11);
    return [
      for (var i = 0; i < n; i++)
        _FloatParticle(
          r.nextDouble(),
          r.nextDouble(),
          0.25 + r.nextDouble() * 0.35,
          8 + r.nextDouble() * 16,
          r.nextDouble() * 2 * pi,
          2 + r.nextDouble() * 4,
          _particleColors[r.nextInt(_particleColors.length)],
        ),
    ];
  }
}

/// Background dots: fade in, then rise, sway and twinkle.
class _FloatPainter extends CustomPainter {
  _FloatPainter(this.anim, this.particles) : super(repaint: anim);

  final Animation<double> anim;
  final List<_FloatParticle> particles;

  @override
  void paint(Canvas canvas, Size size) {
    final t = anim.value;
    final fadeIn = (t / 0.15).clamp(0.0, 1.0);
    if (fadeIn <= 0) return;
    final base = AppColors.isDark ? 0.75 : 0.6;
    final paint = Paint();
    for (final p in particles) {
      final y = ((p.y - t * p.rise) % 1.0) * size.height;
      final x = p.x * size.width + sin(t * 3 * pi + p.phase) * p.sway;
      final twinkle = 0.6 + 0.4 * sin(t * 8 * pi + p.phase);
      paint.color = p.color.withValues(alpha: fadeIn * base * twinkle);
      canvas.drawCircle(Offset(x, y), p.radius, paint);
    }
  }

  @override
  bool shouldRepaint(_FloatPainter old) => false;
}

/// Three short yellow strokes that grow outward one after another.
class _SparksPainter extends CustomPainter {
  _SparksPainter(this.progress);

  final double progress;

  static const _lines = [
    (Offset(4, 22), Offset(10, 4)),
    (Offset(12, 26), Offset(28, 12)),
    (Offset(16, 32), Offset(33, 30)),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;
    final paint = Paint()
      ..color = AppColors.amber400
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    for (final (i, (a, b)) in _lines.indexed) {
      // Stagger: each line starts a third later than the previous one.
      final p = ((progress - i * 0.2) / 0.6).clamp(0.0, 1.0);
      if (p > 0) canvas.drawLine(a, Offset.lerp(a, b, p)!, paint);
    }
  }

  @override
  bool shouldRepaint(_SparksPainter old) => old.progress != progress;
}
