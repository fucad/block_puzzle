/// Placement legality and stamping. Pure functions over immutable boards.
library;

import '../models/board.dart';
import '../models/cell.dart';
import '../models/piece.dart';

/// True if [piece] can be placed with its bounding-box top-left at
/// ([row], [col]): fully in bounds and only over empty cells.
bool canPlace(Board board, Piece piece, int row, int col) {
  if (row < 0 || col < 0) return false;
  if (row + piece.height > Board.size || col + piece.width > Board.size) {
    return false;
  }
  for (final (r, c) in piece.cells) {
    if (board.isOccupied(row + r, col + c)) return false;
  }
  return true;
}

/// Writes [piece] onto the board. Caller must have checked [canPlace].
Board stamp(Board board, Piece piece, int row, int col) {
  assert(canPlace(board, piece, row, col));
  return board.withUpdates({
    for (final (r, c) in piece.cells)
      (row + r) * Board.size + (col + c): Cell(piece.colorId),
  });
}

/// Like [stamp], but attaches gems to the placed cells: [gems] maps a
/// piece-cell index (into `piece.cells`) to a gem color. Used for the
/// quest gem stages where tray pieces carry gems.
Board stampWithGems(
  Board board,
  Piece piece,
  int row,
  int col,
  Map<int, GemColor> gems,
) {
  assert(canPlace(board, piece, row, col));
  final updates = <int, Cell?>{};
  for (final (i, (r, c)) in piece.cells.indexed) {
    updates[(row + r) * Board.size + (col + c)] = Cell(
      piece.colorId,
      gem: gems[i],
    );
  }
  return board.withUpdates(updates);
}

/// True if [piece] fits somewhere on [board].
bool fitsAnywhere(Board board, Piece piece) {
  for (var row = 0; row <= Board.size - piece.height; row++) {
    for (var col = 0; col <= Board.size - piece.width; col++) {
      if (canPlace(board, piece, row, col)) return true;
    }
  }
  return false;
}

/// True if placing [piece] at ([row], [col]) would complete ≥1 row or
/// column — without allocating a stamped board (the hot path in tray
/// generation runs this across every piece × position each refill).
/// Caller ensures the placement is legal.
bool placementCompletesLine(Board board, Piece piece, int row, int col) =>
    countCompletedLines(board, piece, row, col) > 0;

/// How many rows + columns placing [piece] at ([row], [col]) would
/// complete simultaneously. Allocation-free. Caller ensures legality.
int countCompletedLines(Board board, Piece piece, int row, int col) {
  bool isFilled(int r, int c) {
    if (board.isOccupied(r, c)) return true;
    for (final (pr, pc) in piece.cells) {
      if (row + pr == r && col + pc == c) return true;
    }
    return false;
  }

  var count = 0;
  final rowsSeen = <int>{};
  for (final (pr, _) in piece.cells) {
    final r = row + pr;
    if (!rowsSeen.add(r)) continue;
    var full = true;
    for (var c = 0; c < Board.size; c++) {
      if (!isFilled(r, c)) {
        full = false;
        break;
      }
    }
    if (full) count++;
  }
  final colsSeen = <int>{};
  for (final (_, pc) in piece.cells) {
    final c = col + pc;
    if (!colsSeen.add(c)) continue;
    var full = true;
    for (var r = 0; r < Board.size; r++) {
      if (!isFilled(r, c)) {
        full = false;
        break;
      }
    }
    if (full) count++;
  }
  return count;
}
