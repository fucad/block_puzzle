import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/game_state.dart';
import '../systems/game_engine.dart';
import 'providers.dart';

/// Drives one classic run. Null state = no run in progress. The rules all
/// live in GameEngine; this notifier only sequences state, persistence,
/// and end-of-run bookkeeping.
class ClassicGameController extends Notifier<GameState?> {
  int? _seed;

  @override
  GameState? build() {
    // Resume a run that survived an app kill, if any.
    final saved = ref.read(saveDataProvider);
    _seed = saved.classicRunSeed;
    return saved.classicRun;
  }

  bool get isGameOver => state != null && GameEngine.isGameOver(state!);

  /// Starts a fresh run. [seed] is injectable for tests/reproduction;
  /// normally each run rolls its own from the wall clock.
  void startNew({int? seed}) {
    final s = seed ?? DateTime.now().microsecondsSinceEpoch;
    _seed = s;
    final fresh = GameEngine.newGame(s);
    state = fresh;
    ref.read(saveDataProvider.notifier).storeClassicRun(fresh, s);
  }

  /// Applies a placement. Returns the outcome (for effects/haptics) or
  /// null if illegal. On game over the run is folded into the high scores
  /// but kept in memory so summary screens can read it.
  PlacementOutcome? place(int trayIndex, int row, int col) {
    final current = state;
    if (current == null) return null;
    final outcome = GameEngine.place(current, trayIndex, row, col);
    if (outcome == null) return null;
    state = outcome.state;
    final save = ref.read(saveDataProvider.notifier);
    if (GameEngine.isGameOver(outcome.state)) {
      save.recordClassicRunEnd(
        score: outcome.state.score,
        bestCombo: outcome.state.roundBestCombo,
      );
    } else {
      save.storeClassicRun(outcome.state, _seed!);
    }
    return outcome;
  }

  /// Leaves the summary flow: forgets the finished run.
  void clearFinishedRun() {
    state = null;
  }

  /// Injects an arbitrary mid-run state to test end-of-run bookkeeping.
  @visibleForTesting
  void debugLoadRun(GameState run, {int seed = 0}) {
    _seed = seed;
    state = run;
  }
}

final classicGameProvider = NotifierProvider<ClassicGameController, GameState?>(
  ClassicGameController.new,
);
