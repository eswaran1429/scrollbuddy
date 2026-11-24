import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:scrollbuddy/core/custom_widgets/app_button/app_button.dart';
import 'package:scrollbuddy/core/custom_widgets/app_card/app_card.dart';
import 'package:scrollbuddy/core/custom_widgets/app_tile/app_tile.dart';
import 'package:scrollbuddy/core/themes/app_tokens.dart';
import 'package:scrollbuddy/core/custom_widgets/custom_text/custom_text.dart';
import 'package:scrollbuddy/core/custom_widgets/page_header/page_header.dart';
import 'package:scrollbuddy/core/themes/app_colors.dart';

import '../../core/brain_state.dart';
import '../../core/brain_state_colors.dart';
import '../../core/format.dart';
import '../../core/models.dart';
import '../../data/counts_controller.dart';
import '../../data/settings.dart';
import '../../core/rewards.dart';
import 'dressing_room.dart';
import 'fun_fact_card.dart';
import 'mascot_view.dart';
import 'report_card.dart';

const _ringFullAt = 200;

String _greeting(DateTime now) => switch (now.hour) {
  < 12 => 'Good morning',
  < 17 => 'Good afternoon',
  _ => 'Good evening',
};

String _mood(int count, BrainState state) => MascotView.isBedtime
    ? "Past bedtime. Your buddy's asleep"
    : count == 0
    ? 'A fresh start today'
    : switch (state) {
        BrainState.healthy => 'Your brain feels sharp',
        BrainState.tired => 'Your brain is getting foggy',
        BrainState.cracking => 'Maybe time for a break',
        BrainState.fried => 'Your brain needs a rest',
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
          final ringColors = stateColors(state);
          final good = goodDays(counts.past, limit);
          _unlockEarned(context, settingsCtrl, good);

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
            children: [
              PageHeader(
                title: _greeting(DateTime.now()),
                subtitle: _mood(today.total, state),
                actions: [
                  if (kDebugMode)
                    AppIconButton(
                      icon: Icons.bug_report_outlined,
                      tooltip: 'Debug: add reels',
                      onPressed: () => _showDebugSheet(context, counts),
                    ),
                  AppIconButton(
                    icon: AppColors.isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
                    tooltip: AppColors.isDark ? 'Light theme' : 'Dark theme',
                    onPressed: () => settingsCtrl.setThemeMode(AppColors.isDark ? ThemeMode.light : ThemeMode.dark),
                  ),
                  AppIconButton(
                    icon: Icons.settings_outlined,
                    tooltip: 'Settings',
                    onPressed: () => context.push('/settings'),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              if (!counts.accessibilityEnabled.value) ...[const _TrackingOffCard(), const SizedBox(height: 14)],
              _HeroCard(
                glow: ringColors.last,
                stamp: GradeStamp.isEvening
                    ? GradeStamp(reels: today.total, limit: limit, reducedMotion: settings.reducedMotion)
                    : null,
                child: Column(
                  children: [
                    SizedBox.square(
                      dimension: 220,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          TweenAnimationBuilder<double>(
                            tween: Tween(end: progress),
                            duration: settings.reducedMotion ? Duration.zero : const Duration(milliseconds: 800),
                            curve: Curves.easeOutCubic,
                            builder: (context, p, _) =>
                                CustomPaint(size: const Size.square(220), painter: _RingPainter(p, ringColors)),
                          ),
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 400),
                            width: 172,
                            height: 172,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                colors: [
                                  ringColors.first.withValues(alpha: AppColors.isDark ? 0.16 : 0.14),
                                  AppColors.surfaceHigh.withValues(alpha: AppColors.isDark ? 0.9 : 0.6),
                                ],
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: () => showDressingRoom(context, goodDays: good, hasLimit: limit != null),
                            child: MascotView(
                              state: state,
                              reducedMotion: settings.reducedMotion,
                              size: 168,
                              outfit: _healthyLook(today.total, limit, counts.yesterday?.total, settings.outfit),
                            ),
                          ),
                          Positioned(
                            right: 6,
                            bottom: 6,
                            child: OutfitBadge(
                              worn: Reward.byName(settings.outfit),
                              isNew: !settings.dressingRoomSeen,
                              onTap: () => showDressingRoom(context, goodDays: good, hasLimit: limit != null),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    Semantics(
                      label: '${today.total} reels today, ${watchTime(today.totalSeconds)} in reels',
                      excludeSemantics: true,
                      child: Column(
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              CustomText(
                                text: '${today.total}',
                                fontSize: 56,
                                fontWeight: FontWeight.w800,
                                height: 1.0,
                                letterSpacing: -1.5,
                              ),
                              if (limit != null)
                                CustomText(
                                  text: ' / $limit',
                                  fontSize: 20,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textMuted,
                                ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          CustomText(
                            text: 'reels today',
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: AppColors.isDark ? AppColors.lilac : AppColors.lavender,
                          ),
                        ],
                      ),
                    ),
                    if (limit != null) ...[const SizedBox(height: 12), _LimitPill(left: limit - today.total)],
                    const SizedBox(height: 18),
                    _StatsStrip(seconds: today.totalSeconds, total: today.total, yesterday: counts.yesterday?.total),
                  ],
                ),
              ),
              if (today.total > 0) ...[
                const SizedBox(height: 12),
                FunFactCard(reels: today.total, seconds: today.totalSeconds),
              ],
              const SizedBox(height: 20),
              CustomText(
                text: 'Your buddy is ${state.label.toLowerCase()}. A visualization, not a diagnosis.',
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

  /// What the cat looks like while healthy: asleep late at night, cheering on a fresh start
  /// after a good day, otherwise the chosen outfit (or the plain cat).
  String? _healthyLook(int todayTotal, int? limit, int? yesterday, String? outfit) {
    if (MascotView.isBedtime) return MascotView.bedtime;
    if (todayTotal == 0 && limit != null && yesterday != null && yesterday > 0 && yesterday <= limit) {
      return MascotView.happy;
    }
    return Reward.byName(outfit)?.asset;
  }

  /// Saves outfits earned so far and announces new ones (after this frame, not during build).
  void _unlockEarned(BuildContext context, SettingsController ctrl, int good) {
    final earned = earnedRewards(good).map((r) => r.name);
    if (earned.every(ctrl.settings.value.unlockedRewards.contains)) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final fresh = ctrl.unlockRewards(earned);
      if (fresh.isEmpty || !context.mounted) return;
      final names = fresh.map((n) => Reward.byName(n)!.label).join(', ');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: CustomText(
            text: 'New outfit unlocked: $names. Tap the cat to try it on.',
            color: AppColors.onInverse,
          ),
        ),
      );
    });
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
                    TextButton(
                      onPressed: () => counts.debugIncrement(app),
                      child: const CustomText(text: '+1'),
                    ),
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
  _RingPainter(this.progress, this.colors) : dark = AppColors.isDark;

  final double progress;
  final List<Color> colors;
  final bool dark;

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 16.0;
    final center = size.center(Offset.zero);
    final radius = size.width / 2 - stroke / 2 - 4;
    final rect = Rect.fromCircle(center: center, radius: radius);
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..color = AppColors.surfaceHigh,
    );
    if (progress <= 0) return;

    final sweep = 2 * pi * progress;
    final shader = SweepGradient(
      endAngle: sweep,
      colors: colors,
      transform: const GradientRotation(-pi / 2),
    ).createShader(rect);
    if (AppColors.isDark) {
      canvas.drawArc(
        rect,
        -pi / 2,
        sweep,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = stroke
          ..shader = shader
          ..color = Colors.white.withValues(alpha: 0.45)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
      );
    }
    canvas.drawArc(
      rect,
      -pi / 2,
      sweep,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..shader = shader,
    );
    Offset at(double a) => center + Offset(cos(a), sin(a)) * radius;
    canvas.drawCircle(at(-pi / 2), stroke / 2, Paint()..color = colors.first);
    canvas.drawCircle(at(-pi / 2 + sweep), stroke / 2, Paint()..color = colors.last);
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.progress != progress || old.colors != colors || old.dark != dark;
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.glow, required this.child, this.stamp});

  final Color glow;
  final Widget child;

  /// Evening grade, pinned to the card's top-right corner, clear of the ring.
  final Widget? stamp;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      padding: const EdgeInsets.fromLTRB(18, 24, 18, 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.stroke.withValues(alpha: AppColors.isDark ? 0.8 : 0.6)),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color.alphaBlend(glow.withValues(alpha: AppColors.isDark ? 0.12 : 0.06), AppColors.surface),
            AppColors.surface,
          ],
        ),
        boxShadow: AppColors.isDark ? null : AppShadows.sm,
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          child,
          if (stamp != null) Positioned(top: -10, right: -4, child: stamp!),
        ],
      ),
    );
  }
}

