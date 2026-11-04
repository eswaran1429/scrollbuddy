import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:scrollbuddy/core/custom_widgets/app_button/app_button.dart';
import 'package:scrollbuddy/core/custom_widgets/app_card/app_card.dart';
import 'package:scrollbuddy/core/custom_widgets/app_tile/app_tile.dart';
import 'package:scrollbuddy/core/custom_widgets/custom_text/custom_text.dart';
import 'package:scrollbuddy/core/themes/app_colors.dart';

import '../../core/models.dart';
import '../../data/counts_controller.dart';
import '../../data/settings.dart';

const _chevron = Icon(Icons.chevron_right, color: AppColors.textMuted);

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) => Obx(() => _build(context));

  Widget _build(BuildContext context) {
    final s = Get.find<SettingsController>().settings.value;
    final n = Get.find<SettingsController>();
    final trackingOn = Get.find<CountsController>().accessibilityEnabled.value;

    void snack(String msg) =>
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: CustomText(text: msg)));

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          children: [
            const CustomText(text: 'Settings', fontSize: 30, fontWeight: FontWeight.w700, letterSpacing: -0.5),
            const SizedBox(height: 20),
            AppCard(
              color: (trackingOn ? AppColors.sage : AppColors.coral).withValues(alpha: 0.1),
              border: Border.all(color: (trackingOn ? AppColors.sage : AppColors.coral).withValues(alpha: 0.35)),
              radius: 24,
              padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
              child: Row(
                children: [
                  IconBadge(
                    icon: trackingOn ? Icons.check_circle : Icons.error_outline,
                    color: trackingOn ? AppColors.sage : AppColors.coral,
                    size: 40,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CustomText(text: trackingOn ? 'Tracking is on' : 'Tracking is off', fontWeight: FontWeight.w700),
                        CustomText(
                          text: trackingOn ? 'Counting reels in your apps' : 'Turn on Accessibility access',
                          fontSize: 13,
                          color: AppColors.textMuted,
                        ),
                      ],
                    ),
                  ),
                  if (!trackingOn)
                    AppButton(
                      label: 'Fix',
                      compact: true,
                      expand: false,
                      onPressed: () => context.push('/onboarding?step=1'),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            AppTileGroup(
              title: 'Tracked apps',
              children: [
                for (final app in TrackedApp.values)
                  AppTile(
                    leading: IconBadge(icon: app.icon, color: app.color),
                    title: app.label,
                    trailing: Switch(value: s.trackedApps.contains(app), onChanged: (on) => n.setTracked(app, on)),
                  ),
              ],
            ),
            const SizedBox(height: 24),
            AppTileGroup(
              title: 'Limits',
              children: [
                AppTile(
                  leading: const IconBadge(icon: Icons.timer_outlined, color: AppColors.sage),
                  title: 'Limits and blocking',
                  subtitle: s.dailyLimit == null ? 'No limit' : '${s.dailyLimit} reels / day',
                  trailing: _chevron,
                  onTap: () => context.push('/limits'),
                ),
              ],
            ),
            const SizedBox(height: 24),
            AppTileGroup(
              title: 'Display',
              children: [
                AppTile(
                  leading: const IconBadge(icon: Icons.bubble_chart_outlined, color: AppColors.lavender),
                  title: 'Floating counter',
                  subtitle: 'Shows your count on top of reels',
                  trailing: Switch(value: s.showOverlay, onChanged: n.setShowOverlay),
                ),
                AppTile(
                  leading: const IconBadge(icon: Icons.motion_photos_off_outlined, color: AppColors.info),
                  title: 'Reduce motion',
                  trailing: Switch(value: s.reducedMotion, onChanged: n.setReducedMotion),
                ),
              ],
            ),
            const SizedBox(height: 24),
            AppTileGroup(
              title: 'Your data',
              children: [
                AppTile(
                  leading: const IconBadge(icon: Icons.restart_alt, color: AppColors.textMuted),
                  title: "Reset today's count",
                  onTap: () async {
                    if (await _confirm(context, "Reset today's count?", 'Today goes back to 0.')) {
                      Get.find<CountsController>().resetToday();
                    }
                  },
                ),
                AppTile(
                  leading: const IconBadge(icon: Icons.download_outlined, color: AppColors.textMuted),
                  title: 'Export data (CSV)',
                  onTap: () => snack('Export comes in a later version'),
                ),
                AppTile(
                  leading: const IconBadge(icon: Icons.delete_outline, color: AppColors.coral),
                  title: 'Delete all data',
                  titleColor: AppColors.coral,
                  onTap: () async {
                    if (await _confirm(context, 'Delete all data?',
                        'This removes all counts and settings from this device. It cannot be undone.')) {
                      await Get.find<CountsController>().deleteAll();
                      n.reset();
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 24),
            AppTileGroup(
              title: 'About',
              children: [
                AppTile(
                  leading: const IconBadge(icon: Icons.privacy_tip_outlined, color: AppColors.textMuted),
                  title: 'Privacy policy',
                  trailing: _chevron,
                  onTap: () => snack('Privacy policy link goes here'),
                ),
                AppTile(
                  leading: const IconBadge(icon: Icons.description_outlined, color: AppColors.textMuted),
                  title: 'Terms',
                  trailing: _chevron,
                  onTap: () => snack('Terms link goes here'),
                ),
                AppTile(
                  leading: const IconBadge(icon: Icons.replay, color: AppColors.textMuted),
                  title: 'Show onboarding again',
                  trailing: _chevron,
                  onTap: () => context.go('/onboarding'),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const CustomText(
              text: 'ScrollBuddy 1.0.0',
              textAlign: TextAlign.center,
              fontSize: 12,
              color: AppColors.textMuted,
            ),
          ],
        ),
      ),
    );
  }

  Future<bool> _confirm(BuildContext context, String title, String body) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: CustomText(text: title, fontWeight: FontWeight.w700, fontSize: 18),
        content: CustomText(text: body, color: AppColors.textMuted),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const CustomText(text: 'Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const CustomText(text: 'Confirm', fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
    return ok ?? false;
  }
}
