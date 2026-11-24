import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:scrollbuddy/core/custom_widgets/app_card/app_card.dart';
import 'package:scrollbuddy/core/custom_widgets/app_tile/app_tile.dart';
import 'package:scrollbuddy/core/custom_widgets/custom_text/custom_text.dart';
import 'package:scrollbuddy/core/custom_widgets/page_header/page_header.dart';
import 'package:scrollbuddy/core/custom_widgets/pill_tabs/pill_tabs.dart';
import 'package:scrollbuddy/core/themes/app_colors.dart';

import '../../core/format.dart';
import '../../core/history_stats.dart';
import '../../core/models.dart';
import '../../data/counts_controller.dart';
import '../../data/settings.dart';
import 'day_charts.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final _counts = Get.find<CountsController>();
  final _settings = Get.find<SettingsController>();
  int _range = 7;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Obx(() {
          final settings = _settings.settings.value;
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
            children: [
              PageHeader(title: 'History', subtitle: 'Your last $_range days'),
              const SizedBox(height: 18),
              PillTabs(
                labels: const ['7 days', '30 days'],
                selected: _range == 7 ? 0 : 1,
                onChanged: (i) => setState(() => _range = i == 0 ? 7 : 30),
              ),
              const SizedBox(height: 16),
              if (_counts.historyLoading.value)
                const Padding(
                  padding: EdgeInsets.all(48),
                  child: Center(child: CircularProgressIndicator()),
                )
              else
                _HistoryBody(
                  past: _counts.lastDays(_range - 1),
                  today: _counts.today.value,
                  limit: settings.dailyLimit,
                ),
            ],
          );
        }),
      ),
    );
  }
}

class _HistoryBody extends StatelessWidget {
  const _HistoryBody({required this.past, required this.today, required this.limit});

  final List<DayCounts> past;
  final DayCounts today;
  final int? limit;

  @override
  Widget build(BuildContext context) {
    final days = [...past, today];
    final stats = computeStats(past, today, limit: limit);
    final best = stats.bestDay;
    final total = days.fold(0, (a, d) => a + d.total);
    final totalSeconds = days.fold(0, (a, d) => a + d.totalSeconds);
    final perApp = [
      for (final app in TrackedApp.values)
        (app, days.fold(0, (a, d) => a + d.of(app)), days.fold(0, (a, d) => a + d.secondsOf(app))),
    ]..sort((a, b) => b.$2.compareTo(a.$2));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _StatTile(
                  label: 'Average',
                  value: '${stats.average}',
                  caption: 'per day',
                  icon: Icons.show_chart_rounded,
                  color: AppColors.sage,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _StatTile(
                  label: 'Streak',
                  value: limit == null ? '–' : '${stats.streak} days',
                  caption: limit == null ? 'set a limit to start' : 'under $limit',
                  icon: Icons.local_fire_department_outlined,
                  color: AppColors.coral,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        AppCard(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const SectionLabel('Reels per day'),
                  const Spacer(),
                  if (limit != null && days.length <= 7) ...[
                    Container(width: 12, height: 2, color: AppColors.coral),
                    const SizedBox(width: 6),
                    CustomText(text: 'limit $limit', fontSize: 11, color: AppColors.textMuted),
                  ],
                ],
              ),
              if (best != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.emoji_events, size: 16, color: AppColors.amber),
                    const SizedBox(width: 6),
                    CustomText(text: 'Best day · ${shortDate(best.date)} · ', fontSize: 12, color: AppColors.textMuted),
                    CustomText(text: '${best.total} reels', fontSize: 12, fontWeight: FontWeight.w700),
                  ],
                ),
              ],
              const SizedBox(height: 16),
              if (days.length <= 7)
                DayBars(key: const ValueKey('bars'), days: days, limit: limit, best: best?.date)
              else
                DayHeatmap(key: const ValueKey('heatmap'), days: days, limit: limit),
            ],
          ),
        ),
        const SizedBox(height: 10),
        AppCard(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SectionLabel('Breakdown'),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _Total(value: '$total', label: 'reels'),
                  ),
                  Expanded(
                    child: _Total(value: watchTime(totalSeconds), label: 'in reels'),
                  ),
                  Expanded(
                    child: _Total(value: watchTime(totalSeconds ~/ days.length), label: 'per day'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              for (final (app, n, secs) in perApp) _AppShare(app: app, reels: n, seconds: secs, total: total),
            ],
          ),
        ),
      ],
    );
  }
}

class _Total extends StatelessWidget {
  const _Total({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CustomText(text: value, fontSize: 18, fontWeight: FontWeight.w800, maxLines: 1),
        CustomText(text: label, fontSize: 11, color: AppColors.textMuted),
      ],
    );
  }
}

/// One app: icon, name, share bar, reels and time.
class _AppShare extends StatelessWidget {
  const _AppShare({required this.app, required this.reels, required this.seconds, required this.total});

  final TrackedApp app;
  final int reels;
  final int seconds;
  final int total;

  @override
  Widget build(BuildContext context) {
    final share = total == 0 ? 0.0 : reels / total;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          IconBadge(icon: app.icon, color: app.color, size: 34),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CustomText(text: app.label, fontSize: 13, fontWeight: FontWeight.w600),
                    const Spacer(),
                    CustomText(text: '$reels', fontSize: 13, fontWeight: FontWeight.w700),
                  ],
                ),
                const SizedBox(height: 5),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: share,
                    minHeight: 6,
                    color: app.color,
                    backgroundColor: AppColors.surfaceHigh,
                  ),
                ),
                const SizedBox(height: 3),
                CustomText(
                  text: '${(share * 100).round()}% · ${watchTime(seconds)}',
                  fontSize: 11,
                  color: AppColors.textMuted,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.label,
    required this.value,
    required this.caption,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final String caption;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionLabel(label),
          const SizedBox(height: 10),
          Row(
            children: [
              IconBadge(icon: icon, color: color, size: 38),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CustomText(text: value, fontSize: 16, fontWeight: FontWeight.w700, height: 1.2),
                    CustomText(text: caption, fontSize: 11, color: AppColors.textMuted, maxLines: 1),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
