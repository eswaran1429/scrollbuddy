import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:scrollbuddy/core/custom_widgets/custom_text/custom_text.dart';
import 'package:scrollbuddy/core/themes/app_colors.dart';

import '../../core/rewards.dart';
import '../../data/settings.dart';

/// Bottom sheet: pick an outfit for the cat. Locked ones show as silhouettes.
Future<void> showDressingRoom(BuildContext context, {required int goodDays, required bool hasLimit}) {
  Get.find<SettingsController>().markDressingRoomSeen();
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: AppColors.bg,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
    builder: (_) => _DressingRoom(goodDays: goodDays, hasLimit: hasLimit),
  );
}

Color _accent(Reward r) => switch (r) {
  Reward.sunglasses => AppColors.amber,
  Reward.bowtie => AppColors.coral,
  Reward.scarf => const Color(0xFFD9485F),
  Reward.headphones => AppColors.lavender,
  Reward.crown => const Color(0xFFE8B400),
  Reward.partyhat => AppColors.lilac,
};

class _DressingRoom extends StatelessWidget {
  const _DressingRoom({required this.goodDays, required this.hasLimit});

  final int goodDays;
  final bool hasLimit;

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<SettingsController>();
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.88),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Obx(() {
            final s = ctrl.settings.value;
            final worn = Reward.byName(s.outfit);
            final unlocked = Reward.values.where((r) => s.unlockedRewards.contains(r.name)).length;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _Stage(worn: worn),
                const SizedBox(height: 14),
                _Progress(goodDays: goodDays, hasLimit: hasLimit, unlocked: s.unlockedRewards),
                const SizedBox(height: 20),
                Row(
                  children: [
                    const CustomText(text: 'Collection', fontSize: 16, fontWeight: FontWeight.w700),
                    const Spacer(),
                    CustomText(
                      text: '$unlocked / ${Reward.values.length}',
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.lavender,
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                GridView.count(
                  crossAxisCount: 3,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 0.78,
                  children: [
                    _Tile(
                      asset: 'assets/images/healthy.png',
                      label: 'Classic',
                      accent: AppColors.sage,
                      unlocked: true,
                      worn: worn == null,
                      onTap: () => ctrl.wearOutfit(null),
                    ),
                    for (final r in Reward.values)
                      _Tile(
                        asset: r.asset,
                        label: r.label,
                        accent: _accent(r),
                        unlocked: s.unlockedRewards.contains(r.name),
                        lockText: '${r.daysNeeded} day${r.daysNeeded == 1 ? '' : 's'}',
                        worn: worn == r,
                        onTap: () => ctrl.wearOutfit(r.name),
                      ),
                  ],
                ),
              ],
            );
          }),
        ),
      ),
    );
  }
}

/// Big preview of what the cat is wearing now.
class _Stage extends StatelessWidget {
  const _Stage({required this.worn});

  final Reward? worn;

