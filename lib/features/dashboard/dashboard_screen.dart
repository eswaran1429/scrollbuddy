import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:scrollbuddy/core/custom_widgets/app_button/app_button.dart';
import 'package:scrollbuddy/core/custom_widgets/app_card/app_card.dart';
import 'package:scrollbuddy/core/custom_widgets/app_tile/app_tile.dart';
import 'package:scrollbuddy/core/custom_widgets/blob/soft_blob.dart';
import 'package:scrollbuddy/core/custom_widgets/custom_text/custom_text.dart';
import 'package:scrollbuddy/core/themes/app_colors.dart';

import '../../core/brain_state.dart';
import '../../core/models.dart';
import '../../data/counts_controller.dart';
import '../../data/settings.dart';
import 'brain_view.dart';

/// Count at which the ring is full when no limit is set (start of "fried").
const _ringFullAt = 200;

String _greeting(DateTime now) => switch (now.hour) {
      < 12 => 'Good morning',
      < 17 => 'Good afternoon',
      _ => 'Good evening',
    };

String _mood(int count, BrainState state) => count == 0
    ? 'A fresh start today'
    : switch (state) {
        BrainState.healthy => 'Your brain feels sharp',
        BrainState.tired => 'Your brain is getting foggy',
        BrainState.cracking => 'Maybe time for a break',
        BrainState.fried => 'Your brain needs a rest',
      };

/// Splits [items] into pairs; the last pair may have no second item.
List<(Widget, Widget?)> _pairs(List<Widget> items) => [
      for (var i = 0; i < items.length; i += 2) (items[i], i + 1 < items.length ? items[i + 1] : null),
    ];