class _TrackingOffCard extends StatelessWidget {
  const _TrackingOffCard();

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
      child: Row(
        children: [
          const IconBadge(icon: Icons.pause_circle_outline, color: AppColors.coral, size: 40),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomText(text: 'Tracking is off', fontSize: 13, fontWeight: FontWeight.w600),
                CustomText(
                  text: 'Counts update once Accessibility access is on.',
                  fontSize: 11,
                  color: AppColors.textMuted,
                ),
              ],
            ),
          ),
          AppButton.text(
            label: 'On',
            compact: true,
            expand: false,
            onPressed: () => context.push('/onboarding?step=1'),
          ),
        ],
      ),
    );
  }
}

class _LimitPill extends StatelessWidget {
  const _LimitPill({required this.left});

  final int left;

  @override
  Widget build(BuildContext context) {
    final reached = left <= 0;
    return StatusPill(
      text: reached ? 'Limit reached · reels paused' : '$left left before reels pause',
      icon: reached ? Icons.block : Icons.flag_outlined,
      color: reached ? AppColors.coral : AppColors.lavender,
      background: reached ? AppColors.peachSoft : AppColors.lavenderSoft,
    );
  }
}

class _StatsStrip extends StatelessWidget {
  const _StatsStrip({required this.seconds, required this.total, required this.yesterday});

