import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:scrollbuddy/core/themes/app_colors.dart';

import '../data/counts_controller.dart';
import '../data/settings.dart';
import '../features/blocking/block_screen.dart';
import 'router.dart';
import 'theme.dart';

class ScrollBuddyApp extends StatefulWidget {
  const ScrollBuddyApp({super.key});

  @override
  State<ScrollBuddyApp> createState() => _ScrollBuddyAppState();
}

class _ScrollBuddyAppState extends State<ScrollBuddyApp> with WidgetsBindingObserver, SingleTickerProviderStateMixin {
  final GoRouter _router = createRouter();
  final _boundaryKey = GlobalKey();
  late final Worker _settingsWorker;
  late final AnimationController _fade = AnimationController(vsync: this, duration: const Duration(milliseconds: 450))
    ..addStatusListener((s) {
      if (s == AnimationStatus.completed) _clearSnapshot();
    });

  ui.Image? _snapshot;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    Get.find<CountsController>().bridge.setBlockRequestHandler(_checkBlock);
    AppColors.isDark = _wantDark();
    _settingsWorker = ever(Get.find<SettingsController>().settings, (_) => _applyTheme());
  }

  Future<void> _checkBlock() async {
    if (_router.routerDelegate.currentConfiguration.uri.path == '/splash') return;
    if (await Get.find<CountsController>().bridge.takeBlockRequest() && !BlockScreen.isOpen) _router.push('/block');
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _settingsWorker.dispose();
    _fade.dispose();
    _snapshot?.dispose();
    _router.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    Get.find<CountsController>()
      ..refreshAccessibility()
      ..refreshToday();
    _checkBlock();
  }

  @override
  void didChangePlatformBrightness() => _applyTheme();

  bool _wantDark() {
    final mode = Get.find<SettingsController>().settings.value.themeMode;
    final platformDark = WidgetsBinding.instance.platformDispatcher.platformBrightness == Brightness.dark;
    return mode == ThemeMode.dark || (mode == ThemeMode.system && platformDark);
  }

  void _applyTheme() {
    final dark = _wantDark();
    if (!mounted || dark == AppColors.isDark) return;

    final boundary = _boundaryKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    if (boundary != null && boundary.hasSize) {
      try {
        final image = boundary.toImageSync(pixelRatio: View.of(context).devicePixelRatio);
        _snapshot?.dispose();
        _snapshot = image;
      } catch (_) {}
    }

    AppColors.isDark = dark;
    _rebuildAll();
    setState(() {});
    if (_snapshot != null) _fade.forward(from: 0);
  }

  void _clearSnapshot() {
    if (_snapshot == null) return;
    setState(() {
      _snapshot!.dispose();
      _snapshot = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final dark = AppColors.isDark;
    final theme = AppTheme.build();
    return MaterialApp.router(
      title: 'ScrollBuddy',
      debugShowCheckedModeBanner: false,
      theme: theme,
      darkTheme: theme,
      themeMode: dark ? ThemeMode.dark : ThemeMode.light,
      themeAnimationDuration: Duration.zero,
      routerConfig: _router,
      builder: (context, child) => AnnotatedRegion<SystemUiOverlayStyle>(
        value: dark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
        child: Stack(
          alignment: Alignment.topLeft,
          children: [
            RepaintBoundary(key: _boundaryKey, child: child!),
            if (_snapshot != null)
              Positioned.fill(
                child: IgnorePointer(
                  child: FadeTransition(
                    opacity: ReverseAnimation(CurvedAnimation(parent: _fade, curve: Curves.easeInOut)),
                    child: RawImage(image: _snapshot, fit: BoxFit.fill),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _rebuildAll() {
    void mark(Element e) {
      e.markNeedsBuild();
      e.visitChildren(mark);
    }

    (context as Element).visitChildren(mark);
  }
}