/// Blob tint per state: calm green → lavender → peach.
Color _blobColor(BrainState s) => switch (s) {
      BrainState.healthy => AppColors.sageSoft,
      BrainState.tired => AppColors.lavenderSoft,
      BrainState.cracking || BrainState.fried => AppColors.peachSoft,
    };

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final counts = Get.find<CountsController>();
    final settingsCtrl = Get.find<SettingsController>();

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Obx(() {
          final today = counts.today.value;
          final settings = settingsCtrl.settings.value;
          final limit = settings.dailyLimit;
          final state = brainStateFor(today.total, limit: limit);
          final progress = min(today.total / (limit ?? _ringFullAt), 1.0);
          final week = [...counts.lastDays(6), today];

          return ListView(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 120),
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CustomText(
                          text: _greeting(DateTime.now()),
                          fontSize: 26,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.5,
                        ),
                        CustomText(text: _mood(today.total, state), color: AppColors.textMuted),
                      ],
                    ),
                  ),
                  if (kDebugMode) ...[
                    AppIconButton(
                      icon: Icons.bug_report_outlined,
                      tooltip: 'Debug: add reels',
                      onPressed: () => _showDebugSheet(context, counts),
                    ),
                    const SizedBox(width: 8),
                  ],
                  AppIconButton(
                    icon: Icons.tune,
                    tooltip: 'Limits',
                    onPressed: () => context.push('/limits'),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              if (!counts.accessibilityEnabled.value) ...[const _TrackingOffCard(), const SizedBox(height: 20)],
              Center(
                child: SizedBox.square(
                  dimension: 280,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      TweenAnimationBuilder<double>(
                        tween: Tween(end: progress),
                        duration: settings.reducedMotion ? Duration.zero : const Duration(milliseconds: 800),
                        curve: Curves.easeOutCubic,
                        builder: (context, p, _) =>
                            CustomPaint(size: const Size.square(280), painter: _RingPainter(p)),
                      ),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 400),
                        child: SoftBlob(
                          key: ValueKey(state),
                          size: 220,
                          color: _blobColor(state),
                        ),
                      ),
                      BrainView(
                        count: today.total,
                        limit: limit,
                        reducedMotion: settings.reducedMotion,
                        size: 170,
                        showLabel: false,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Semantics(
                label: '${today.total} reels today',
                excludeSemantics: true,
                child: Column(
                  children: [
                    CustomText(
                      text: '${today.total}',
                      fontSize: 64,
                      fontWeight: FontWeight.w700,
                      height: 1.05,
                      letterSpacing: -1.5,
                    ),
                    const CustomText(text: 'reels today', fontSize: 15, color: AppColors.textMuted),
                  ],
                ),
              ),
              if (counts.yesterday != null) ...[
                const SizedBox(height: 12),
                Center(child: _DeltaChip(diff: today.total - counts.yesterday!.total)),
              ],
              if (limit != null) ...[
                const SizedBox(height: 24),
                _LimitCard(total: today.total, settings: settings),
              ],
              const SizedBox(height: 28),
              const CustomText(text: 'Your apps', fontSize: 18, fontWeight: FontWeight.w600),
              const SizedBox(height: 12),
              // Rows of two at natural height (a fixed aspect ratio overflowed on narrow screens).
              for (final pair in _pairs([
                for (final app in TrackedApp.values)
                  if (settings.trackedApps.contains(app))
                    _AppCard(app: app, today: today.of(app), week: [for (final d in week) d.of(app)]),
              ]))
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: pair.$1),
                      const SizedBox(width: 12),
                      Expanded(child: pair.$2 ?? const SizedBox.shrink()),
                    ],
                  ),
                ),
              const SizedBox(height: 20),
              CustomText(
                text: '${state.label} brain. A visualization, not a diagnosis.',
                fontSize: 11,
                textAlign: TextAlign.center,
                color: AppColors.textMuted.withValues(alpha: 0.8),
              ),
            ],
          );
        }),
      ),
    );
  }

  void _showDebugSheet(BuildContext context, CountsController counts) {
    showModalBottomSheet<void>(
      context: context,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const CustomText(text: 'Debug: simulate reels', fontSize: 18, fontWeight: FontWeight.w600),
              const SizedBox(height: 12),
              for (final app in TrackedApp.values)
                Row(
                  children: [
                    IconBadge(icon: app.icon, color: app.color),
                    const SizedBox(width: 12),
                    Expanded(child: CustomText(text: app.label)),
                    TextButton(onPressed: () => counts.debugIncrement(app), child: const CustomText(text: '+1')),
                    TextButton(
                      onPressed: () => counts.debugIncrement(app, 10),
                      child: const CustomText(text: '+10'),
                    ),
                  ],
                ),
              const SizedBox(height: 8),
              AppButton.secondary(label: 'Reset today', icon: Icons.restart_alt, onPressed: counts.resetToday),
            ],
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter(this.progress);

  final double progress;

  Color get _color => progress < 0.5
      ? Color.lerp(AppColors.sage, AppColors.lavender, progress * 2)!
      : Color.lerp(AppColors.lavender, AppColors.coral, (progress - 0.5) * 2)!;

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 14.0;
    final rect = Rect.fromCircle(center: size.center(Offset.zero), radius: size.width / 2 - stroke / 2);
    canvas.drawArc(
      rect,
      0,
      2 * pi,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..color = AppColors.surfaceHigh,
    );
    if (progress <= 0) return;
    canvas.drawArc(
      rect,
      -pi / 2,
      2 * pi * progress,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round
        ..color = _color,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.progress != progress;
}

class _TrackingOffCard extends StatelessWidget {
  const _TrackingOffCard();

  @override
  Widget build(BuildContext context) {
    return AppCard(
      color: AppColors.peachSoft,
      radius: 24,
      padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
      child: Row(
        children: [
          const IconBadge(icon: Icons.pause_circle_outline, color: AppColors.coral, size: 40),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomText(text: 'Tracking is off', fontWeight: FontWeight.w600),
                CustomText(
                  text: 'Counts will not update until Accessibility access is on.',
                  fontSize: 12,
                  color: AppColors.textMuted,
                ),
              ],
            ),
          ),
          AppButton.text(
            label: 'Fix',
            compact: true,
            expand: false,
            onPressed: () => context.push('/onboarding?step=1'),
          ),
        ],
      ),
    );
  }
}

