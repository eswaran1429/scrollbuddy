import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:scrollbuddy/core/custom_widgets/app_button/app_button.dart';
import 'package:scrollbuddy/core/custom_widgets/app_card/app_card.dart';
import 'package:scrollbuddy/core/custom_widgets/app_tile/app_tile.dart';
import 'package:scrollbuddy/core/custom_widgets/custom_text/custom_text.dart';
import 'package:scrollbuddy/core/custom_widgets/page_header/page_header.dart';
import 'package:scrollbuddy/core/themes/app_colors.dart';

import '../../core/format.dart';
import '../../data/settings.dart';

class LimitsScreen extends StatelessWidget {
  const LimitsScreen({super.key});

  @override
  Widget build(BuildContext context) => Obx(() => _build(context));

  Widget _build(BuildContext context) {
    final s = Get.find<SettingsController>().settings.value;
    final n = Get.find<SettingsController>();
    final strict = s.strictActive(DateTime.now());
    final locked = strict; // no changes during strict mode
    final limit = s.dailyLimit;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
          children: [
            const PageHeader(title: 'Limits', subtitle: 'Your daily reel limit'),
            const SizedBox(height: 18),
            if (strict) ...[
              AppCard(
                color: AppColors.sage.withValues(alpha: 0.1),
                border: Border.all(color: AppColors.sage.withValues(alpha: 0.4)),
                radius: 24,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.lock_clock, color: AppColors.sage),
                    const SizedBox(width: 12),
                    Expanded(
                      child: CustomText(
                        text:
                            'Strict mode is on until ${hhmm(s.strictUntil!)}. Limits cannot be changed in '
                            'ScrollBuddy until then. Android still lets you turn off the service in system settings.',
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
            AppCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: [
                      const IconBadge(icon: Icons.flag_outlined, color: AppColors.sage, size: 40),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CustomText(text: 'Daily reel limit', fontWeight: FontWeight.w700, fontSize: 14),
                            CustomText(
                              text: 'Reels pause when you reach it. Feed and messages keep working.',
                              fontSize: 11,
                              color: AppColors.textMuted,
                            ),
                          ],
                        ),
                      ),
                      Switch(value: limit != null, onChanged: locked ? null : (on) => n.setDailyLimit(on ? 100 : null)),
                    ],
                  ),
                  if (limit != null) _LimitPicker(limit: limit, enabled: !locked, onChanged: n.setDailyLimit),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Padding(
              padding: EdgeInsets.only(left: 4, bottom: 8),
              child: SectionLabel('When the limit is reached'),
            ),
            for (final mode in UnlockMode.values) ...[
              _ModeOption(
                mode: mode,
                selected: s.unlockMode == mode,
                enabled: !locked,
                onTap: () => n.setUnlockMode(mode),
              ),
              const SizedBox(height: 8),
            ],
            if (s.unlockMode == UnlockMode.strict && !strict) ...[
              const SizedBox(height: 8),
              AppButton(label: 'Start strict mode', icon: Icons.lock_clock, onPressed: () => _startStrict(context)),
            ],
            const SizedBox(height: 16),
            AppButton.secondary(
              label: 'Preview block screen',
              icon: Icons.visibility_outlined,
              onPressed: () => context.push('/block-preview'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _startStrict(BuildContext context) async {
    final now = DateTime.now();
    final midnight = DateTime(now.year, now.month, now.day + 1);
    final until = await showModalBottomSheet<DateTime>(
      context: context,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const CustomText(text: 'Start strict mode?', fontSize: 20, fontWeight: FontWeight.w700),
              const SizedBox(height: 8),
              const CustomText(
                text: 'You will not be able to unlock reels or change limits in ScrollBuddy until the timer ends.',
                color: AppColors.textMuted,
              ),
              const SizedBox(height: 20),
              for (final (label, t) in [
                ('1 hour', now.add(const Duration(hours: 1))),
                ('4 hours', now.add(const Duration(hours: 4))),
                ('Until midnight', midnight),
              ]) ...[
                AppButton.secondary(label: label, onPressed: () => Navigator.pop(context, t)),
                const SizedBox(height: 8),
              ],
            ],
          ),
        ),
      ),
    );
    if (until != null) Get.find<SettingsController>().startStrict(until);
  }
}

class _ModeOption extends StatelessWidget {
  const _ModeOption({required this.mode, required this.selected, required this.enabled, required this.onTap});

  final UnlockMode mode;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1 : 0.45,
      child: AppCard(
        radius: 18,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: Border.all(color: selected ? AppColors.sage : AppColors.stroke, width: selected ? 2 : 1),
        onTap: enabled ? onTap : null,
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: selected ? AppColors.sage : null,
                border: selected ? null : Border.all(color: AppColors.textMuted, width: 2),
              ),
              child: selected ? const Icon(Icons.check, size: 14, color: Colors.white) : null,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomText(text: mode.label, fontSize: 14, fontWeight: FontWeight.w700),
                  CustomText(text: mode.description, fontSize: 11, color: AppColors.textMuted),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Big number with − / + buttons (steps of [_step]) and quick presets.
class _LimitPicker extends StatelessWidget {
  const _LimitPicker({required this.limit, required this.enabled, required this.onChanged});

  final int limit;
  final bool enabled;
  final ValueChanged<int> onChanged;

  static const _step = 10;
  static const _min = 10;
  static const _max = 500;
  static const _presets = [30, 50, 100, 200];

  @override
  Widget build(BuildContext context) {
    void set(int v) => onChanged(v.clamp(_min, _max));
    return Column(
      children: [
        const SizedBox(height: 18),
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: AppColors.surfaceHigh, borderRadius: BorderRadius.circular(18)),
          child: Row(
            children: [
              _StepButton(
                icon: Icons.remove,
                tooltip: '$_step fewer',
                onTap: enabled && limit > _min ? () => set(limit - _step) : null,
              ),
              Expanded(
                child: Column(
                  children: [
                    CustomText(text: '$limit', fontSize: 30, fontWeight: FontWeight.w700, height: 1.1),
                    const CustomText(text: 'reels per day', fontSize: 11, color: AppColors.textMuted),
                  ],
                ),
              ),
              _StepButton(
                icon: Icons.add,
                tooltip: '$_step more',
                onTap: enabled && limit < _max ? () => set(limit + _step) : null,
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            for (final (i, preset) in _presets.indexed) ...[
              if (i > 0) const SizedBox(width: 8),
              Expanded(
                child: _PresetChip(value: preset, selected: preset == limit, onTap: enabled ? () => set(preset) : null),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

class _StepButton extends StatelessWidget {
  const _StepButton({required this.icon, required this.tooltip, required this.onTap});

  final IconData icon;
  final String tooltip;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final on = onTap != null;
    return Tooltip(
      message: tooltip,
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: SizedBox.square(
            dimension: 48,
            child: Icon(icon, color: on ? AppColors.sage : AppColors.textMuted.withValues(alpha: 0.4)),
          ),
        ),
      ),
    );
  }
}

class _PresetChip extends StatelessWidget {
  const _PresetChip({required this.value, required this.selected, required this.onTap});

  final int value;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.sage : AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: selected ? AppColors.sage : AppColors.stroke),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 9),
          child: CustomText(
            text: '$value',
            textAlign: TextAlign.center,
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : AppColors.textMuted,
          ),
        ),
      ),
    );
  }
}
