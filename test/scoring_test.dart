import 'package:block_puzzle/systems/scoring.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('lineScore rewards simultaneous multi-line clears superlinearly', () {
    expect(lineScore(1), 10);
    expect(lineScore(2), 30);
    expect(lineScore(3), 60);
    expect(lineScore(4), 100);
    // Two singles (20) < one double (30).
    expect(lineScore(1) * 2, lessThan(lineScore(2)));
  });

  test('comboBonus starts paying at the second consecutive clear', () {
    expect(comboBonus(0), 0);
    expect(comboBonus(1), 0);
    expect(comboBonus(2), 10);
    expect(comboBonus(3), 20);
    expect(comboBonus(14), 130);
  });
}
