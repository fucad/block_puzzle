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
