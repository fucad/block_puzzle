/// A polyomino piece. Pieces never rotate at runtime — every orientation is
/// its own catalog entry (see piece_catalog.dart).
class Piece {
  const Piece(this.id, this.cells, {required this.colorId, this.weight = 1.0});

  final String id;

  /// Normalized (row, col) offsets: min row and min col are both 0.
  final List<(int, int)> cells;

  /// Index into the active theme's block palette.
  final int colorId;

  /// Relative spawn weight before fit-weighting (see PieceGenerator).
  final double weight;

  int get height => 1 + cells.map((c) => c.$1).reduce((a, b) => a > b ? a : b);

  int get width => 1 + cells.map((c) => c.$2).reduce((a, b) => a > b ? a : b);
}
