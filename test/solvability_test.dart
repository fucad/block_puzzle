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

  group('FitProfile', () {
    test('snug placement scores higher contact than open space', () {
      // A 1x1 hole fully enclosed by filled cells: a single dropped there
      // touches filled neighbours on all 4 sides -> contact 1.0.
      final enclosed = boardFrom([
        '........',
        '........',
        '........',
        '...1....',
        '..1.1...', // hole at (4,3), surrounded by 1s at N/S/E/W
        '...1....',
        '........',
        '........',
      ]);
      final single = pieceById['single']!;
      final snug = FitProfile.of(enclosed, single);
      expect(snug.fits, isTrue);
      expect(snug.bestContact, 1.0);

      // Same single on an empty board only ever contacts the border, so
      // its best snugness is far lower.
      final open = FitProfile.of(boardFrom(List.filled(8, '........')), single);
      expect(open.bestContact, lessThan(snug.bestContact));
    });

    test('reports break capability', () {
      final board = boardFrom([
        '........',
        '........',
        '........',
        '........',
        '........',
        '........',
        '........',
        '1111111.', // single at (7,7) completes row 7
      ]);
      final profile = FitProfile.of(board, pieceById['single']!);
      expect(profile.canBreak, isTrue);
    });
  });
}
