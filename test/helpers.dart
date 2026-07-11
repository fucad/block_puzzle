import 'package:block_puzzle/models/board.dart';
import 'package:block_puzzle/models/cell.dart';

/// Builds a board from 8 strings of 8 chars. `.` = empty, a digit = occupied
/// with that colorId, a letter = occupied (colorId 0) holding a gem:
/// r/b/p/y/g = red/blue/purple/yellow/green.
Board boardFrom(List<String> rows) {
  assert(rows.length == Board.size);
  final cells = <Cell?>[];
  for (final row in rows) {
    assert(row.length == Board.size);
    for (final ch in row.split('')) {
      if (ch == '.') {
        cells.add(null);
      } else if (RegExp(r'\d').hasMatch(ch)) {
        cells.add(Cell(int.parse(ch)));
      } else {
        const gems = {
          'r': GemColor.red,
          'b': GemColor.blue,
          'p': GemColor.purple,
          'y': GemColor.yellow,
          'g': GemColor.green,
        };
        cells.add(Cell(0, gem: gems[ch]!));
      }
    }
  }
  return Board.fromCells(cells);
}

/// Renders a board back to the `boardFrom` string form (gems lowercase,
/// occupied = colorId digit) for readable assertion failures.
List<String> render(Board board) {
  const gemChars = {
    GemColor.red: 'r',
    GemColor.blue: 'b',
    GemColor.purple: 'p',
    GemColor.yellow: 'y',
    GemColor.green: 'g',
  };
  return [
    for (var r = 0; r < Board.size; r++)
      [
        for (var c = 0; c < Board.size; c++)
          switch (board.at(r, c)) {
            null => '.',
            final cell when cell.gem != null => gemChars[cell.gem]!,
            final cell => '${cell.colorId}',
          },
      ].join(),
  ];
}
