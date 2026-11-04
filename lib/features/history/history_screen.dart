import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:scrollbuddy/core/custom_widgets/app_card/app_card.dart';
import 'package:scrollbuddy/core/custom_widgets/app_tile/app_tile.dart';
import 'package:scrollbuddy/core/custom_widgets/custom_text/custom_text.dart';
import 'package:scrollbuddy/core/custom_widgets/pill_tabs/pill_tabs.dart';
import 'package:scrollbuddy/core/themes/app_colors.dart';

import '../../core/format.dart';
import '../../core/history_stats.dart';
import '../../core/models.dart';
import '../../data/counts_controller.dart';
import '../../data/settings.dart';

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
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 120),
            children: [
              const CustomText(text: 'History', fontSize: 26, fontWeight: FontWeight.w700, letterSpacing: -0.5),
              CustomText(text: 'Your last $_range days', color: AppColors.textMuted),
              const SizedBox(height: 20),
              PillTabs(
                labels: const ['7 days', '30 days'],
                selected: _range == 7 ? 0 : 1,
                onChanged: (i) => setState(() => _range = i == 0 ? 7 : 30),
              ),
              const SizedBox(height: 20),
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
    final perApp = [
      for (final app in TrackedApp.values) (app, days.fold(0, (a, d) => a + d.of(app))),
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
                  value: '${stats.average}',
                  label: 'Average',
                  caption: 'per day',
                  color: AppColors.sageSoft,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _StatTile(
                  value: best == null ? '–' : '${best.total}',
                  label: 'Best day',
                  caption: best == null ? null : shortDate(best.date),
                  color: AppColors.lavenderSoft,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _StatTile(
                  value: limit == null ? '–' : '${stats.streak}d',
                  label: 'Streak',
                  caption: limit == null ? 'set a limit' : 'under limit',
                  color: AppColors.peachSoft,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        AppCard(
          padding: const EdgeInsets.fromLTRB(12, 18, 18, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 8),
                child: Row(
                  children: [
                    const CustomText(text: 'Reels per day', fontWeight: FontWeight.w600),
                    const Spacer(),
                    if (limit != null) ...[
                      Container(width: 14, height: 2, color: AppColors.coral),
                      const SizedBox(width: 6),
                      CustomText(text: 'limit $limit', fontSize: 12, color: AppColors.textMuted),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(height: 190, child: _Chart(days: days, limit: limit)),
            ],
          ),
        ),
        const SizedBox(height: 28),
        const CustomText(text: 'By app', fontSize: 18, fontWeight: FontWeight.w600),
        const SizedBox(height: 12),
        AppTileGroup(
          children: [
            for (final (app, n) in perApp)
              AppTile(
                leading: IconBadge(icon: app.icon, color: app.color, size: 40),
                title: app.label,
                subtitle: total == 0 ? '0% of reels' : '${(n * 100 / total).round()}% of reels',
                trailing: CustomText(text: '$n', fontWeight: FontWeight.w700, fontSize: 17),
              ),
          ],
        ),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.value, required this.label, required this.color, this.caption});

  final String value;
  final String label;
  final String? caption;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      color: color,
      radius: 22,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CustomText(text: label, fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textMuted),
          const SizedBox(height: 4),
          CustomText(text: value, fontSize: 24, fontWeight: FontWeight.w700),
          if (caption != null)
            CustomText(text: caption!, fontSize: 11, color: AppColors.textMuted, maxLines: 1),
        ],
      ),
    );
  }
}

class _Chart extends StatelessWidget {
  const _Chart({required this.days, required this.limit});

  final List<DayCounts> days;
  final int? limit;

  @override
  Widget build(BuildContext context) {
    final short = days.length <= 7;
    const muted = TextStyle(fontSize: 11, color: AppColors.textMuted, fontFamily: CustomText.fontFamily);
    return LineChart(
      LineChartData(
        minY: 0,
        gridData: FlGridData(
          drawVerticalLine: false,
          getDrawingHorizontalLine: (_) => const FlLine(color: AppColors.stroke, strokeWidth: 1),
        ),
        borderData: FlBorderData(show: false),
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (_) => AppColors.textPrimary,
            getTooltipItems: (spots) => [
              for (final s in spots)
                LineTooltipItem(
                  '${s.y.toInt()} reels\n${shortDate(days[s.x.toInt()].date)}',
                  const TextStyle(color: Colors.white, fontFamily: CustomText.fontFamily, fontSize: 12),
                ),
            ],
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: [for (final (i, d) in days.indexed) FlSpot(i.toDouble(), d.total.toDouble())],
            isCurved: true,
            preventCurveOverShooting: true,
            color: AppColors.sage,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: short,
              getDotPainter: (spot, _, _, i) => FlDotCirclePainter(
                radius: i == days.length - 1 ? 5 : 3.5,
                color: Colors.white,
                strokeWidth: 2.5,
                strokeColor: limit != null && spot.y > limit! ? AppColors.coral : AppColors.sage,
              ),
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [AppColors.sage.withValues(alpha: 0.25), AppColors.sage.withValues(alpha: 0)],
              ),
            ),
          ),
        ],
        extraLinesData: ExtraLinesData(horizontalLines: [
          if (limit != null)
            HorizontalLine(y: limit!.toDouble(), color: AppColors.coral, strokeWidth: 1.5, dashArray: const [5, 4]),
        ]),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(),
          // Empty right gutter so the "Today" label is not clipped.
          rightTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 16,
              getTitlesWidget: (_, _) => const SizedBox.shrink(),
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 34,
              getTitlesWidget: (value, meta) => value == meta.max && value % meta.appliedInterval != 0
                  ? const SizedBox.shrink()
                  : Text(meta.formattedValue, style: muted),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 1,
              getTitlesWidget: (value, meta) {
                final i = value.toInt();
                if (i < 0 || i >= days.length || value != i) return const SizedBox.shrink();
                final d = days[i].date;
                if (!short && i % 5 != 4 && i != days.length - 1) return const SizedBox.shrink();
                final isToday = i == days.length - 1;
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    isToday ? 'Today' : (short ? weekdayLetter(d) : '${d.day}'),
                    style: isToday ? muted.copyWith(color: AppColors.sage, fontWeight: FontWeight.w600) : muted,
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
