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
import 'package:scrollbuddy/core/custom_widgets/page_header/page_header.dart';
import 'package:scrollbuddy/core/themes/app_colors.dart';

import '../../core/brain_state.dart';
import '../../core/format.dart';
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
                    icon: Icons.settings_outlined,
                    tooltip: 'Settings',
                    onPressed: () => context.push('/settings'),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              if (!counts.accessibilityEnabled.value) ...[const _TrackingOffCard(), const SizedBox(height: 14)],
              AppCard(
                padding: const EdgeInsets.fromLTRB(18, 22, 18, 18),
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
                                CustomPaint(size: const Size.square(220), painter: _RingPainter(p)),
                          ),
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 400),
                            child: SoftBlob(key: ValueKey(state), size: 172, color: _blobColor(state)),
                          ),
                          BrainView(
                            count: today.total,
                            limit: limit,
                            reducedMotion: settings.reducedMotion,
                            size: 132,
                            showLabel: false,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    Semantics(
                      label: '${today.total} reels today, ${watchTime(today.totalSeconds)} in reels',
                      excludeSemantics: true,
                      child: Column(
                        children: [
                          CustomText(
                            text: '${today.total}',
                            fontSize: 44,
                            fontWeight: FontWeight.w700,
                            height: 1.05,
                            letterSpacing: -1,
                          ),
                          const CustomText(text: 'reels today', fontSize: 12, color: AppColors.textMuted),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.schedule_rounded, size: 15, color: AppColors.lavender),
                              const SizedBox(width: 5),
                              CustomText(
                                text: '${watchTime(today.totalSeconds)} in reels',
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.lavender,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    if (counts.yesterday != null) ...[
                      const SizedBox(height: 12),
                      _DeltaChip(diff: today.total - counts.yesterday!.total),
                    ],
                  ],
                ),
              ),
              if (limit != null) ...[const SizedBox(height: 14), _LimitCard(total: today.total, settings: settings)],
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
      padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
      child: Row(
        children: [
          const IconBadge(icon: Icons.pause_circle_outline, color: AppColors.coral, size: 40),
          const SizedBox(width: 12),
          const Expanded(
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

class _DeltaChip extends StatelessWidget {
  const _DeltaChip({required this.diff});

  final int diff;

  @override
  Widget build(BuildContext context) {
    final (text, fg, bg, icon) = switch (diff) {
      0 => ('Same as yesterday', AppColors.textMuted, AppColors.surfaceHigh, Icons.drag_handle_rounded),
      > 0 => ('$diff more than yesterday', AppColors.coral, AppColors.peachSoft, Icons.trending_up_rounded),
      _ => ('${-diff} fewer than yesterday', AppColors.sage, AppColors.sageSoft, Icons.trending_down_rounded),
    };
    return StatusPill(text: text, color: fg, background: bg, icon: icon);
  }
}

class _LimitCard extends StatelessWidget {
  const _LimitCard({required this.total, required this.settings});

  final int total;
  final AppSettings settings;

  @override
  Widget build(BuildContext context) {
    final limit = settings.dailyLimit!;
    final left = limit - total;
    final reached = left <= 0;
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const IconBadge(icon: Icons.flag_outlined, color: AppColors.lavender, size: 40),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SectionLabel('Daily limit'),
                    CustomText(text: '$total of $limit', fontSize: 15, fontWeight: FontWeight.w700),
                  ],
                ),
              ),
              StatusPill(
                text: reached ? 'Reached' : '$left left',
                icon: reached ? Icons.block : Icons.check_circle,
                color: reached ? AppColors.coral : AppColors.lavender,
                background: reached ? AppColors.peachSoft : AppColors.lavenderSoft,
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: min(total / limit, 1),
              minHeight: 6,
              color: reached ? AppColors.coral : AppColors.lavender,
              backgroundColor: AppColors.lavenderSoft,
            ),
          ),
          const SizedBox(height: 10),
          CustomText(
            text: reached ? 'Limit reached. Reels are paused.' : 'Reels pause at the limit',
            fontSize: 11,
            color: AppColors.textMuted,
          ),
        ],
      ),
    );
  }
}
