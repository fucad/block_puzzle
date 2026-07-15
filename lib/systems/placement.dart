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
bool placementCompletesLine(Board board, Piece piece, int row, int col) {
  bool isFilled(int r, int c) {
    if (board.isOccupied(r, c)) return true;
    for (final (pr, pc) in piece.cells) {
      if (row + pr == r && col + pc == c) return true;
    }
    return false;
  }

  // Only rows/cols the piece touches can newly complete.
  for (final (pr, _) in piece.cells) {
    final r = row + pr;
    var full = true;
    for (var c = 0; c < Board.size; c++) {
      if (!isFilled(r, c)) {
        full = false;
        break;
      }
    }
    if (full) return true;
  }
  for (final (_, pc) in piece.cells) {
    final c = col + pc;
    var full = true;
    for (var r = 0; r < Board.size; r++) {
      if (!isFilled(r, c)) {
        full = false;
        break;
      }
    }
    if (full) return true;
  }
  return false;
}
