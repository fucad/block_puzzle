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
