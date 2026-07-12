import 'package:block_puzzle/models/board.dart';
import 'package:block_puzzle/systems/game_constants.dart';
import 'package:block_puzzle/systems/piece_generator.dart';
import 'package:block_puzzle/systems/placement.dart';
import 'package:block_puzzle/systems/solvability.dart';
import 'package:block_puzzle/systems/rng.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

void main() {
  test('same seed and board produce the same trays', () {
    final a = PieceGenerator(GameRng(123));
    final b = PieceGenerator(GameRng(123));
    final board = Board.empty();
    for (var i = 0; i < 20; i++) {
      expect(
        a.nextTray(board).map((p) => p.id).toList(),
        b.nextTray(board).map((p) => p.id).toList(),
      );
    }
  });

  test('tray always has traySize pieces', () {
    final gen = PieceGenerator(GameRng(5));
    expect(gen.nextTray(Board.empty()), hasLength(traySize));
  });

  test('fit-weighting biases toward pieces that fit a cramped board', () {
    // Only scattered single holes: just 'single' fits.
    final cramped = boardFrom([
      '.1111111',
      '11111111',
      '111.1111',
      '11111111',
      '11111111',
      '1111.111',
      '11111111',
      '1111111.',
    ]);
    final gen = PieceGenerator(GameRng(77));
    var fitting = 0;
    var total = 0;
    for (var i = 0; i < 300; i++) {
      for (final piece in gen.nextTray(cramped)) {
        total++;
        if (fitsAnywhere(cramped, piece)) fitting++;
      }
    }
    // 'single' has base weight 0.25 of ~29 pieces; unweighted it would be
    // drawn <2% of the time. With fitPenalty 0.15 it should be well above.
    expect(fitting / total, greaterThan(0.05));
  });

  test('trays are playable in some order on realistic mid-game boards', () {
    // A board with structure: partial rows/columns like real play.
    final board = boardFrom([
      '11111.1.',
      '1.1.....',
      '1.......',
      '1...22..',
      '1...22..',
      '........',
      '33.3.3..',
      '333.333.',
    ]);
    final gen = PieceGenerator(GameRng(11));
    for (var i = 0; i < 40; i++) {
      final tray = gen.nextTray(board);
      expect(
        canPlaceAllInSomeOrder(board, tray),
        isTrue,
        reason: 'tray ${tray.map((p) => p.id)} not sequence-playable',
      );
    }
  });

  test('breaker pieces are boosted when a line is close to done', () {
    // Row 0 needs only (0,5): every piece covering it is a breaker.
    final board = boardFrom([
      '11111.11',
      '........',
      '........',
      '........',
      '........',
      '........',
      '........',
      '........',
    ]);
    final gen = PieceGenerator(GameRng(5));
    var breakerTrays = 0;
    const trials = 100;
    for (var i = 0; i < trials; i++) {
      final tray = gen.nextTray(board);
      if (tray.any((p) => canClearLineWith(board, p))) breakerTrays++;
    }
    // The generator explicitly prefers sets containing a breaker.
    expect(breakerTrays / trials, greaterThan(0.9));
  });

  test('fresh trays are always placeable while any piece fits', () {
    // Only 'single' (rare, weight 0.25) fits this board, so unguarded
    // draws would routinely produce dead trays.
    final cramped = boardFrom([
      '.1111111',
      '11111111',
      '11111111',
      '11111111',
      '11111111',
      '11111111',
      '11111111',
      '1111111.',
    ]);
    final gen = PieceGenerator(GameRng(2026));
    for (var i = 0; i < 200; i++) {
      final tray = gen.nextTray(cramped);
      expect(tray.any((p) => fitsAnywhere(cramped, p)), isTrue);
    }
  });
}
