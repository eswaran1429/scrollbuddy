import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:scrollbuddy/core/custom_widgets/app_button/app_button.dart';
import 'package:scrollbuddy/core/custom_widgets/app_card/app_card.dart';
import 'package:scrollbuddy/core/custom_widgets/app_tile/app_tile.dart';
import 'package:scrollbuddy/core/custom_widgets/custom_text/custom_text.dart';
import 'package:scrollbuddy/core/custom_widgets/custom_textfield/custom_textfield.dart';
import 'package:scrollbuddy/core/themes/app_colors.dart';

import '../../core/format.dart';
import '../../core/models.dart';
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
      appBar: AppBar(title: const CustomText(text: 'Limits')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
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
                      text: 'Strict mode is on until ${hhmm(s.strictUntil!)}. Limits cannot be changed in '
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
            child: Column(
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CustomText(text: 'Daily reel limit', fontWeight: FontWeight.w700, fontSize: 16),
                          CustomText(text: 'Shapes your brain and streak', fontSize: 13, color: AppColors.textMuted),
                        ],
                      ),
                    ),
                    Switch(value: limit != null, onChanged: locked ? null : (on) => n.setDailyLimit(on ? 100 : null)),
                  ],
                ),
                if (limit != null) ...[
                  const SizedBox(height: 16),
                  CustomText(text: '$limit', fontSize: 52, fontWeight: FontWeight.w700, height: 1),
                  const CustomText(text: 'reels per day', color: AppColors.textMuted),
                  Slider(
                    value: limit.toDouble(),
                    min: 10,
                    max: 500,
                    divisions: 49,
                    label: '$limit',
                    onChanged: locked ? null : (v) => n.setDailyLimit(v.round()),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),
          AppTileGroup(
            title: 'Blocking',
            children: [
              AppTile(
                leading: const IconBadge(icon: Icons.block, color: AppColors.coral),
                title: 'Block reels at limit',
                subtitle: 'Only reels and shorts. Feed and messages keep working.',
                trailing: Switch(
                  value: s.blockingEnabled,
                  onChanged: limit == null || locked ? null : n.setBlocking,
                ),
              ),
              for (final app in TrackedApp.values)
                if (s.trackedApps.contains(app))
                  AppTile(
                    enabled: !locked,
                    leading: IconBadge(icon: app.icon, color: app.color),
                    title: '${app.label} limit',
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CustomText(
                          text: s.perAppLimits[app]?.toString() ?? 'Off',
                          color: AppColors.textMuted,
                          fontWeight: FontWeight.w600,
                        ),
                        const Icon(Icons.chevron_right, color: AppColors.textMuted),
                      ],
                    ),
                    onTap: () => _editPerApp(context, app, s.perAppLimits[app]),
                  ),
            ],
          ),
          const SizedBox(height: 24),
          const Padding(
            padding: EdgeInsets.only(left: 6, bottom: 10),
            child: CustomText(
              text: 'When the limit is reached',
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textMuted,
            ),
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
    );
  }

  Future<void> _editPerApp(BuildContext context, TrackedApp app, int? current) async {
    final controller = TextEditingController(text: current?.toString() ?? '');
    final result = await showDialog<int?>(
      context: context,
      builder: (context) => AlertDialog(
        title: CustomText(text: '${app.label} daily limit', fontWeight: FontWeight.w700, fontSize: 18),
        content: CustomTextField(
          label: 'Reels per day',
          controller: controller,
          autofocus: true,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, -1), child: const CustomText(text: 'Turn off')),
          FilledButton(
            onPressed: () => Navigator.pop(context, int.tryParse(controller.text.trim())),
            child: const CustomText(text: 'Save', fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
    controller.dispose();
    if (result == null) return;
    Get.find<SettingsController>().setPerAppLimit(app, result <= 0 ? null : result);
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
        radius: 20,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
                  CustomText(text: mode.label, fontWeight: FontWeight.w700),
                  CustomText(text: mode.description, fontSize: 13, color: AppColors.textMuted),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
