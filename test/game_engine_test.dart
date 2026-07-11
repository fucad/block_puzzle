import 'package:block_puzzle/models/cell.dart';
import 'package:block_puzzle/models/game_state.dart';
import 'package:block_puzzle/models/piece_catalog.dart';
import 'package:block_puzzle/systems/game_constants.dart';
import 'package:block_puzzle/systems/game_engine.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

/// Plays [steps] moves greedily (first playable tray slot, first legal
/// position) and returns the final state. Deterministic given the seed.
GameState playGreedy(GameState state, int steps) {
  for (var i = 0; i < steps; i++) {
    var moved = false;
    for (var slot = 0; slot < state.tray.length && !moved; slot++) {
      if (state.tray[slot] == null) continue;
      for (var row = 0; row < 8 && !moved; row++) {
        for (var col = 0; col < 8 && !moved; col++) {
          final outcome = GameEngine.place(state, slot, row, col);
          if (outcome != null) {
            state = outcome.state;
            moved = true;
          }
        }
      }
    }
    if (!moved) break; // game over
  }
  return state;
}

void main() {
  test('newGame starts with an empty board, zero score, full tray', () {
    final state = GameEngine.newGame(42);
    expect(state.board.isEmpty, isTrue);
    expect(state.score, 0);
    expect(state.combo, 0);
    expect(state.tray.whereType<String>(), hasLength(traySize));
  });

  test('deterministic: same seed and moves give identical end states', () {
    final a = playGreedy(GameEngine.newGame(2026), 60);
    final b = playGreedy(GameEngine.newGame(2026), 60);
    expect(a.score, b.score);
    expect(a.rngState, b.rngState);
    expect(a.tray, b.tray);
    expect(render(a.board), render(b.board));
    expect(a.score, greaterThan(0));
  });

  test('rejects illegal placements and used slots', () {
    final state = GameEngine.newGame(1);
    expect(GameEngine.place(state, 0, 7, 7) == null, isTrue);
    // Play slot 0 somewhere legal, then try to reuse it.
    final outcome = GameEngine.place(state, 0, 0, 0)!;
    expect(outcome.state.tray[0], isNull);
    expect(GameEngine.place(outcome.state, 0, 4, 4), isNull);
  });

  test('placing scores 1 point per cell', () {
    final state = GameEngine.newGame(7);
    final piece = pieceById[state.tray[0]!]!;
    final outcome = GameEngine.place(state, 0, 0, 0)!;
    expect(outcome.events.scoreDelta, piece.cells.length);
    expect(outcome.events.linesCleared, 0);
    expect(outcome.events.combo, 0);
  });

  test('line clear scores, combo builds, breaks on a dry placement', () {
    // Row 0 one cell short; column 7 nearly full for the follow-up clear.
    var state = GameEngine.newGame(1).copyWith(
      board: boardFrom([
        '1111111.',
        '.......1',
        '.......1',
        '.......1',
        '.......1',
        '.......1',
        '.......1',
        '........',
      ]),
      tray: [
        'single',
        'single',
        'line2v',
        'single',
        'single',
      ].sublist(0, 3), // single, single, line2v
    );

    // 1st clear: completes row 0 AND column 7 (single at 0,7) -> 2 lines.
    var outcome = GameEngine.place(state, 0, 0, 7)!;
    expect(outcome.events.clearedRows, [0]);
    expect(outcome.events.clearedCols, isEmpty); // (7,7) still empty
    expect(outcome.events.combo, 1);
    expect(outcome.events.scoreDelta, 1 + 10); // cell + single line
    state = outcome.state;

    // Dry placement: combo resets.
    outcome = GameEngine.place(state, 1, 3, 3)!;
    expect(outcome.events.linesCleared, 0);
    expect(outcome.state.combo, 0);
    expect(outcome.state.roundBestCombo, 1);
  });

  test('consecutive clears increment combo and pay the bonus', () {
    var state = GameEngine.newGame(1).copyWith(
      // The stray cell at (7,0) keeps the second clear from being an
      // all-clear, so this isolates the combo bonus.
      board: boardFrom([
        '1111111.',
        '1111111.',
        '........',
        '........',
        '........',
        '........',
        '........',
        '1.......',
      ]),
      tray: ['single', 'single', 'single'],
    );
    var outcome = GameEngine.place(state, 0, 0, 7)!;
    expect(outcome.events.combo, 1);
    expect(outcome.events.scoreDelta, 1 + 10);
    outcome = GameEngine.place(outcome.state, 1, 1, 7)!;
    expect(outcome.events.combo, 2);
    expect(outcome.events.scoreDelta, 1 + 10 + 10); // + combo bonus
    expect(outcome.state.roundBestCombo, 2);
  });

  test('all-clear pays the bonus and flags the event', () {
    var state = GameEngine.newGame(1).copyWith(
      board: boardFrom([
        '11111.11',
        '........',
        '........',
        '........',
        '........',
        '........',
        '........',
        '........',
      ]),
      tray: ['single', 'single', 'single'],
    );
    final outcome = GameEngine.place(state, 0, 0, 5)!;
    expect(outcome.events.allClear, isTrue);
    expect(outcome.state.board.isEmpty, isTrue);
    expect(outcome.events.scoreDelta, 1 + 10 + allClearBonus);
  });

  test('tray refills after the third placement', () {
    var state = GameEngine.newGame(3);
    var refills = 0;
    for (var i = 0; i < 3; i++) {
      final slot = state.tray.indexWhere((id) => id != null);
      // Greedy first legal position.
      GameState? next;
      for (var row = 0; row < 8 && next == null; row++) {
        for (var col = 0; col < 8 && next == null; col++) {
          final outcome = GameEngine.place(state, slot, row, col);
          if (outcome != null) {
            next = outcome.state;
            if (outcome.events.trayRefilled) refills++;
          }
        }
      }
      state = next!;
    }
    expect(refills, 1);
    expect(state.tray.whereType<String>(), hasLength(traySize));
  });

  test('gems in cleared lines accumulate on the run state', () {
    var state = GameEngine.newGame(1).copyWith(
      board: boardFrom([
        '1p1r111.',
        '........',
        '........',
        '........',
        '........',
        '........',
        '........',
        '........',
      ]),
      tray: ['single', 'single', 'single'],
    );
    final outcome = GameEngine.place(state, 0, 0, 7)!;
    expect(outcome.events.gems, {GemColor.purple: 1, GemColor.red: 1});
    expect(outcome.state.gemsCollected, {GemColor.purple: 1, GemColor.red: 1});
  });

  test('game over when no tray piece fits, not before', () {
    final crampedRows = [
      '.1111111',
      '11111111',
      '11111111',
      '11111111',
      '11111111',
      '11111111',
      '11111111',
      '1111111.',
    ];
    final bigOnly = GameEngine.newGame(1).copyWith(
      board: boardFrom(crampedRows),
      tray: ['square3', 'line5h', 'rect2x3'],
    );
    expect(GameEngine.isGameOver(bigOnly), isTrue);

    final withSingle = bigOnly.copyWith(tray: ['square3', 'single', null]);
    expect(GameEngine.isGameOver(withSingle), isFalse);
  });
}
