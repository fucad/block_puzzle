/// Human-authorable board layout format, used by quest packs and tests.
///
/// 8 strings of 8 chars: `.` = empty, `0`-`7` = block with that palette
/// colorId, and a gem letter = gold block holding a gem:
/// `r`ed, `b`lue, `p`urple, `y`ellow, `g`reen.
library;

import 'board.dart';
import 'cell.dart';

const Map<String, GemColor> gemLetters = {
  'r': GemColor.red,
  'b': GemColor.blue,
  'p': GemColor.purple,
  'y': GemColor.yellow,
  'g': GemColor.green,
};

/// Palette colorId used for the block that carries a gem (gold-ish).
const int gemBlockColorId = 3;

/// Strict: throws [FormatException] on wrong dimensions or unknown chars.
Board parseBoardRows(List<String> rows) {
  if (rows.length != Board.size) {
    throw FormatException(
      'Board must have ${Board.size} rows, got ${rows.length}',
    );
  }
  final cells = <Cell?>[];
  for (final (r, row) in rows.indexed) {
    if (row.length != Board.size) {
      throw FormatException(
        'Board row $r must have ${Board.size} chars: "$row"',
      );
    }
    for (final ch in row.split('')) {
      if (ch == '.') {
        cells.add(null);
      } else if (gemLetters.containsKey(ch)) {
        cells.add(Cell(gemBlockColorId, gem: gemLetters[ch]));
      } else {
        final colorId = int.tryParse(ch);
        if (colorId == null || colorId > 7) {
          throw FormatException('Unknown board char "$ch" in row $r');
        }
        cells.add(Cell(colorId));
      }
    }
  }
  return Board.fromCells(cells);
}

/// Inverse of [parseBoardRows] (gems render as their letter).
List<String> renderBoardRows(Board board) {
  final letters = {for (final e in gemLetters.entries) e.value: e.key};
  return [
    for (var r = 0; r < Board.size; r++)
      [
        for (var c = 0; c < Board.size; c++)
          switch (board.at(r, c)) {
            null => '.',
            final cell when cell.gem != null => letters[cell.gem]!,
            final cell => '${cell.colorId}',
          },
      ].join(),
  ];
}
