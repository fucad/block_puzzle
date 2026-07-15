import 'package:block_puzzle/models/piece.dart';
import 'package:block_puzzle/models/piece_catalog.dart';
import 'package:block_puzzle/systems/solvability.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

void main() {
  List<Piece> pieces(List<String> ids) => [
    for (final id in ids) pieceById[id]!,
  ];

  group('openingCascadeExists', () {
    test('true when every tray piece fills a gap and breaks its line', () {
      // Three parallel rows with gaps sized 3 / 2 / 1 (this is starter
      // s01's shape); the matching tray completes all three.
      final board = boardFrom([
        '........',
        '........',
        '........',
        '........',
        '........',
        '11...111', // gap cols 2-4 (3 wide)
        '000..000', // gap cols 3-4 (2 wide)
        '3333.333', // gap col 4  (1 wide)
      ]);
      expect(
        openingCascadeExists(board, pieces(['line3h', 'line2h', 'single'])),
        isTrue,
      );
    });

    test('false when the tray cannot fill the gaps that clear', () {
      // Same board, but two line2h cannot fill the 3-wide top gap, so no
      // order makes all three break.
      final board = boardFrom([
        '........',
        '........',
        '........',
        '........',
        '........',
        '11...111',
        '000..000',
        '3333.333',
      ]);
      expect(
        openingCascadeExists(board, pieces(['line2h', 'line2h', 'single'])),
        isFalse,
      );
    });

    test('false when only one line can be broken', () {
      final board = boardFrom([
        '........',
        '........',
        '........',
        '........',
        '........',
        '........',
        '........',
        '1111111.',
      ]);
      expect(
        openingCascadeExists(board, pieces(['single', 'line2h', 'square2'])),
        isFalse,
      );
    });

    test('false on an empty board (nothing to break)', () {
      expect(
        openingCascadeExists(
          boardFrom(List.filled(8, '........')),
          pieces(['single', 'single', 'single']),
        ),
        isFalse,
      );
    });

    test('vertical gaps work too (columns)', () {
      // Three parallel columns each one cell short at the bottom.
      final board = boardFrom([
        '1.3.5...',
        '1.3.5...',
        '1.3.5...',
        '1.3.5...',
        '1.3.5...',
        '1.3.5...',
        '1.3.5...',
        '........',
      ]);
      expect(
        openingCascadeExists(board, pieces(['single', 'single', 'single'])),
        isTrue,
      );
    });
  });
}
