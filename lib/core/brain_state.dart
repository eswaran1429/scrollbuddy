import 'dart:math';

enum BrainState {
  healthy('Healthy', 'Bright and focused'),
  tired('Tired', 'Getting a little dull'),
  cracking('Cracking', 'Showing some cracks'),
  fried('Fried', 'Running on fumes');

  const BrainState(this.label, this.description);

  final String label;
  final String description;
}

/// Continuous damage from 0.0 (fresh) to 3.0 (fried). The whole part is the
/// [BrainState] index; the fraction is progress inside that band.
///
/// Bands (plan.md §9, D-12): counts 0 / 50 / 100 / 200, or with a limit the
/// ratio count/limit at 0 / 50 % / 80 % / 100 %.
double brainDamage(int count, {int? limit}) {
  final List<double> edges;
  final double v;
  if (limit != null && limit > 0) {
    v = count / limit;
    edges = const [0, 0.5, 0.8, 1.0];
  } else {
    v = count.toDouble();
    edges = const [0, 50, 100, 200];
  }
  for (var i = edges.length - 1; i >= 0; i--) {
    if (v >= edges[i]) {
      if (i == edges.length - 1) return 3;
      return i + (v - edges[i]) / (edges[i + 1] - edges[i]);
    }
  }
  return 0;
}

BrainState brainStateFor(int count, {int? limit}) =>
    BrainState.values[min(brainDamage(count, limit: limit).floor(), 3)];
