import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:scrollbuddy/core/custom_widgets/app_button/app_button.dart';
import 'package:scrollbuddy/core/custom_widgets/app_card/app_card.dart';
import 'package:scrollbuddy/core/custom_widgets/blob/soft_blob.dart';
import 'package:scrollbuddy/core/custom_widgets/custom_text/custom_text.dart';
import 'package:scrollbuddy/core/custom_widgets/custom_textfield/custom_textfield.dart';
import 'package:scrollbuddy/core/themes/app_colors.dart';

import '../../core/brain_state.dart';
import '../../core/format.dart';
import '../../data/counts_controller.dart';
import '../../data/settings.dart';
import '../dashboard/mascot_view.dart';

class BlockScreen extends StatefulWidget {
  const BlockScreen({super.key, this.preview = false});

  final bool preview;

  static const unlockPhrase = 'I choose how I spend my time';
  static const waitSeconds = 30;
  static const bonusReels = 10;

  @override
  State<BlockScreen> createState() => _BlockScreenState();

  static bool isOpen = false;

  static DateTime? _waitStartedAt;
}

class _BlockScreenState extends State<BlockScreen> {
  Timer? _timer;
  late final DateTime _waitStart;
  late int _secondsLeft;
  final _phrase = TextEditingController();

  final _line = _lines[Random().nextInt(_lines.length)];

  int _remaining() =>
      (BlockScreen.waitSeconds - DateTime.now().difference(_waitStart).inSeconds).clamp(0, BlockScreen.waitSeconds);

  @override
  void initState() {
    super.initState();
    if (widget.preview) {
      _waitStart = DateTime.now();
    } else {
      BlockScreen.isOpen = true;
      _waitStart = BlockScreen._waitStartedAt ??= DateTime.now();
    }
    _secondsLeft = _remaining();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      setState(() => _secondsLeft = _remaining());
      if (_secondsLeft == 0) t.cancel();
    });
  }

  @override
  void dispose() {
    if (!widget.preview) BlockScreen.isOpen = false;
    _timer?.cancel();
    _phrase.dispose();
    super.dispose();
  }

  Future<void> _unlock(int reels) async {
    if (!widget.preview) {
      await Get.find<CountsController>().bridge.grantBonus(reels);
      BlockScreen._waitStartedAt = null;
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: CustomText(
          text: widget.preview ? 'Unlocked $reels more reels (preview)' : "Fine. $reels more. We didn't see anything.",
        ),
      ),
    );
    _close();
  }

  void _close() => context.canPop() ? context.pop() : context.go('/');

  @override
  Widget build(BuildContext context) => Obx(() => _build(context));

  Widget _build(BuildContext context) {
    final s = Get.find<SettingsController>().settings.value;
    final today = Get.find<CountsController>().today.value;
    final count = today.total;
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
                        label: widget.preview ? 'Close preview' : 'Close',
                        expand: false,
                        compact: true,
                        onPressed: _close,
                      ),
                    ),
                    Column(
                      children: [
                        SoftBlob(
                          size: 210,
                          color: AppColors.lavenderSoft,
                          child: MascotView(
                            state: brainStateFor(count, limit: s.dailyLimit),
                            reducedMotion: s.reducedMotion,
                            size: 160,
                          ),
                        ),
                        const SizedBox(height: 8),
                        CustomText(
                          text: _line.$1,
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.5,
                          height: 1.15,
                        ),
                        const SizedBox(height: 6),
                        CustomText(
                          text: '$count reels · ${watchTime(today.totalSeconds)}',
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.sage,
                        ),
                        const SizedBox(height: 12),
                        CustomText(text: _line.$2, color: AppColors.textMuted, height: 1.45),
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
    const reels = BlockScreen.bonusReels;
    switch (mode) {
      case UnlockMode.none:
        return const [
          Icon(Icons.nightlight_round, color: AppColors.sage),
          SizedBox(height: 8),
          CustomText(text: 'Reels are back at midnight.', fontWeight: FontWeight.w600),
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
            text: _secondsLeft > 0 ? 'Let your thumb cool down first.' : 'Still want more? Your call.',
            color: AppColors.textMuted,
          ),
          const SizedBox(height: 16),
          AppButton(label: 'Unlock $reels more reels', onPressed: _secondsLeft == 0 ? () => _unlock(reels) : null),
        ];
      case UnlockMode.task:
        final ok = _phrase.text.trim().toLowerCase() == BlockScreen.unlockPhrase.toLowerCase();
        return [
          CustomText(text: 'Type this to unlock', color: AppColors.textMuted),
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
          AppButton(label: 'Unlock $reels more reels', onPressed: ok ? () => _unlock(reels) : null),
        ];
    }
  }
}

const _lines = [
  ('Okay, thumb athlete.', 'Rest day. Future you set this limit and future you was right.'),
  ('The algorithm will miss you.', "That's kind of the point. Go do something it can't recommend."),
  ('You finished the internet.', "Nothing left but cats and recipes you won't make. Real life is open."),
  ("Reel talk: that's enough.", 'Stopping now is the plot twist nobody saw coming.'),
  ('Your buddy needs a nap.', 'Ten minutes off-screen and it will forgive you. Probably.'),
];
