import 'package:block_puzzle/models/board.dart';
import 'package:block_puzzle/models/piece_catalog.dart';
import 'package:block_puzzle/systems/placement.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

void main() {
  final line3h = pieceById['line3h']!;
  final square3 = pieceById['square3']!;
  final single = pieceById['single']!;

  group('canPlace', () {
    test('anywhere in bounds on an empty board', () {
      final board = Board.empty();
      expect(canPlace(board, line3h, 0, 0), isTrue);
      expect(canPlace(board, line3h, 7, 5), isTrue);
      expect(canPlace(board, square3, 5, 5), isTrue);
    });

    test('rejects out of bounds', () {
      final board = Board.empty();
      expect(canPlace(board, line3h, 0, 6), isFalse); // off right edge
      expect(canPlace(board, square3, 6, 0), isFalse); // off bottom edge
      expect(canPlace(board, line3h, -1, 0), isFalse);
      expect(canPlace(board, line3h, 0, -1), isFalse);
    });

    test('rejects overlap with occupied cells', () {
      final board = boardFrom([
        '........',
        '...1....',
        '........',
        '........',
        '........',
        '........',
        '........',
        '........',
      ]);
      expect(canPlace(board, line3h, 1, 1), isFalse); // covers (1,3)
      expect(canPlace(board, line3h, 1, 4), isTrue); // just past it
      expect(canPlace(board, single, 1, 3), isFalse);
    });
  });

  test('stamp writes the piece cells with its color', () {
    final board = stamp(Board.empty(), line3h, 2, 3);
    expect(render(board), [
      '........',
      '........',
      '...111..',
      '........',
      '........',
      '........',
      '........',
      '........',
    ]);
  });

  group('fitsAnywhere', () {
    test('false when the only holes are too small', () {
      final almostFull = boardFrom([
        '.1111111',
        '11111111',
        '11111111',
        '11111111',
        '11111111',
        '11111111',
        '11111111',
        '1111111.',
      ]);
      expect(fitsAnywhere(almostFull, single), isTrue);
      expect(fitsAnywhere(almostFull, line3h), isFalse);
      expect(fitsAnywhere(almostFull, square3), isFalse);
    });

    test('true when exactly one slot fits', () {
      final board = boardFrom([
        '...11111',
        '11111111',
        '11111111',
        '11111111',
        '11111111',
        '11111111',
        '11111111',
        '11111111',
      ]);
      expect(fitsAnywhere(board, line3h), isTrue);
    });
  });
}
