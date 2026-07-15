import '../models/board.dart';
import '../models/cell.dart';
import '../models/piece.dart';
import '../models/piece_catalog.dart';
import 'game_constants.dart';
import 'rng.dart';
import 'solvability.dart';

/// Draws trays of [traySize] pieces from the catalog. Four forces shape
/// every deal (contract documented in ARCHITECTURE.md):
///
/// 1. **Fit weighting** — pieces that don't fit the board are damped by
///    [fitPenalty]; if a whole draw is dead while something fits, the
///    last slot is redrawn from the fitting pieces.
/// 2. **Snug fit** — pieces that slot flush into existing gaps are
///    favored by up to [snugBoost] (see FitProfile.bestContact): fitting
///    into the empty spots is the satisfaction, so the deal serves it.
/// 3. **Breaker boost** — pieces that could complete a line right now are
///    boosted by [breakerBoost]: clearing is the payoff.
/// 4. **Set solvability** — up to [traySetDrawAttempts] candidate sets are
///    drawn, and the first one playable in SOME order wins (preferring
///    sets that contain a breaker when a break is possible at all). The
///    player might not find the order, but one always exists while the
///    board allows it.
///
/// [clearFocus] (classic mode) turns this up: breakers are boosted far
/// harder, open boards favor big/long pieces to set up multi-line clears
/// and all-clears, and among more candidate sets the one that can clear
/// the most lines (by [clearingPotential]) is chosen — so clears and
/// combos happen almost every tray.
class PieceGenerator {
  PieceGenerator(this.rng);

  final GameRng rng;

  List<Piece> nextTray(Board board, {bool clearFocus = false}) {
    final profiles = {
      for (final piece in pieceCatalog) piece.id: FitProfile.of(board, piece),
    };
    final fitting = {
      for (final piece in pieceCatalog)
        if (profiles[piece.id]!.fits) piece.id,
    };
    final breakers = {
      for (final piece in pieceCatalog)
        if (profiles[piece.id]!.canBreak) piece.id,
    };

    final filled = board.cells.where((c) => c != null).length;
    final openBoard =
        clearFocus &&
        filled / (Board.size * Board.size) < classicOpenBoardFullness;
    final breakMult = clearFocus ? classicBreakerBoost : breakerBoost;

    double effectiveWeight(Piece p) {
      final prof = profiles[p.id]!;
      var w =
          p.weight *
          (prof.fits ? 1.0 : fitPenalty) *
          (prof.canBreak ? breakMult : 1.0) *
          (1 + prof.bestContact * snugBoost);
      // Open board in classic: hand out big/long pieces to fill fast.
      if (openBoard) w *= 1 + p.cells.length * classicBigPieceBias;
      return w;
    }

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

    final attempts = clearFocus ? classicDrawAttempts : traySetDrawAttempts;

    if (clearFocus) {
      // Keep the playable set that can clear the most lines.
      List<Piece>? bestSet;
      var bestScore = -1;
      for (var attempt = 0; attempt < attempts; attempt++) {
        final tray = draw();
        if (!canPlaceAllInSomeOrder(board, tray)) continue;
        final score = clearingPotential(board, tray);
        if (score > bestScore) {
          bestScore = score;
          bestSet = tray;
          // A double-line-or-better set is plenty satisfying; take it.
          if (score >= 2) break;
        }
      }
      if (bestSet != null) return bestSet;
    }

    List<Piece>? solvableFallback;
    var best = draw();
    for (var attempt = 0; attempt < attempts; attempt++) {
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

  /// Assigns gems to a freshly-drawn [tray] for a quest gem stage. Only
  /// colors still [needed] (need > 0) are spawned, weighted by how many are
  /// left. Each piece has a chance of carrying one gem (bigger pieces may
  /// carry two); many pieces carry none. Consumes [rng] deterministically,
  /// so it must run right after [nextTray] using the same generator.
  List<Map<int, GemColor>> assignGems(
    List<Piece> tray,
    Map<GemColor, int> needed,
  ) {
    final colors = [
      for (final e in needed.entries)
        if (e.value > 0) e,
    ];
    if (colors.isEmpty) {
      return List.generate(tray.length, (_) => const <int, GemColor>{});
    }
    var total = colors.fold(0, (a, e) => a + e.value);
    GemColor pick() {
      var roll = rng.nextInt(total);
      for (final e in colors) {
        roll -= e.value;
        if (roll < 0) return e.key;
      }
      return colors.last.key;
    }

    return [
      for (final piece in tray)
        if (rng.nextDouble() < gemSpawnChance)
          {
            rng.nextInt(piece.cells.length): pick(),
            if (piece.cells.length >= 4 && rng.nextDouble() < gemSecondChance)
              rng.nextInt(piece.cells.length): pick(),
          }
        else
          const <int, GemColor>{},
    ];
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
