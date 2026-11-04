import 'package:flutter_test/flutter_test.dart';
import 'package:scrollbuddy/core/brain_state.dart';

void main() {
  group('brainStateFor without limit', () {
    test('band edges', () {
      expect(brainStateFor(0), BrainState.healthy);
      expect(brainStateFor(49), BrainState.healthy);
      expect(brainStateFor(50), BrainState.tired);
      expect(brainStateFor(99), BrainState.tired);
      expect(brainStateFor(100), BrainState.cracking);
      expect(brainStateFor(199), BrainState.cracking);
      expect(brainStateFor(200), BrainState.fried);
      expect(brainStateFor(5000), BrainState.fried);
    });
  });

  group('brainStateFor with limit 100', () {
    test('ratio edges (D-12)', () {
      expect(brainStateFor(49, limit: 100), BrainState.healthy);
      expect(brainStateFor(50, limit: 100), BrainState.tired);
      expect(brainStateFor(79, limit: 100), BrainState.tired);
      expect(brainStateFor(80, limit: 100), BrainState.cracking);
      expect(brainStateFor(99, limit: 100), BrainState.cracking);
      expect(brainStateFor(100, limit: 100), BrainState.fried);
    });

    test('limit 0 falls back to counts', () {
      expect(brainStateFor(10, limit: 0), BrainState.healthy);
    });
  });

  test('brainDamage is continuous and capped at 3', () {
    expect(brainDamage(0), 0);
    expect(brainDamage(25), closeTo(0.5, 1e-9));
    expect(brainDamage(150), closeTo(2.5, 1e-9));
    expect(brainDamage(999), 3);
  });
}
