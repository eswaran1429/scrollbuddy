import 'dart:math';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:scrollbuddy/core/custom_widgets/blob/soft_blob.dart';
import 'package:scrollbuddy/core/custom_widgets/custom_text/custom_text.dart';
import 'package:scrollbuddy/core/themes/app_colors.dart';

import '../../data/settings.dart';

/// Animated intro (≈1.8 s), then onboarding or Today.
///
/// Timeline (fractions of the controller):
/// - 0.00–0.35  lavender blob grows in behind the mascot
/// - 0.00–0.50  mascot pops (scale up, squash, settle) with a small wobble
/// - 0.30–0.55  three sparks draw in at the top-right
/// - 0.45–0.70  "ScrollBuddy" slides up and fades in
/// - 0.60–0.82  tagline fades in
/// - 0.90–1.00  everything fades out, then navigate
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  static const duration = Duration(milliseconds: 1800);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  late final _blob = CurvedAnimation(parent: _c, curve: const Interval(0, 0.35, curve: Curves.easeOutBack));
  late final _catScale = TweenSequence<double>([
    TweenSequenceItem(tween: Tween(begin: 0.85, end: 1.12).chain(CurveTween(curve: Curves.easeOut)), weight: 20),
    TweenSequenceItem(tween: Tween(begin: 1.12, end: 0.96).chain(CurveTween(curve: Curves.easeInOut)), weight: 15),
    TweenSequenceItem(tween: Tween(begin: 0.96, end: 1.0).chain(CurveTween(curve: Curves.easeOut)), weight: 15),
    TweenSequenceItem(tween: ConstantTween(1.0), weight: 50),
  ]).animate(_c);
  late final _sparks = CurvedAnimation(parent: _c, curve: const Interval(0.3, 0.55, curve: Curves.easeOut));
  late final _title = CurvedAnimation(parent: _c, curve: const Interval(0.45, 0.7, curve: Curves.easeOutCubic));
  late final _tagline = CurvedAnimation(parent: _c, curve: const Interval(0.6, 0.82, curve: Curves.easeOut));
  late final _exit = CurvedAnimation(parent: _c, curve: const Interval(0.9, 1, curve: Curves.easeIn));

  @override
  void initState() {
    super.initState();
    final reduced = Get.find<SettingsController>().settings.value.reducedMotion;
    // Reduced motion: no pop or wobble, just a short pause on the finished frame.
    _c = AnimationController(vsync: this, duration: reduced ? const Duration(milliseconds: 500) : SplashScreen.duration);
    if (reduced) _c.value = 0.85;
    _c.forward().whenComplete(_done);
  }

  void _done() {
    if (!mounted) return;
    final onboarded = Get.find<SettingsController>().settings.value.onboardingDone;
    context.go(onboarded ? '/' : '/onboarding');
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: AnimatedBuilder(
          animation: _c,
          builder: (context, _) {
            // Gentle wobble while the pop settles, fading out by t = 0.5.
            final t = _c.value;
            final wobble = t < 0.5 ? sin(t * 4 * pi) * 0.05 * (1 - t / 0.5) : 0.0;
            return Opacity(
              opacity: 1 - _exit.value,
              child: Transform.scale(
                scale: 1 + _exit.value * 0.06,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox.square(
                      dimension: 240,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Opacity(
                            opacity: _blob.value.clamp(0.0, 1.0),
                            child: Transform.scale(
                              scale: 0.6 + 0.4 * _blob.value,
                              child: const SoftBlob(size: 220, color: AppColors.lavenderSoft),
                            ),
                          ),
                          Transform.rotate(
                            angle: wobble,
                            child: Transform.scale(
                              scale: _catScale.value,
                              child: Image.asset(
                                'assets/images/logo_mark.png',
                                width: 160,
                                height: 160,
                                semanticLabel: 'ScrollBuddy',
                              ),
                            ),
                          ),
                          Positioned(
                            top: 30,
                            right: 34,
                            child: CustomPaint(size: const Size(34, 34), painter: _SparksPainter(_sparks.value)),
                          ),
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
                      child: const CustomText(text: 'Every reel, counted.', color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
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