  @override
  Widget build(BuildContext context) {
    final accent = worn == null ? AppColors.sage : _accent(worn!);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      height: 210,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.alphaBlend(accent.withValues(alpha: AppColors.isDark ? 0.22 : 0.18), AppColors.surface),
            AppColors.surface,
          ],
        ),
        border: Border.all(color: accent.withValues(alpha: 0.35)),
      ),
      child: Stack(
        children: [
          Positioned(
            left: 16,
            top: 14,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomText(text: 'Dressing room', fontSize: 12, color: AppColors.textMuted),
                CustomText(text: worn?.label ?? 'Classic', fontSize: 20, fontWeight: FontWeight.w800),
              ],
            ),
          ),
          Positioned(
            right: 8,
            bottom: 0,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 350),
              switchInCurve: Curves.easeOutBack,
              transitionBuilder: (child, a) => ScaleTransition(
                scale: Tween(begin: 0.8, end: 1.0).animate(a),
                child: FadeTransition(opacity: a, child: child),
              ),
              child: Image.asset(
                worn?.asset ?? 'assets/images/happy.png',
                key: ValueKey(worn),
                height: 180,
                cacheHeight: 540,
                fit: BoxFit.contain,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Good days so far and how far the next outfit is.
class _Progress extends StatelessWidget {
  const _Progress({required this.goodDays, required this.hasLimit, required this.unlocked});

  final int goodDays;
  final bool hasLimit;
  final Set<String> unlocked;

  @override
  Widget build(BuildContext context) {
    final next = Reward.values.where((r) => !unlocked.contains(r.name)).firstOrNull;
    final String title;
    final String sub;
    double value;
    if (!hasLimit) {
      title = 'Set a daily limit';
      sub = 'Every day under it earns your buddy something to wear.';
      value = 0;
    } else if (next == null) {
      title = 'Full wardrobe!';
      sub = 'Every outfit unlocked. Fashion icon.';
      value = 1;
    } else {
      final left = (next.daysNeeded - goodDays).clamp(1, next.daysNeeded);
      title = '$goodDays good day${goodDays == 1 ? '' : 's'}';
      sub = '${next.label} unlocks in $left more day${left == 1 ? '' : 's'} under your limit';
      value = (goodDays / next.daysNeeded).clamp(0.0, 1.0);
    }
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.stroke),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(color: AppColors.amber.withValues(alpha: 0.15), shape: BoxShape.circle),
            child: const Icon(Icons.local_fire_department, color: AppColors.amber),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomText(text: title, fontSize: 15, fontWeight: FontWeight.w800),
                CustomText(text: sub, fontSize: 12, color: AppColors.textMuted),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: value,
                    minHeight: 8,
                    color: AppColors.amber,
                    backgroundColor: AppColors.surfaceHigh,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({
    required this.asset,
    required this.label,
    required this.accent,
    required this.unlocked,
    required this.worn,
    required this.onTap,
    this.lockText,
  });

  final String asset;
  final String label;
  final Color accent;
  final bool unlocked;
  final bool worn;
  final VoidCallback onTap;
  final String? lockText;

  @override
  Widget build(BuildContext context) {
    Widget img = Image.asset(asset, cacheWidth: 240, fit: BoxFit.contain);
    if (!unlocked) {
      img = Opacity(
        opacity: 0.18,
        child: ColorFiltered(colorFilter: ColorFilter.mode(AppColors.textPrimary, BlendMode.srcIn), child: img),
      );
    }
    final r = BorderRadius.circular(18);
    return AnimatedScale(
      scale: worn ? 1.03 : 1,
      duration: const Duration(milliseconds: 150),
      child: Material(
        color: Colors.transparent,
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: r,
            gradient: unlocked
                ? LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      accent.withValues(alpha: AppColors.isDark ? 0.22 : 0.14),
                      AppColors.surface,
                    ],
                  )
                : null,
            color: unlocked ? null : AppColors.surfaceHigh,
            border: Border.all(
              color: worn ? accent : (unlocked ? accent.withValues(alpha: 0.3) : AppColors.stroke),
              width: worn ? 2.2 : 1,
            ),
          ),
          child: InkWell(
            borderRadius: r,
            onTap: unlocked ? onTap : null,
            child: Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 10, 8, 8),
                  child: Column(
                    children: [
                      Expanded(child: img),
                      const SizedBox(height: 6),
                      CustomText(
                        text: label,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        maxLines: 1,
                        color: unlocked ? AppColors.textPrimary : AppColors.textMuted,
                      ),
                    ],
                  ),
                ),
                if (worn)
                  Positioned(
                    top: 6,
                    right: 6,
                    child: Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(color: accent, shape: BoxShape.circle),
                      child: const Icon(Icons.check_rounded, size: 15, color: Colors.white),
                    ),
                  ),
                if (!unlocked)
                  Positioned.fill(
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: AppColors.stroke),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.lock_rounded, size: 12, color: AppColors.textMuted),
                            const SizedBox(width: 3),
                            CustomText(
                              text: lockText ?? '',
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textMuted,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Small clothing-tag button on the ring's lower-right that opens the dressing room.
/// Tinted with the worn outfit's colour; a dot marks it until the dressing room is opened once.
class OutfitBadge extends StatelessWidget {
  const OutfitBadge({super.key, required this.worn, required this.isNew, required this.onTap});

  final Reward? worn;
  final bool isNew;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accent = worn == null ? AppColors.lavender : _accent(worn!);
    return Semantics(
      button: true,
      label: 'Dressing room. Wearing ${worn?.label ?? 'Classic'}',
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        // 44 px touch area around a 30 px tag.
        child: SizedBox.square(
          dimension: 44,
          child: Center(
            child: Transform.rotate(
              angle: -0.18,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(9),
                      border: Border.all(color: accent.withValues(alpha: 0.55), width: 1.5),
                      boxShadow: [
                        BoxShadow(color: accent.withValues(alpha: 0.18), blurRadius: 6, offset: const Offset(0, 2)),
                      ],
                    ),
                    child: Icon(Icons.checkroom_rounded, size: 16, color: accent),
                  ),
                  if (isNew)
                    Positioned(
                      right: -3,
                      top: -3,
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: AppColors.amber,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.surface, width: 2),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
