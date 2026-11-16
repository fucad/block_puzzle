import 'package:block_puzzle/dev/screenshot_mode.dart';
import 'package:block_puzzle/systems/game_engine.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('screenshot classic fixture is a busy, live, full-tray board', () {
    final s = greedyClassicRun(125, 80);
    final filled = s.board.cells.where((c) => c != null).length;
    expect(GameEngine.isGameOver(s), isFalse);
    expect(s.tray.every((p) => p != null), isTrue);
    expect(filled, inInclusiveRange(24, 40));
    // ignore: avoid_print
    print('fixture score=${s.score} filled=$filled tray=${s.tray}');
  });
}
