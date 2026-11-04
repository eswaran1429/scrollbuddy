import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:scrollbuddy/core/custom_widgets/app_bottom_nav/app_bottom_nav.dart';

import '../features/battles/battles_screen.dart';
import '../features/blocking/block_screen.dart';
import '../features/dashboard/dashboard_screen.dart';
import '../features/history/history_screen.dart';
import '../features/limits/limits_screen.dart';
import '../features/onboarding/onboarding_screen.dart';
import '../features/settings/settings_screen.dart';
import '../features/splash/splash_screen.dart';

/// Fades a page in; used for the screens the splash hands over to.
CustomTransitionPage<void> _fade(GoRouterState state, Widget child) => CustomTransitionPage<void>(
      key: state.pageKey,
      child: child,
      transitionDuration: const Duration(milliseconds: 350),
      transitionsBuilder: (context, animation, _, child) => FadeTransition(opacity: animation, child: child),
    );

/// The splash decides whether to continue to onboarding or Today.
GoRouter createRouter() {
  return GoRouter(
    initialLocation: '/splash',
    routes: [
      GoRoute(path: '/splash', builder: (context, state) => const SplashScreen()),
      GoRoute(
        path: '/onboarding',
        pageBuilder: (context, state) => _fade(
          state,
          OnboardingScreen(startPage: int.tryParse(state.uri.queryParameters['step'] ?? '') ?? 0),
        ),
      ),
      GoRoute(path: '/limits', builder: (context, state) => const LimitsScreen()),
      GoRoute(path: '/block-preview', builder: (context, state) => const BlockScreen()),
      StatefulShellRoute.indexedStack(
        pageBuilder: (context, state, shell) => _fade(state, _HomeShell(shell: shell)),
        branches: [
          StatefulShellBranch(
            routes: [GoRoute(path: '/', builder: (context, state) => const DashboardScreen())],
          ),
          StatefulShellBranch(
            routes: [GoRoute(path: '/history', builder: (context, state) => const HistoryScreen())],
          ),
          StatefulShellBranch(
            routes: [GoRoute(path: '/battles', builder: (context, state) => const BattlesScreen())],
          ),
          StatefulShellBranch(
            routes: [GoRoute(path: '/settings', builder: (context, state) => const SettingsScreen())],
          ),
        ],
      ),
    ],
  );
}

class _HomeShell extends StatelessWidget {
  const _HomeShell({required this.shell});

  final StatefulNavigationShell shell;

  static const _tabs = [
    (AppNavItem(icon: Icons.today_outlined, activeIcon: Icons.today, label: 'Today'), 0),
    (AppNavItem(icon: Icons.bar_chart_outlined, activeIcon: Icons.bar_chart, label: 'History'), 1),
    (AppNavItem(icon: Icons.settings_outlined, activeIcon: Icons.settings, label: 'Settings'), 3),
  ];

  @override
  Widget build(BuildContext context) {
    final current = _tabs.indexWhere((t) => t.$2 == shell.currentIndex);
    return Scaffold(
      extendBody: true,
      body: shell,
      bottomNavigationBar: AppBottomNav(
        items: [for (final t in _tabs) t.$1],
        currentIndex: current < 0 ? 0 : current,
        onTap: (i) {
          final branch = _tabs[i].$2;
          shell.goBranch(branch, initialLocation: branch == shell.currentIndex);
        },
      ),
    );
  }
}
