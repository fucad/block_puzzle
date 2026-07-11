import 'package:block_puzzle/systems/rng.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('same seed produces identical sequences', () {
    final a = GameRng(12345);
    final b = GameRng(12345);
    for (var i = 0; i < 100; i++) {
      expect(a.nextDouble(), b.nextDouble());
    }
    expect(a.state, b.state);
  });

  test('different seeds produce different sequences', () {
    final a = GameRng(1);
    final b = GameRng(2);
    final aSeq = [for (var i = 0; i < 10; i++) a.nextDouble()];
    final bSeq = [for (var i = 0; i < 10; i++) b.nextDouble()];
    expect(aSeq, isNot(bSeq));
  });

  test('golden sequence for seed 42 is stable across releases', () {
    // If this test breaks, saved runs and pinned quest seeds break with it.
    // Never "fix" it by regenerating the goldens after an RNG change.
    final rng = GameRng(42);
    expect(rng.nextDouble(), closeTo(0.1941059175341826, 1e-15));
    expect(rng.nextDouble(), closeTo(0.5626318272656207, 1e-15));
    expect(rng.nextDouble(), closeTo(0.4861061377100522, 1e-15));
    expect(rng.nextDouble(), closeTo(0.2711055606027185, 1e-15));
    expect(rng.state, 2730941277836234587);

    final ints = GameRng(42);
    expect(
      [for (var i = 0; i < 8; i++) ints.nextInt(100)],
      [19, 56, 48, 27, 80, 58, 30, 79],
    );
  });

  test('state round-trips: a resumed rng continues the sequence', () {
    final original = GameRng(7);
    original.nextDouble();
    original.nextDouble();
    final resumed = GameRng.fromState(original.state);
    for (var i = 0; i < 20; i++) {
      expect(resumed.nextDouble(), original.nextDouble());
    }
  });

  test('nextInt stays in range and hits all values', () {
    final rng = GameRng(99);
    final seen = <int>{};
    for (var i = 0; i < 1000; i++) {
      final v = rng.nextInt(8);
      expect(v, inInclusiveRange(0, 7));
      seen.add(v);
    }
    expect(seen, hasLength(8));
  });
}
