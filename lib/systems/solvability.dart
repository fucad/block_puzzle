/// Set-level playability checks, shared by the tray generator (only deal
/// sets the player can actually finish) and the quest validator (opening
/// trays must deliver their promised first clear).
library;

import '../models/board.dart';
import '../models/piece.dart';
import 'game_constants.dart';
import 'line_clear.dart';
import 'placement.dart';

/// True if some position of [piece] on [board] completes ≥1 line.
bool canClearLineWith(Board board, Piece piece) {
  for (var row = 0; row <= Board.size - piece.height; row++) {
    for (var col = 0; col <= Board.size - piece.width; col++) {
      if (!canPlace(board, piece, row, col)) continue;
      if (clearFullLines(stamp(board, piece, row, col)).lineCount > 0) {
        return true;
      }
    }
  }
  return false;
}

/// How a piece relates to the current board, computed in one placement
/// scan (drives satisfaction-first tray dealing).
class FitProfile {
  const FitProfile({
    required this.fits,
    required this.canBreak,
    required this.bestContact,
  });

  /// Fits somewhere at all.
  final bool fits;

  /// Some placement completes a line right now.
  final bool canBreak;

  /// Best "snugness" over all placements, in [0, 1]: the fraction of the
  /// piece's outer cell-edges that press against a filled cell or the
  /// board border. High = the piece slots flush into a gap rather than
  /// landing in open space.
  final double bestContact;

  static const _neighbors = [(-1, 0), (1, 0), (0, -1), (0, 1)];

  static FitProfile of(Board board, Piece piece) {
    var fits = false;
    var canBreak = false;
    var best = 0.0;
    final edges = 4 * piece.cells.length;
    for (var row = 0; row <= Board.size - piece.height; row++) {
      for (var col = 0; col <= Board.size - piece.width; col++) {
        if (!canPlace(board, piece, row, col)) continue;
        fits = true;
        if (!canBreak &&
            clearFullLines(stamp(board, piece, row, col)).lineCount > 0) {
          canBreak = true;
        }
        var contact = 0;
        for (final (r, c) in piece.cells) {
          final pr = row + r;
          final pc = col + c;
          for (final (dr, dc) in _neighbors) {
            final nr = pr + dr;
            final nc = pc + dc;
            // Border or a cell already filled on the board (same-piece
            // neighbours are empty on the original board, so they don't
            // count — only true nestling does).
            if (nr < 0 ||
                nr >= Board.size ||
                nc < 0 ||
                nc >= Board.size ||
                board.isOccupied(nr, nc)) {
              contact++;
            }
          }
        }
        final ratio = contact / edges;
        if (ratio > best) best = ratio;
      }
    }
    return FitProfile(fits: fits, canBreak: canBreak, bestContact: best);
  }
}

/// True if there is an order in which ALL [pieces] can be placed such
/// that EVERY placement clears at least one line — the quest "opening
/// cascade" contract: the starting tray fits right into the designed
/// board, and each drop breaks. Leftover blocks may remain.
bool openingCascadeExists(Board board, List<Piece> pieces) {
  bool search(Board b, List<Piece> rest) {
    if (rest.isEmpty) return true;
    final triedIds = <String>{};
    for (var i = 0; i < rest.length; i++) {
      final piece = rest[i];
      if (!triedIds.add(piece.id)) continue;
      final remaining = [...rest]..removeAt(i);
      for (var row = 0; row <= Board.size - piece.height; row++) {
        for (var col = 0; col <= Board.size - piece.width; col++) {
          if (!canPlace(b, piece, row, col)) continue;
          final result = clearFullLines(stamp(b, piece, row, col));
          if (result.lineCount == 0) continue; // every drop must break
          if (search(result.board, remaining)) return true;
        }
      }
    }
    return false;
  }

  return search(board, pieces);
}

/// True if the [pieces] can ALL be placed in some order (clears happen
/// between placements, exactly as in play). Backtracking with a node cap:
/// if the search budget runs out undecided, assume playable — a rare
/// false positive only weakens a heuristic, while an unbounded search
/// could stall a tray refill.
bool canPlaceAllInSomeOrder(Board board, List<Piece> pieces) {
  var nodes = 0;
  bool search(Board b, List<Piece> rest) {
    if (rest.isEmpty) return true;
    if (++nodes > solvabilityNodeCap) return true;
    final triedIds = <String>{};
    for (var i = 0; i < rest.length; i++) {
      final piece = rest[i];
      if (!triedIds.add(piece.id)) continue; // duplicates are equivalent
      final remaining = [...rest]..removeAt(i);
      for (var row = 0; row <= Board.size - piece.height; row++) {
        for (var col = 0; col <= Board.size - piece.width; col++) {
          if (!canPlace(b, piece, row, col)) continue;
          final next = clearFullLines(stamp(b, piece, row, col)).board;
          if (search(next, remaining)) return true;
        }
      }
    }
    return false;
  }

  return search(board, pieces);
}
