import '../models/board.dart';
import '../models/piece.dart';
import '../models/piece_catalog.dart';
import 'game_constants.dart';
import 'placement.dart';
import 'rng.dart';
import 'solvability.dart';

/// Draws trays of [traySize] pieces from the catalog. Three forces shape
/// every deal (contract documented in ARCHITECTURE.md):
///
/// 1. **Fit weighting** — pieces that don't fit the board are damped by
///    [fitPenalty]; if a whole draw is dead while something fits, the
///    last slot is redrawn from the fitting pieces.
/// 2. **Breaker boost** — pieces that could complete a line right now are
///    boosted by [breakerBoost]: clearing is the game's satisfaction, so
///    the deal leans into it.
/// 3. **Set solvability** — up to [traySetDrawAttempts] candidate sets are
///    drawn, and the first one playable in SOME order wins (preferring
///    sets that contain a breaker when a break is possible at all). The
///    player might not find the order, but one always exists while the
///    board allows it.
class PieceGenerator {
  PieceGenerator(this.rng);

  final GameRng rng;

  List<Piece> nextTray(Board board) {
    final fitting = <String>{};
    final breakers = <String>{};
    for (final piece in pieceCatalog) {
      if (fitsAnywhere(board, piece)) {
        fitting.add(piece.id);
        if (canClearLineWith(board, piece)) breakers.add(piece.id);
      }
    }
    double effectiveWeight(Piece p) =>
        p.weight *
        (fitting.contains(p.id) ? 1.0 : fitPenalty) *
        (breakers.contains(p.id) ? breakerBoost : 1.0);

    List<Piece> draw() {
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

    List<Piece>? solvableFallback;
    var best = draw();
    for (var attempt = 0; attempt < traySetDrawAttempts; attempt++) {
      final tray = attempt == 0 ? best : draw();
      best = tray;
      if (!canPlaceAllInSomeOrder(board, tray)) continue;
      if (breakers.isEmpty || tray.any((p) => breakers.contains(p.id))) {
        return tray; // playable and as satisfying as the board allows
      }
      solvableFallback ??= tray;
    }
    return solvableFallback ?? best;
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
