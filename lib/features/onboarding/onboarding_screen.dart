import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:scrollbuddy/core/custom_widgets/app_button/app_button.dart';
import 'package:scrollbuddy/core/custom_widgets/app_card/app_card.dart';
import 'package:scrollbuddy/core/custom_widgets/app_tile/app_tile.dart';
import 'package:scrollbuddy/core/custom_widgets/brand/wordmark.dart';
import 'package:scrollbuddy/core/custom_widgets/blob/soft_blob.dart';
import 'package:scrollbuddy/core/custom_widgets/custom_text/custom_text.dart';
import 'package:scrollbuddy/core/themes/app_colors.dart';

import '../../core/models.dart';
import '../../data/counts_controller.dart';
import '../../data/settings.dart';
import '../dashboard/brain_view.dart';

/// Disclosure copy from plan.md §11. Keep in sync with docs/PLAY_COMPLIANCE.md.
const disclosureText =
    'ScrollBuddy uses Android\'s Accessibility Service to detect when you scroll between reels or '
    'shorts in the apps you select (Instagram, YouTube, Facebook, Snapchat). This is used only to '
    'count reels and, if you turn it on, to block them after your limit. To tell one reel from the '
    'next, ScrollBuddy briefly looks at what is on screen in the reels viewer, but it never stores '
    'or sends any of it. It does not read your messages or passwords and does not record your '
    'screen. Counts are stored on your device. If you join Scroll Battles, only your daily total '
    'is shared with friends.';

const _bullets = [
  (true, 'Counts reels and shorts in the apps you pick'),
  (false, 'Does not store or send what you watch'),
  (false, 'Does not read messages or passwords'),
  (false, 'Does not record your screen'),
];

/// Steps: 0 intro, 1 disclosure, 2 apps, 3 accessibility, 4 notifications.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key, this.startPage = 0});

  final int startPage;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  static const _pageCount = 5;
  late final _controller = PageController(initialPage: widget.startPage);
  late int _page = widget.startPage;
  bool _declined = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _next() => _controller.nextPage(duration: const Duration(milliseconds: 350), curve: Curves.easeOutCubic);

  void _back() => _controller.previousPage(duration: const Duration(milliseconds: 350), curve: Curves.easeOutCubic);

  void _finish() {
    Get.find<SettingsController>().markOnboardingDone();
    context.go('/');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
              child: Row(
                children: [
                  AppIconButton(
                    icon: Icons.arrow_back,
                    tooltip: 'Back',
                    onPressed: _page > 0 && !_declined ? _back : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Row(
                      children: [
                        for (var i = 0; i < _pageCount; i++)
                          Expanded(
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              height: 6,
                              margin: const EdgeInsets.symmetric(horizontal: 3),
                              decoration: BoxDecoration(
                                color: i <= _page ? AppColors.sage : AppColors.stroke,
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 56),
                ],
              ),
            ),
            Expanded(
              child: PageView(
                controller: _controller,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (p) => setState(() => _page = p),
                children: [
                  _IntroPage(onNext: _next),
                  _declined
                      ? _DeclinedPage(onBack: () => setState(() => _declined = false), onSkip: _finish)
                      : _DisclosurePage(onAgree: _next, onDecline: () => setState(() => _declined = true)),
                  _AppsPage(onNext: _next),
                  _AccessibilityPage(onNext: _next),
                  _NotificationsPage(onFinish: _finish),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Page layout: content centered vertically (scrolls if tall), actions pinned at bottom.
class _Page extends StatelessWidget {
  const _Page({required this.title, required this.content, required this.actions, this.top, this.accent});

  final String title;

  /// Second title line in amber.
  final String? accent;
  final Widget? top;
  final List<Widget> content;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: LayoutBuilder(
              builder: (context, c) => SingleChildScrollView(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: (c.maxHeight - 32).clamp(0, double.infinity)),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (top != null) ...[Center(child: top), const SizedBox(height: 28)],
                      CustomText(
                        text: title,
                        fontSize: 30,
                        fontWeight: FontWeight.w700,
                        height: 1.15,
                        letterSpacing: -0.5,
                        textAlign: TextAlign.center,
                      ),
                      if (accent != null)
                        CustomText(
                          text: accent!,
                          fontSize: 30,
                          fontWeight: FontWeight.w700,
                          height: 1.15,
                          letterSpacing: -0.5,
                          textAlign: TextAlign.center,
                          color: AppColors.sage,
                        ),
                      const SizedBox(height: 16),
                      ...content,
                    ],
                  ),
                ),
              ),
            ),
          ),
          for (final (i, a) in actions.indexed) ...[if (i > 0) const SizedBox(height: 8), a],
        ],
      ),
    );
  }
}