class _DeltaChip extends StatelessWidget {
  const _DeltaChip({required this.diff});

  final int diff;

  @override
  Widget build(BuildContext context) {
    final (text, fg, bg) = switch (diff) {
      0 => ('Same as yesterday', AppColors.textMuted, AppColors.surfaceHigh),
      > 0 => ('$diff more than yesterday', AppColors.coral, AppColors.peachSoft),
      _ => ('${-diff} fewer than yesterday', AppColors.sage, AppColors.sageSoft),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
      child: CustomText(text: text, fontSize: 13, fontWeight: FontWeight.w600, color: fg),
    );
  }
}

class _AppCard extends StatelessWidget {
  const _AppCard({required this.app, required this.today, required this.week});

  final TrackedApp app;
  final int today;
  final List<int> week;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '${app.label}: $today today',
      excludeSemantics: true,
      child: AppCard(
        radius: 24,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                IconBadge(icon: app.icon, color: app.color, size: 34),
                const Spacer(),
                CustomText(text: '$today', fontSize: 22, fontWeight: FontWeight.w700),
              ],
            ),
            const SizedBox(height: 6),
            CustomText(text: app.label, fontSize: 13, color: AppColors.textMuted),
            const SizedBox(height: 12),
            SizedBox(
              height: 26,
              width: double.infinity,
              child: CustomPaint(painter: _SparklinePainter(week, app.color)),
            ),
          ],
        ),
      ),
    );
  }
}

/// Last 7 days as a smooth line; today's point is a dot.
class _SparklinePainter extends CustomPainter {
  _SparklinePainter(this.values, this.color);

  final List<int> values;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.length < 2) return;
    final maxV = max(values.reduce(max), 1);
    final pts = [
      for (final (i, v) in values.indexed)
        Offset(size.width * i / (values.length - 1), size.height - 3 - (size.height - 6) * v / maxV),
    ];
    final path = Path()..moveTo(pts.first.dx, pts.first.dy);
    for (var i = 1; i < pts.length; i++) {
      final mid = Offset((pts[i - 1].dx + pts[i].dx) / 2, (pts[i - 1].dy + pts[i].dy) / 2);
      path.quadraticBezierTo(pts[i - 1].dx, pts[i - 1].dy, mid.dx, mid.dy);
    }
    path.lineTo(pts.last.dx, pts.last.dy);
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round
        ..color = color.withValues(alpha: 0.85),
    );
    canvas.drawCircle(pts.last, 3.5, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_SparklinePainter old) => old.values != values || old.color != color;
}

class _LimitCard extends StatelessWidget {
  const _LimitCard({required this.total, required this.settings});

  final int total;
  final AppSettings settings;

  @override
  Widget build(BuildContext context) {
    final limit = settings.dailyLimit!;
    final left = limit - total;
    return AppCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const IconBadge(icon: Icons.flag_outlined, color: AppColors.lavender, size: 32),
              const SizedBox(width: 12),
              const Expanded(child: CustomText(text: 'Daily limit', fontWeight: FontWeight.w600)),
              CustomText(text: '$total of $limit', color: AppColors.textMuted),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: min(total / limit, 1),
              minHeight: 8,
              color: left > 0 ? AppColors.lavender : AppColors.coral,
              backgroundColor: AppColors.lavenderSoft,
            ),
          ),
          const SizedBox(height: 10),
          CustomText(
            text: left > 0
                ? '$left left today${settings.blockingEnabled ? ' · reels pause at the limit' : ''}'
                : settings.blockingEnabled
                    ? 'Limit reached. Reels are paused.'
                    : 'Limit reached. Blocking is off.',
            fontSize: 13,
            color: AppColors.textMuted,
          ),
        ],
      ),
    );
  }
}
