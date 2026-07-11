import '../models/board.dart';
import '../models/cell.dart';

/// Result of clearing all simultaneously full lines from a board.
class ClearResult {
  const ClearResult(this.board, this.rows, this.cols, this.gems);

  final Board board;

  /// Cleared row / column indices, ascending.
  final List<int> rows;
  final List<int> cols;

  /// Gems that sat in cleared cells, by color.
  final Map<GemColor, int> gems;

  int get lineCount => rows.length + cols.length;
}

/// Detects every full row and column of [board] simultaneously and clears
/// their union (a cell at a full row × full col intersection clears once).
ClearResult clearFullLines(Board board) {
  final rows = <int>[];
  final cols = <int>[];
  for (var i = 0; i < Board.size; i++) {
    var rowFull = true;
    var colFull = true;
    for (var j = 0; j < Board.size; j++) {
      if (!board.isOccupied(i, j)) rowFull = false;
      if (!board.isOccupied(j, i)) colFull = false;
    }
    if (rowFull) rows.add(i);
    if (colFull) cols.add(i);
  }
  if (rows.isEmpty && cols.isEmpty) {
    return ClearResult(board, const [], const [], const {});
  }

  final updates = <int, Cell?>{};
  final gems = <GemColor, int>{};
  void clearCell(int row, int col) {
    final index = row * Board.size + col;
    if (updates.containsKey(index)) return;
    final gem = board.cells[index]?.gem;
    if (gem != null) gems[gem] = (gems[gem] ?? 0) + 1;
    updates[index] = null;
  }

  for (final row in rows) {
    for (var col = 0; col < Board.size; col++) {
      clearCell(row, col);
    }
  }
  for (final col in cols) {
    for (var row = 0; row < Board.size; row++) {
      clearCell(row, col);
    }
  }
  return ClearResult(board.withUpdates(updates), rows, cols, gems);
}
