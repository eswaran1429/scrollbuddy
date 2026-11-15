import 'models.dart';

class HistoryStats {
  const HistoryStats({required this.average, required this.bestDay, required this.streak});

  final int average;

  final DayCounts? bestDay;

  final int streak;
}

HistoryStats computeStats(List<DayCounts> pastDays, DayCounts today, {int? limit}) {
  DayCounts? best;
  for (final d in pastDays) {
    if (best == null || d.total < best.total) best = d;
  }
  final average = pastDays.isEmpty ? 0 : (pastDays.fold(0, (a, d) => a + d.total) / pastDays.length).round();

  var streak = 0;
  if (limit != null) {
    for (final d in [...pastDays, today].reversed) {
      if (d.total > limit) break;
      streak++;
    }
  }
  return HistoryStats(average: average, bestDay: best, streak: streak);
}