  final int seconds;
  final int total;
  final int? yesterday;

  @override
  Widget build(BuildContext context) {
    final diff = yesterday == null ? null : total - yesterday!;
    final cells = <Widget>[
      _Stat(icon: Icons.schedule_rounded, color: AppColors.lavender, value: watchTime(seconds), label: 'in reels'),
      if (diff != null)
        _Stat(
          icon: diff > 0
              ? Icons.trending_up_rounded
              : diff < 0
              ? Icons.trending_down_rounded
              : Icons.drag_handle_rounded,
          color: diff > 0
              ? AppColors.coral
              : diff < 0
              ? AppColors.sage
              : AppColors.textMuted,
          value: diff > 0
              ? '+$diff'
              : diff < 0
              ? '−${-diff}'
              : 'Same',
          label: 'vs yesterday',
        ),
    ];
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceHigh.withValues(alpha: AppColors.isDark ? 0.7 : 0.8),
        borderRadius: BorderRadius.circular(18),
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            for (final (i, c) in cells.indexed) ...[
              if (i > 0) VerticalDivider(width: 1, thickness: 1, color: AppColors.stroke),
              Expanded(child: c),
            ],
          ],
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.icon, required this.color, required this.value, required this.label});

  final IconData icon;
  final Color color;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(height: 4),
        CustomText(text: value, fontSize: 14, fontWeight: FontWeight.w700, maxLines: 1),
        CustomText(text: label, fontSize: 10, color: AppColors.textMuted, maxLines: 1),
      ],
    );
  }
}
