import '../models/board.dart';
import '../models/piece.dart';
import '../models/piece_catalog.dart';
import 'game_constants.dart';
import 'placement.dart';
import 'rng.dart';

/// Draws trays of [traySize] pieces from the catalog, lightly weighted
/// toward pieces that currently fit the board. Algorithm contract is
/// documented in ARCHITECTURE.md — keep them in sync.
class PieceGenerator {
  PieceGenerator(this.rng);

  final GameRng rng;

  /// Draws the next tray for [board]:
  /// 1. effective weight = base × ([fitPenalty] if the piece doesn't fit),
  /// 2. three weighted draws with replacement,
  /// 3. guarantee: if no drawn piece fits but some catalog piece does, the
  ///    last slot is redrawn from the fitting pieces only. A fresh tray is
  ///    therefore always playable unless nothing fits at all; game overs
  ///    happen mid-tray, after the guaranteed piece is spent.
  List<Piece> nextTray(Board board) {
    final fitting = {
      for (final piece in pieceCatalog)
        if (fitsAnywhere(board, piece)) piece.id,
    };
    double effectiveWeight(Piece piece) =>
        piece.weight * (fitting.contains(piece.id) ? 1.0 : fitPenalty);

    final tray = List<Piece>.generate(
      traySize,
      (_) => _weightedDraw(pieceCatalog, effectiveWeight),
    );
    if (fitting.isNotEmpty && !tray.any((p) => fitting.contains(p.id))) {
      final candidates = [
        for (final piece in pieceCatalog)
          if (fitting.contains(piece.id)) piece,
      ];
      tray[traySize - 1] = _weightedDraw(candidates, (p) => p.weight);
    }
    return tray;
  }

  Piece _weightedDraw(List<Piece> pieces, double Function(Piece) weightOf) {
    var total = 0.0;
    for (final piece in pieces) {
      total += weightOf(piece);
    }
    var roll = rng.nextDouble() * total;
    for (final piece in pieces) {
      roll -= weightOf(piece);
      if (roll < 0) return piece;
    }
    return pieces.last;
  }
}
