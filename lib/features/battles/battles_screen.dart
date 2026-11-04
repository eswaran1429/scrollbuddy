import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:scrollbuddy/core/custom_widgets/app_button/app_button.dart';
import 'package:scrollbuddy/core/custom_widgets/app_card/app_card.dart';
import 'package:scrollbuddy/core/custom_widgets/custom_text/custom_text.dart';
import 'package:scrollbuddy/core/custom_widgets/custom_textfield/custom_textfield.dart';
import 'package:scrollbuddy/core/themes/app_colors.dart';

import '../../data/counts_controller.dart';
import 'battles_data.dart';

class _Entry {
  const _Entry(this.name, this.count, {this.active = true, this.isMe = false});

  final String name;
  final int count;
  final bool active;
  final bool isMe;
}

/// Active players by count ascending, then inactive ones (they cannot win, D-14).
List<_Entry> _rank(List<_Entry> entries) => [
      ...entries.where((e) => e.active).toList()..sort((a, b) => a.count.compareTo(b.count)),
      ...entries.where((e) => !e.active),
    ];

const _avatarColors = [AppColors.teal, AppColors.purple, AppColors.orange, AppColors.blue500, AppColors.successGreen];

Color _avatarColor(String name) => _avatarColors[name.codeUnits.fold(0, (a, b) => a + b) % _avatarColors.length];

class BattlesScreen extends StatelessWidget {
  const BattlesScreen({super.key});

  @override
  Widget build(BuildContext context) => Obx(() => _build(context));

  Widget _build(BuildContext context) {
    final friends = Get.find<FriendsController>().friends.toList();
    final myToday = Get.find<CountsController>().today.value.total;
    final myYesterday = Get.find<CountsController>().yesterday?.total ?? 0;
    final accepted = friends.where((f) => !f.pending);
    final pending = friends.where((f) => f.pending).toList();

    final today = _rank([
      _Entry('You', myToday, isMe: true),
      for (final f in accepted) _Entry(f.name, f.today, active: f.trackingActive),
    ]);
    final yesterday = _rank([
      _Entry('You', myYesterday, isMe: true),
      for (final f in accepted) _Entry(f.name, f.yesterday),
    ]);
    final winner = yesterday.first;

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          children: [
            Row(
              children: [
                const Expanded(
                  child: CustomText(text: 'Battles', fontSize: 30, fontWeight: FontWeight.w700, letterSpacing: -0.5),
                ),
                AppIconButton(icon: Icons.person_add_alt, tooltip: 'Add friend', onPressed: () => _addFriend(context)),
              ],
            ),
            const CustomText(text: 'Fewest reels wins the day', color: AppColors.textMuted),
            const SizedBox(height: 20),
            AppCard(
              color: AppColors.lavenderSoft,
              child: Row(
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CustomText(text: 'Your friend code', fontSize: 13, color: AppColors.textMuted),
                        SizedBox(height: 4),
                        CustomText(
                          text: myFriendCode,
                          fontSize: 26,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 3,
                          color: AppColors.lavender,
                        ),
                      ],
                    ),
                  ),
                  AppButton.secondary(
                    label: 'Copy',
                    icon: Icons.copy,
                    compact: true,
                    expand: false,
                    onPressed: () {
                      Clipboard.setData(const ClipboardData(text: myFriendCode));
                      ScaffoldMessenger.of(context)
                          .showSnackBar(const SnackBar(content: CustomText(text: 'Friend code copied')));
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const CustomText(text: 'Today', fontSize: 18, fontWeight: FontWeight.w700),
            const SizedBox(height: 12),
            AppCard(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                children: [
                  for (final (i, e) in today.indexed)
                    _EntryRow(entry: e, rank: i + 1, winner: e.active && e.count == today.first.count),
                ],
              ),
            ),
            const SizedBox(height: 16),
            AppCard(
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.sage),
                    child: const Icon(Icons.emoji_events, color: Colors.white),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const CustomText(text: 'Yesterday', fontSize: 12, color: AppColors.textMuted),
                        CustomText(
                          text: '${winner.isMe ? 'You' : winner.name} won with ${winner.count} reels',
                          fontWeight: FontWeight.w700,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (pending.isNotEmpty) ...[
              const SizedBox(height: 24),
              const CustomText(text: 'Pending', fontSize: 18, fontWeight: FontWeight.w700),
              const SizedBox(height: 12),
              AppCard(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Column(
                  children: [
                    for (final f in pending)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          children: [
                            _Avatar(name: f.name),
                            const SizedBox(width: 12),
                            Expanded(child: CustomText(text: f.name, fontWeight: FontWeight.w600)),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceHigh,
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: const CustomText(text: 'Pending', fontSize: 12, color: AppColors.textMuted),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 20),
            const CustomText(
              text: 'Only your daily total is shared with friends. Never what you watched.',
              textAlign: TextAlign.center,
              fontSize: 12,
              color: AppColors.textMuted,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _addFriend(BuildContext context) async {
    final controller = TextEditingController();
    final code = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const CustomText(text: 'Add a friend', fontWeight: FontWeight.w700, fontSize: 18),
        content: CustomTextField(
          label: 'Friend code',
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.characters,
          maxLength: 8,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const CustomText(text: 'Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim().toUpperCase()),
            child: const CustomText(text: 'Send request', fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
    controller.dispose();
    if (code == null || code.length != 8) return;
    Get.find<FriendsController>().addByCode(code);
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    final color = _avatarColor(name);
    return CircleAvatar(
      radius: 20,
      backgroundColor: color.withValues(alpha: 0.2),
      child: CustomText(text: name[0], fontWeight: FontWeight.w700, color: color),
    );
  }
}

class _EntryRow extends StatelessWidget {
  const _EntryRow({required this.entry, required this.rank, required this.winner});

  final _Entry entry;
  final int rank;
  final bool winner;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: entry.isMe
          ? BoxDecoration(
              color: AppColors.sage.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.sage.withValues(alpha: 0.35)),
            )
          : null,
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: winner ? AppColors.amber400 : AppColors.surfaceHigh,
            ),
            alignment: Alignment.center,
            child: winner
                ? const Icon(Icons.emoji_events, size: 16, color: Colors.white)
                : CustomText(
                    text: entry.active ? '$rank' : '–',
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textMuted,
                  ),
          ),
          const SizedBox(width: 12),
          _Avatar(name: entry.name),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomText(text: entry.name, fontWeight: entry.isMe ? FontWeight.w700 : FontWeight.w600),
                if (!entry.active) const CustomText(text: 'Tracking off', fontSize: 12, color: AppColors.coral),
              ],
            ),
          ),
          CustomText(
            text: entry.active ? '${entry.count}' : '–',
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: winner ? AppColors.sage : AppColors.textPrimary,
          ),
        ],
      ),
    );
  }
}
