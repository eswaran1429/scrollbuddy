import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';

import '../data/counts_controller.dart';
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
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _router.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) Get.find<CountsController>().refreshAccessibility();
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
