import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:scrollbuddy/core/custom_widgets/app_button/app_button.dart';
import 'package:scrollbuddy/core/custom_widgets/app_card/app_card.dart';
import 'package:scrollbuddy/core/custom_widgets/blob/soft_blob.dart';
import 'package:scrollbuddy/core/custom_widgets/custom_text/custom_text.dart';
import 'package:scrollbuddy/core/custom_widgets/custom_textfield/custom_textfield.dart';
import 'package:scrollbuddy/core/themes/app_colors.dart';

import '../../core/format.dart';
import '../../data/counts_controller.dart';
import '../../data/settings.dart';
import '../dashboard/brain_view.dart';

/// Flutter preview of the block screen. The real one is a native
/// TYPE_ACCESSIBILITY_OVERLAY window (D-07) with the same content.
class BlockScreen extends StatefulWidget {
  const BlockScreen({super.key});

  static const unlockPhrase = 'I choose how I spend my time';
  static const waitSeconds = 30;
  static const bonusReels = 10;

  @override
  State<BlockScreen> createState() => _BlockScreenState();
}

class _BlockScreenState extends State<BlockScreen> {
  Timer? _timer;
  int _secondsLeft = BlockScreen.waitSeconds;
  final _phrase = TextEditingController();

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_secondsLeft == 0) return t.cancel();
      setState(() => _secondsLeft--);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _phrase.dispose();
    super.dispose();
  }

  void _unlock() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: CustomText(text: 'Unlocked ${BlockScreen.bonusReels} bonus reels (preview)')),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) => Obx(() => _build(context));

  Widget _build(BuildContext context) {
    final s = Get.find<SettingsController>().settings.value;
    final count = Get.find<CountsController>().today.value.total;
    final strict = s.strictActive(DateTime.now());
    final mode = strict ? UnlockMode.strict : s.unlockMode;

    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, c) => SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: (c.maxHeight - 48).clamp(0, double.infinity)),
              child: DefaultTextStyle.merge(
                textAlign: TextAlign.center,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Align(
                      alignment: Alignment.centerRight,
                      child: AppButton.text(
                        label: 'Close preview',
                        expand: false,
                        compact: true,
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                    Column(
                      children: [
                        SoftBlob(
                          size: 210,
                          color: AppColors.lavenderSoft,
                          child: BrainView(
                            count: count,
                            limit: s.dailyLimit,
                            reducedMotion: s.reducedMotion,
                            size: 160,
                            showLabel: false,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const CustomText(
                          text: 'Limit reached',
                          fontSize: 30,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.5,
                        ),
                        const SizedBox(height: 4),
                        CustomText(text: '$count reels today', fontSize: 16, color: AppColors.sage),
                        const SizedBox(height: 12),
                        const CustomText(
                          text: 'Take a breath. Your feed and messages still work. Only reels are paused.',
                          color: AppColors.textMuted,
                        ),
                        const SizedBox(height: 28),
                        AppCard(child: Column(children: _unlockSection(mode, s))),
                      ],
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _unlockSection(UnlockMode mode, AppSettings s) {
    switch (mode) {
      case UnlockMode.none:
        return const [
          Icon(Icons.nightlight_round, color: AppColors.sage),
          SizedBox(height: 8),
          CustomText(text: 'Reels unlock again at midnight.', fontWeight: FontWeight.w600),
        ];
      case UnlockMode.strict:
        final until = s.strictUntil;
        return [
          const Icon(Icons.lock_clock, color: AppColors.sage),
          const SizedBox(height: 8),
          const CustomText(text: 'Strict mode', fontWeight: FontWeight.w700),
          CustomText(
            text: until == null ? 'No unlock until the timer ends.' : 'No unlock until ${hhmm(until)}.',
            color: AppColors.textMuted,
          ),
        ];
      case UnlockMode.wait:
        return [
          SizedBox.square(
            dimension: 72,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox.expand(
                  child: CircularProgressIndicator(
                    value: 1 - _secondsLeft / BlockScreen.waitSeconds,
                    strokeWidth: 6,
                    backgroundColor: AppColors.surfaceHigh,
                  ),
                ),
                CustomText(text: '${_secondsLeft}s', fontWeight: FontWeight.w700, fontSize: 18),
              ],
            ),
          ),
          const SizedBox(height: 12),
          CustomText(
            text: _secondsLeft > 0 ? 'Wait a moment before you decide.' : 'You can unlock now.',
            color: AppColors.textMuted,
          ),
          const SizedBox(height: 16),
          AppButton(
            label: 'Unlock ${BlockScreen.bonusReels} more reels',
            onPressed: _secondsLeft == 0 ? _unlock : null,
          ),
        ];
      case UnlockMode.task:
        final ok = _phrase.text.trim().toLowerCase() == BlockScreen.unlockPhrase.toLowerCase();
        return [
          const CustomText(text: 'Type this to unlock', color: AppColors.textMuted),
          const SizedBox(height: 6),
          const CustomText(text: '"${BlockScreen.unlockPhrase}"', fontWeight: FontWeight.w700, fontSize: 16),
          const SizedBox(height: 16),
          CustomTextField(
            label: 'Type the phrase',
            controller: _phrase,
            onChanged: (_) => setState(() {}),
            fillColor: AppColors.surfaceHigh,
          ),
          const SizedBox(height: 16),
          AppButton(label: 'Unlock ${BlockScreen.bonusReels} more reels', onPressed: ok ? _unlock : null),
        ];
    }
  }
}
