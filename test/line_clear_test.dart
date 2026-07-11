import 'package:block_puzzle/models/cell.dart';
import 'package:block_puzzle/systems/line_clear.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

void main() {
  test('no full lines leaves the board untouched', () {
    final board = boardFrom([
      '1111111.',
      '........',
      '........',
      '........',
      '........',
      '........',
      '........',
      '........',
    ]);
    final result = clearFullLines(board);
    expect(result.lineCount, 0);
    expect(result.board, same(board));
    expect(result.gems, isEmpty);
  });

  test('clears a single full row, leaving other cells alone', () {
    final board = boardFrom([
      '........',
      '11111111',
      '..2.....',
      '........',
      '........',
      '........',
      '........',
      '........',
    ]);
    final result = clearFullLines(board);
    expect(result.rows, [1]);
    expect(result.cols, isEmpty);
    expect(render(result.board)[1], '........');
    expect(render(result.board)[2], '..2.....');
  });

  test('clears a single full column', () {
    final board = boardFrom([
      '..3.....',
      '..3.....',
      '..31....',
      '..3.....',
      '..3.....',
      '..3.....',
      '..3.....',
      '..3.....',
    ]);
    final result = clearFullLines(board);
    expect(result.rows, isEmpty);
    expect(result.cols, [2]);
    expect(render(result.board)[2], '...1....');
  });

  test('clears intersecting row and column simultaneously', () {
    final board = boardFrom([
      '..1.....',
      '..1.....',
      '11111111',
      '..1.....',
      '..1.....',
      '..1.....',
      '..1.....',
      '..1.....',
    ]);
    final result = clearFullLines(board);
    expect(result.rows, [2]);
    expect(result.cols, [2]);
    expect(result.lineCount, 2);
    expect(result.board.isEmpty, isTrue);
  });

  test('clears multiple rows at once', () {
    final board = boardFrom([
      '11111111',
      '11111111',
      '........',
      '........',
      '........',
      '........',
      '........',
      '....5...',
    ]);
    final result = clearFullLines(board);
    expect(result.rows, [0, 1]);
    expect(render(result.board)[7], '....5...');
  });

  test('collects gems from cleared lines, intersection counted once', () {
    final board = boardFrom([
      '..r.....',
      '..1.....',
      '1p111b11',
      '..1.....',
      '..1.....',
      '..1.....',
      '..1.....',
      '..p.....',
    ]);
    // Row 2 and column 2 are both full; gem at (2,1) purple, (2,5) blue in
    // the row; (0,2) red... wait: (0,2) is 'r' — column 2 holds r at row 0
    // and p at row 7.
    final result = clearFullLines(board);
    expect(result.rows, [2]);
    expect(result.cols, [2]);
    expect(result.gems, {
      GemColor.red: 1,
      GemColor.purple: 2,
      GemColor.blue: 1,
    });
    expect(result.board.isEmpty, isTrue);
  });
}