class _IconTile extends StatelessWidget {
  const _IconTile(this.icon, {this.color = AppColors.sage});

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 84,
      height: 84,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.stroke),
        boxShadow: [BoxShadow(color: color.withValues(alpha: 0.18), blurRadius: 40)],
      ),
      child: Icon(icon, size: 40, color: color),
    );
  }
}

class _Muted extends StatelessWidget {
  const _Muted(this.text);

  final String text;

  @override
  Widget build(BuildContext context) =>
      CustomText(text: text, color: AppColors.textMuted, textAlign: TextAlign.center, height: 1.5);
}

class _IntroPage extends StatelessWidget {
  const _IntroPage({required this.onNext});

  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    const apps = TrackedApp.values;
    const spots = [Alignment(-0.95, -0.7), Alignment(0.95, -0.55), Alignment(-0.85, 0.75), Alignment(0.9, 0.8)];
    return _Page(
      top: Column(
        children: [
          const Wordmark(size: 28),
          const SizedBox(height: 24),
          SizedBox.square(
            dimension: 260,
            child: Stack(
              alignment: Alignment.center,
              children: [
                const SoftBlob(size: 210, color: AppColors.sageSoft),
                const BrainView(count: 0, reducedMotion: true, size: 170, showLabel: false),
                for (final (i, app) in apps.indexed)
                  Align(
                    alignment: spots[i],
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.stroke),
                      ),
                      child: Icon(app.icon, color: app.color, size: 22),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
      title: 'Every reel,',
      accent: 'counted.',
      content: const [
        _Muted('ScrollBuddy counts the reels and shorts you watch, live, all day. Watch your brain buddy '
            'change as the number climbs, and set a limit that works for you.'),
      ],
      actions: [AppButton(label: 'Get started', onPressed: onNext)],
    );
  }
}

class _Bullets extends StatelessWidget {
  const _Bullets();

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          for (final (ok, text) in _bullets)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  IconBadge(
                    icon: ok ? Icons.check : Icons.close,
                    color: ok ? AppColors.sage : AppColors.coral,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: CustomText(text: text, fontWeight: FontWeight.w500)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _DisclosurePage extends StatelessWidget {
  const _DisclosurePage({required this.onAgree, required this.onDecline});

  final VoidCallback onAgree;
  final VoidCallback onDecline;

  @override
  Widget build(BuildContext context) {
    return _Page(
      top: const _IconTile(Icons.accessibility_new),
      title: 'How ScrollBuddy uses Accessibility',
      content: const [
        AppCard(
          child: CustomText(text: disclosureText, fontSize: 13, height: 1.6, color: AppColors.textMuted),
        ),
        SizedBox(height: 12),
        _Bullets(),
      ],
      actions: [
        AppButton(label: 'Agree', onPressed: onAgree),
        AppButton.text(label: 'No thanks', onPressed: onDecline),
      ],
    );
  }
}

class _DeclinedPage extends StatelessWidget {
  const _DeclinedPage({required this.onBack, required this.onSkip});

  final VoidCallback onBack;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    return _Page(
      top: const _IconTile(Icons.info_outline, color: AppColors.info),
      title: 'No problem',
      content: const [
        _Muted('ScrollBuddy cannot count reels without Accessibility access. You can turn it on later from Settings.'),
      ],
      actions: [
        AppButton(label: 'Review again', onPressed: onBack),
        AppButton.text(label: 'Continue without tracking', onPressed: onSkip),
      ],
    );
  }
}

class _AppsPage extends StatelessWidget {
  const _AppsPage({required this.onNext});

  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<SettingsController>();
    return Obx(() {
      final tracked = ctrl.settings.value.trackedApps;
      return _Page(
        title: 'Which apps should we track?',
        content: [
          const _Muted('Pick at least one. You can change this any time.'),
          const SizedBox(height: 24),
          // TODO(phase-5): show only installed apps.
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.25,
            children: [
              for (final app in TrackedApp.values)
                _AppChoice(
                  app: app,
                  selected: tracked.contains(app),
                  onTap: () => ctrl.setTracked(app, !tracked.contains(app)),
                ),
            ],
          ),
        ],
        actions: [AppButton(label: 'Continue', onPressed: tracked.isEmpty ? null : onNext)],
      );
    });
  }
}

class _AppChoice extends StatelessWidget {
  const _AppChoice({required this.app, required this.selected, required this.onTap});

  final TrackedApp app;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      checked: selected,
      label: app.label,
      child: AppCard(
        radius: 24,
        padding: const EdgeInsets.all(16),
        border: Border.all(color: selected ? AppColors.sage : AppColors.stroke, width: selected ? 2 : 1),
        color: selected ? AppColors.sage.withValues(alpha: 0.08) : null,
        onTap: onTap,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                IconBadge(icon: app.icon, color: app.color, size: 48),
                const SizedBox(height: 10),
                CustomText(text: app.label, fontWeight: FontWeight.w600),
              ],
            ),
            Positioned(
              top: 0,
              right: 0,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 150),
                opacity: selected ? 1 : 0,
                child: Container(
                  width: 22,
                  height: 22,
                  decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.sage),
                  child: const Icon(Icons.check, size: 14, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AccessibilityPage extends StatelessWidget {
  const _AccessibilityPage({required this.onNext});

  final VoidCallback onNext;

  void _showWhy(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => const SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              CustomText(text: 'Why this permission?', fontSize: 20, fontWeight: FontWeight.w700),
              SizedBox(height: 8),
              CustomText(
                text: 'Android only lets apps notice reel swipes in other apps through Accessibility. '
                    'ScrollBuddy uses it for counting and, if you choose, blocking.',
                color: AppColors.textMuted,
                height: 1.5,
              ),
              SizedBox(height: 16),
              _Bullets(),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final counts = Get.find<CountsController>();
    return Obx(() {
      final enabled = counts.accessibilityEnabled.value;
      return _Page(
        top: _IconTile(
          enabled ? Icons.check_circle : Icons.toggle_on_outlined,
          color: enabled ? AppColors.sage : AppColors.sage,
        ),
        title: enabled ? 'Tracking is on' : 'Turn on tracking',
        content: [
          _Muted(enabled
              ? 'All set. ScrollBuddy will now count reels in the apps you picked.'
              : 'One permission and you are ready to go.'),
          const SizedBox(height: 24),
          AppCard(
            padding: const EdgeInsets.fromLTRB(18, 16, 14, 16),
            child: Row(
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CustomText(text: 'Accessibility access', fontWeight: FontWeight.w700, fontSize: 16),
                      CustomText(text: 'To count your reels', fontSize: 13, color: AppColors.textMuted),
                    ],
                  ),
                ),
                if (enabled)
                  const IconBadge(icon: Icons.check, color: AppColors.sage)
                else
                  AppButton(
                    label: 'Open settings',
                    compact: true,
                    expand: false,
                    onPressed: counts.openAccessibilitySettings,
                  ),
              ],
            ),
          ),
          if (!enabled) ...[
            const SizedBox(height: 12),
            AppCard(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
              child: const Column(
                children: [
                  _Step(1, 'Tap "Open settings"'),
                  _Step(2, 'Open "Installed apps" or "Downloaded apps"'),
                  _Step(3, 'Pick ScrollBuddy and turn it on'),
                  _Step(4, 'Come back here. We check automatically'),
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),
          AppCard(
            radius: 999,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            onTap: () => _showWhy(context),
            child: const Row(
              children: [
                Icon(Icons.verified_user_outlined, color: AppColors.sage),
                SizedBox(width: 12),
                Expanded(child: CustomText(text: 'Why does ScrollBuddy need this?', fontWeight: FontWeight.w600)),
                Icon(Icons.chevron_right, color: AppColors.textMuted),
              ],
            ),
          ),
        ],
        actions: [
          if (enabled)
            AppButton(label: 'Continue', onPressed: onNext)
          else
            AppButton.text(label: 'Do this later', onPressed: onNext),
        ],
      );
    });
  }
}

class _NotificationsPage extends StatelessWidget {
  const _NotificationsPage({required this.onFinish});

  final VoidCallback onFinish;

  @override
  Widget build(BuildContext context) {
    return _Page(
      top: const _IconTile(Icons.notifications_active_outlined),
      title: 'Your count,',
      accent: 'always in view',
      content: [
        const _Muted('ScrollBuddy keeps a quiet notification with your live count. Android needs your permission.'),
        const SizedBox(height: 24),
        AppCard(
          radius: 22,
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(color: AppColors.sage, borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.psychology, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CustomText(text: 'ScrollBuddy · now', fontSize: 12, color: AppColors.textMuted),
                    CustomText(text: '42 reels today', fontWeight: FontWeight.w700),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
      actions: [
        AppButton(
          // TODO(phase-5): request POST_NOTIFICATIONS via permission_handler.
          label: 'Allow notifications',
          onPressed: onFinish,
        ),
        AppButton.text(label: 'Not now', onPressed: onFinish),
      ],
    );
  }
}

class _Step extends StatelessWidget {
  const _Step(this.n, this.text);

  final int n;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 26,
            height: 26,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.sage.withValues(alpha: 0.16),
            ),
            child: CustomText(text: '$n', fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.sage),
          ),
          const SizedBox(width: 12),
          Expanded(child: CustomText(text: text)),
        ],
      ),
    );
  }
}
