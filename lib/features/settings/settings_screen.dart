import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:scrollbuddy/core/custom_widgets/app_button/app_button.dart';
import 'package:scrollbuddy/core/custom_widgets/app_card/app_card.dart';
import 'package:scrollbuddy/core/custom_widgets/app_tile/app_tile.dart';
import 'package:scrollbuddy/core/custom_widgets/custom_text/custom_text.dart';
import 'package:scrollbuddy/core/custom_widgets/custom_textfield/custom_textfield.dart';
import 'package:scrollbuddy/core/custom_widgets/page_header/page_header.dart';
import 'package:scrollbuddy/core/themes/app_colors.dart';

import '../../core/models.dart';
import '../../data/counts_controller.dart';
import '../../data/settings.dart';

// const _chevron = Icon(Icons.chevron_right, color: AppColors.textMuted);

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) => Obx(() => _build(context));

  Widget _build(BuildContext context) {
    final s = Get.find<SettingsController>().settings.value;
    final n = Get.find<SettingsController>();
    final trackingOn = Get.find<CountsController>().accessibilityEnabled.value;

    // void snack(String msg) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: CustomText(text: msg)));

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          children: [
            const PageHeader(title: 'Settings', subtitle: 'Tracking, limits and your data', showBack: true),
            const SizedBox(height: 18),
            AppCard(
              padding: const EdgeInsets.fromLTRB(14, 14, 12, 14),
              child: Row(
                children: [
                  IconBadge(
                    icon: trackingOn ? Icons.verified_outlined : Icons.error_outline,
                    color: trackingOn ? AppColors.sage : AppColors.coral,
                    size: 44,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SectionLabel('Tracking'),
                        CustomText(
                          text: trackingOn ? 'Tracking is on' : 'Tracking is off',
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                        CustomText(
                          text: trackingOn ? 'Counting reels in your apps' : 'Turn on Accessibility access',
                          fontSize: 11,
                          color: AppColors.textMuted,
                        ),
                      ],
                    ),
                  ),
                  if (trackingOn)
                    const StatusPill(
                      text: 'Active',
                      icon: Icons.check_circle,
                      color: AppColors.sage,
                      background: AppColors.sageSoft,
                    )
                  else
                    AppButton(
                      label: 'On',
                      compact: true,
                      expand: false,
                      onPressed: Get.find<CountsController>().openAccessibilitySettings,
                    ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            _TrackedAppsCard(
              tracked: s.trackedApps,
              onToggle: (app) => n.setTracked(app, !s.trackedApps.contains(app)),
            ),
            const SizedBox(height: 22),
            AppTileGroup(
              title: 'Display',
              children: [
                AppTile(
                  leading: const IconBadge(icon: Icons.bubble_chart_outlined, color: AppColors.lavender),
                  title: 'Floating counter',
                  subtitle: 'Shows your count on top of reels',
                  trailing: Switch(value: s.showOverlay, onChanged: n.setShowOverlay),
                ),
                if (s.showOverlay) _OverlayAfterPicker(value: s.overlayAfter, onChanged: n.setOverlayAfter),
                AppTile(
                  leading: const IconBadge(icon: Icons.motion_photos_off_outlined, color: AppColors.info),
                  title: 'Reduce motion',
                  trailing: Switch(value: s.reducedMotion, onChanged: n.setReducedMotion),
                ),
              ],
            ),
            const SizedBox(height: 22),
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
                // AppTile(
                //   leading: const IconBadge(icon: Icons.download_outlined, color: AppColors.textMuted),
                //   title: 'Export data (CSV)',
                //   onTap: () => snack('Export comes in a later version'),
                // ),
                // AppTile(
                //   leading: const IconBadge(icon: Icons.delete_outline, color: AppColors.coral),
                //   title: 'Delete all data',
                //   titleColor: AppColors.coral,
                //   onTap: () async {
                //     if (await _confirm(
                //       context,
                //       'Delete all data?',
                //       'This removes all counts and settings from this device. It cannot be undone.',
                //     )) {
                //       await Get.find<CountsController>().deleteAll();
                //       n.reset();
                //     }
                //   },
                // ),
              ],
            ),
            const SizedBox(height: 22),
            // AppTileGroup(
            //   title: 'About',
            //   children: [
            //     AppTile(
            //       leading: const IconBadge(icon: Icons.privacy_tip_outlined, color: AppColors.textMuted),
            //       title: 'Privacy policy',
            //       trailing: _chevron,
            //       onTap: () => snack('Privacy policy link goes here'),
            //     ),
            //     AppTile(
            //       leading: const IconBadge(icon: Icons.description_outlined, color: AppColors.textMuted),
            //       title: 'Terms',
            //       trailing: _chevron,
            //       onTap: () => snack('Terms link goes here'),
            //     ),
            //     AppTile(
            //       leading: const IconBadge(icon: Icons.replay, color: AppColors.textMuted),
            //       title: 'Show onboarding again',
            //       trailing: _chevron,
            //       onTap: () => context.go('/onboarding'),
            //     ),
            //   ],
            // ),
            // const SizedBox(height: 20),
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
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const CustomText(text: 'Cancel'),
          ),
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

/// "Show after" choice for the floating counter: from the first reel, a preset, or a custom number.
class _OverlayAfterPicker extends StatelessWidget {
  const _OverlayAfterPicker({required this.value, required this.onChanged});

  final int value;
  final ValueChanged<int> onChanged;

  static const _options = [0, 10, 25, 50];

  Future<void> _custom(BuildContext context) async {
    final n = await showDialog<int>(
      context: context,
      builder: (context) => _CustomCountDialog(initial: _options.contains(value) ? null : value),
    );
    if (n != null) onChanged(n);
  }

  @override
  Widget build(BuildContext context) {
    final custom = !_options.contains(value);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CustomText(
            text: value == 0 ? 'Show from the first reel' : 'Show after $value reels today',
            fontSize: 12,
            color: AppColors.textMuted,
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              for (final o in _options) ...[
                Expanded(
                  flex: o == 0 ? 3 : 2,
                  child: _Chip(label: o == 0 ? 'Always' : '$o', selected: o == value, onTap: () => onChanged(o)),
                ),
                const SizedBox(width: 6),
              ],
              Expanded(
                flex: 3,
                child: _Chip(
                  label: custom ? '$value' : 'Custom',
                  icon: Icons.edit_outlined,
                  selected: custom,
                  onTap: () => _custom(context),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.selected, required this.onTap, this.icon});

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final fg = selected ? Colors.white : AppColors.textMuted;
    return Material(
      color: selected ? AppColors.lavender : AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: selected ? AppColors.lavender : AppColors.stroke),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[Icon(icon, size: 13, color: fg), const SizedBox(width: 4)],
              Flexible(
                child: CustomText(text: label, fontSize: 12, fontWeight: FontWeight.w600, maxLines: 1, color: fg),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Number entry for a custom "show after" count. Owns its controller so it is
/// disposed only after the dialog's exit animation (see the limits dialog crash).
class _CustomCountDialog extends StatefulWidget {
  const _CustomCountDialog({this.initial});

  final int? initial;

  @override
  State<_CustomCountDialog> createState() => _CustomCountDialogState();
}

class _CustomCountDialogState extends State<_CustomCountDialog> {
  late final _controller = TextEditingController(text: widget.initial?.toString() ?? '');

  int? get _value {
    final n = int.tryParse(_controller.text.trim());
    return n == null || n < 1 || n > 999 ? null : n;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const CustomText(text: 'Show counter after', fontWeight: FontWeight.w700, fontSize: 18),
      content: CustomTextField(
        label: 'Reels today (1–999)',
        controller: _controller,
        autofocus: true,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(3)],
        onChanged: (_) => setState(() {}),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const CustomText(text: 'Cancel'),
        ),
        FilledButton(
          onPressed: _value == null ? null : () => Navigator.pop(context, _value),
          child: const CustomText(text: 'Save', fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}

/// Tracked apps: a header with how many are counted, then a 2×2 grid of toggles.
class _TrackedAppsCard extends StatelessWidget {
  const _TrackedAppsCard({required this.tracked, required this.onToggle});

  final Set<TrackedApp> tracked;
  final ValueChanged<TrackedApp> onToggle;

  @override
  Widget build(BuildContext context) {
    const apps = TrackedApp.values;
    final count = apps.where(tracked.contains).length;
    Widget cell(TrackedApp app) => Expanded(
      child: _AppToggle(app: app, on: tracked.contains(app), onTap: () => onToggle(app)),
    );

    return AppCard(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      child: Column(
        children: [
          Row(
            children: [
              const IconBadge(icon: Icons.apps_rounded, color: AppColors.sage, size: 36),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const CustomText(text: 'Tracked apps', fontSize: 14, fontWeight: FontWeight.w700),
                    CustomText(
                      text: count == 0 ? 'Nothing is counted' : '$count of ${apps.length} apps counted',
                      fontSize: 11,
                      color: AppColors.textMuted,
                    ),
                  ],
                ),
              ),
              StatusPill(
                text: '$count/${apps.length}',
                color: count == 0 ? AppColors.coral : AppColors.sage,
                background: count == 0 ? AppColors.peachSoft : AppColors.sageSoft,
              ),
            ],
          ),
          const SizedBox(height: 14),
          for (var i = 0; i < apps.length; i += 2) ...[
            if (i > 0) const SizedBox(height: 8),
            Row(
              children: [
                cell(apps[i]),
                const SizedBox(width: 8),
                if (i + 1 < apps.length) cell(apps[i + 1]) else const Spacer(),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// One app toggle: round badge filled with the app colour when tracked, name, status and a check.
class _AppToggle extends StatelessWidget {
  const _AppToggle({required this.app, required this.on, required this.onTap});

  final TrackedApp app;
  final bool on;
  final VoidCallback onTap;

  static const _anim = Duration(milliseconds: 200);

  @override
  Widget build(BuildContext context) {
    final r = BorderRadius.circular(16);
    return Semantics(
      toggled: on,
      button: true,
      label: app.label,
      excludeSemantics: true,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: r,
          child: AnimatedContainer(
            duration: _anim,
            padding: const EdgeInsets.fromLTRB(8, 8, 10, 8),
            decoration: BoxDecoration(
              color: on ? app.color.withValues(alpha: 0.07) : AppColors.surface,
              borderRadius: r,
              border: Border.all(color: on ? app.color.withValues(alpha: 0.35) : AppColors.stroke, width: 1.2),
            ),
            child: Row(
              children: [
                AnimatedContainer(
                  duration: _anim,
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(color: on ? app.color : AppColors.surfaceHigh, shape: BoxShape.circle),
                  child: Icon(app.icon, size: 17, color: on ? Colors.white : AppColors.textMuted),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CustomText(
                        text: app.label,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        color: on ? AppColors.textPrimary : AppColors.textMuted,
                      ),
                      CustomText(
                        text: on ? 'On' : 'Off',
                        fontSize: 10,
                        color: on ? app.color : AppColors.textMuted.withValues(alpha: 0.7),
                      ),
                    ],
                  ),
                ),
                AnimatedContainer(
                  duration: _anim,
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: on ? app.color : Colors.transparent,
                    border: on ? null : Border.all(color: AppColors.stroke, width: 1.5),
                  ),
                  child: on ? const Icon(Icons.check_rounded, size: 12, color: Colors.white) : null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
