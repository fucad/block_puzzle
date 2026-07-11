import 'piece.dart';

/// The full data-driven piece set: 29 pieces, no runtime rotation.
/// Tune shapes/weights/colors here only. Documented in ARCHITECTURE.md.
///
/// Naming: `h`/`v` horizontal/vertical; corner ids say where the elbow sits
/// (nw/ne/se/sw); t/s/z ids say which way the shape points or leans.
const List<Piece> pieceCatalog = [
  // Lines.
  Piece('line2h', [(0, 0), (0, 1)], colorId: 0),
  Piece('line3h', [(0, 0), (0, 1), (0, 2)], colorId: 1),
  Piece('line4h', [(0, 0), (0, 1), (0, 2), (0, 3)], colorId: 2),
  Piece('line5h', [(0, 0), (0, 1), (0, 2), (0, 3), (0, 4)], colorId: 3),
  Piece('line2v', [(0, 0), (1, 0)], colorId: 0),
  Piece('line3v', [(0, 0), (1, 0), (2, 0)], colorId: 1),
  Piece('line4v', [(0, 0), (1, 0), (2, 0), (3, 0)], colorId: 2),
  Piece('line5v', [(0, 0), (1, 0), (2, 0), (3, 0), (4, 0)], colorId: 3),
  // Squares and rectangles.
  Piece('square2', [(0, 0), (0, 1), (1, 0), (1, 1)], colorId: 4),
  Piece('square3', [
    (0, 0), (0, 1), (0, 2), //
    (1, 0), (1, 1), (1, 2),
    (2, 0), (2, 1), (2, 2),
  ], colorId: 5),
  Piece('rect2x3', [
    (0, 0),
    (0, 1),
    (0, 2),
    (1, 0),
    (1, 1),
    (1, 2),
  ], colorId: 6),
  Piece('rect3x2', [
    (0, 0),
    (0, 1),
    (1, 0),
    (1, 1),
    (2, 0),
    (2, 1),
  ], colorId: 6),
  // Small corners: 3 cells in a 2×2 box, elbow at the named corner.
  Piece('corner3nw', [(0, 0), (0, 1), (1, 0)], colorId: 7),
  Piece('corner3ne', [(0, 0), (0, 1), (1, 1)], colorId: 7),
  Piece('corner3se', [(0, 1), (1, 0), (1, 1)], colorId: 7),
  Piece('corner3sw', [(0, 0), (1, 0), (1, 1)], colorId: 7),
  // Large corners: 5 cells in a 3×3 box, elbow at the named corner.
  Piece('corner5sw', [(0, 0), (1, 0), (2, 0), (2, 1), (2, 2)], colorId: 2),
  Piece('corner5nw', [(0, 0), (0, 1), (0, 2), (1, 0), (2, 0)], colorId: 2),
  Piece('corner5ne', [(0, 0), (0, 1), (0, 2), (1, 2), (2, 2)], colorId: 2),
  Piece('corner5se', [(0, 2), (1, 2), (2, 0), (2, 1), (2, 2)], colorId: 2),
  // T shapes, stem pointing in the named direction.
  Piece('tDown', [(0, 0), (0, 1), (0, 2), (1, 1)], colorId: 1),
  Piece('tUp', [(0, 1), (1, 0), (1, 1), (1, 2)], colorId: 1),
  Piece('tRight', [(0, 0), (1, 0), (1, 1), (2, 0)], colorId: 1),
  Piece('tLeft', [(0, 1), (1, 0), (1, 1), (2, 1)], colorId: 1),
  // S / Z shapes.
  Piece('sH', [(0, 1), (0, 2), (1, 0), (1, 1)], colorId: 4),
  Piece('sV', [(0, 0), (1, 0), (1, 1), (2, 1)], colorId: 4),
  Piece('zH', [(0, 0), (0, 1), (1, 1), (1, 2)], colorId: 5),
  Piece('zV', [(0, 1), (1, 0), (1, 1), (2, 0)], colorId: 5),
  // Single cell — rare filler.
  Piece('single', [(0, 0)], colorId: 3, weight: 0.25),
];

final Map<String, Piece> pieceById = {
  for (final piece in pieceCatalog) piece.id: piece,
};
