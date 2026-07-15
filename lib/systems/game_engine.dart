import '../models/board.dart';
import '../models/cell.dart';
import '../models/game_state.dart';
import '../models/piece_catalog.dart';
import 'game_constants.dart';
import 'line_clear.dart';
import 'piece_generator.dart';
import 'placement.dart' as placement;
import 'rng.dart';
import 'scoring.dart';

/// What one placement did — consumed by effects, audio, and quest goals.
class PlacementEvents {
  const PlacementEvents({
    required this.scoreDelta,
    required this.clearedRows,
    required this.clearedCols,
    required this.combo,
    required this.allClear,
    required this.gems,
    required this.trayRefilled,
  });

  final int scoreDelta;
  final List<int> clearedRows;
  final List<int> clearedCols;

  /// Combo level after this placement (0 if the streak just broke).
  final int combo;

  final bool allClear;
  final Map<GemColor, int> gems;
  final bool trayRefilled;

  int get linesCleared => clearedRows.length + clearedCols.length;
}

class PlacementOutcome {
  const PlacementOutcome(this.state, this.events);

  final GameState state;
  final PlacementEvents events;
}

/// Pure, deterministic rules engine: `place(state, ...)` is the only way a
/// run advances. Given a seed and a placement sequence, the resulting state
/// is exactly reproducible (tested in game_engine_test.dart).
class GameEngine {
  /// Fresh run: [board] is empty for Classic or pre-placed for a Quest
  /// stage. The first tray is drawn from [seed] — unless the stage pins
  /// an [initialTray] (quest "opening break" design), which bypasses the
  /// generator for that first set only.
  static GameState newGame(
    int seed, {
    Board? board,
    List<String>? initialTray,
    bool clearFocus = false,
  }) {
    assert(initialTray == null || initialTray.length == traySize);
    assert(initialTray?.every(pieceById.containsKey) ?? true);
    final startBoard = board ?? Board.empty();
    final rng = GameRng(seed);
    final tray =
        initialTray ??
        [
          for (final p in PieceGenerator(
            rng,
          ).nextTray(startBoard, clearFocus: clearFocus))
            p.id,
        ];
    return GameState(
      board: startBoard,
      tray: List.of(tray),
      rngState: rng.state,
      score: 0,
      combo: 0,
      roundBestCombo: 0,
      clearFocus: clearFocus,
    );
  }

  /// Applies one placement. Returns null if [trayIndex] is empty or the
  /// piece doesn't fit at ([row], [col]).
  static PlacementOutcome? place(
    GameState state,
    int trayIndex,
    int row,
    int col,
  ) {
    final pieceId = state.tray[trayIndex];
    if (pieceId == null) return null;
    final piece = pieceById[pieceId]!;
    if (!placement.canPlace(state.board, piece, row, col)) return null;

    final stamped = placement.stamp(state.board, piece, row, col);
    final clear = clearFullLines(stamped);

    // Combo: any clearing placement extends the streak; a placement that
    // clears nothing resets it to 0 (decision 2026-07-11).
    final combo = clear.lineCount > 0 ? state.combo + 1 : 0;
    final allClear = clear.lineCount > 0 && clear.board.isEmpty;
    var delta = piece.cells.length * pointsPerCell;
    if (clear.lineCount > 0) {
      delta += lineScore(clear.lineCount) + comboBonus(combo);
    }
    if (allClear) delta += allClearBonus;

    var tray = [
      for (var i = 0; i < state.tray.length; i++)
        i == trayIndex ? null : state.tray[i],
    ];
    var rngState = state.rngState;
    final trayRefilled = tray.every((id) => id == null);
    if (trayRefilled) {
      final rng = GameRng.fromState(rngState);
      tray = [
        for (final p in PieceGenerator(
          rng,
        ).nextTray(clear.board, clearFocus: state.clearFocus))
          p.id,
      ];
      rngState = rng.state;
    }

    final gems = state.gemsCollected;
    final nextState = state.copyWith(
      board: clear.board,
      tray: tray,
      rngState: rngState,
      score: state.score + delta,
      combo: combo,
      roundBestCombo: combo > state.roundBestCombo
          ? combo
          : state.roundBestCombo,
      allClears: allClear ? state.allClears + 1 : state.allClears,
      gemsCollected: clear.gems.isEmpty
          ? gems
          : {
              for (final color in GemColor.values)
                if ((gems[color] ?? 0) + (clear.gems[color] ?? 0) > 0)
                  color: (gems[color] ?? 0) + (clear.gems[color] ?? 0),
            },
    );
    return PlacementOutcome(
      nextState,
      PlacementEvents(
        scoreDelta: delta,
        clearedRows: clear.rows,
        clearedCols: clear.cols,
        combo: combo,
        allClear: allClear,
        gems: clear.gems,
        trayRefilled: trayRefilled,
      ),
    );
  }

  /// Game over: no remaining tray piece fits anywhere.
  static bool isGameOver(GameState state) {
    for (final pieceId in state.tray) {
      if (pieceId == null) continue;
      if (placement.fitsAnywhere(state.board, pieceById[pieceId]!)) {
        return false;
      }
    }
    return true;
  }
}
