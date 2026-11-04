import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';

import '../data/counts_controller.dart';
import '../features/blocking/block_screen.dart';
import 'router.dart';
import 'theme.dart';

class ScrollBuddyApp extends StatefulWidget {
  const ScrollBuddyApp({super.key});

  @override
  State<ScrollBuddyApp> createState() => _ScrollBuddyAppState();
}

class _ScrollBuddyAppState extends State<ScrollBuddyApp> with WidgetsBindingObserver {
  final GoRouter _router = createRouter();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    Get.find<CountsController>().bridge.setBlockRequestHandler(_checkBlock);
  }

  /// Opens the block screen when the service reports a reached limit.
  /// The splash handles this itself on a cold start.
  Future<void> _checkBlock() async {
    if (_router.routerDelegate.currentConfiguration.uri.path == '/splash') return;
    if (await Get.find<CountsController>().bridge.takeBlockRequest() && !BlockScreen.isOpen) _router.push('/block');
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _router.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    Get.find<CountsController>().refreshAccessibility();
    _checkBlock();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'ScrollBuddy',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      themeMode: ThemeMode.light,
      routerConfig: _router,
    );
  }
}
