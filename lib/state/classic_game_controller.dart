import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/game_state.dart';
import '../systems/game_engine.dart';
import 'providers.dart';

/// Everything the end-of-run summary screen needs, captured at the
/// moment the run ended (before the save folded the result in).
class RunSummary {
  const RunSummary({
    required this.score,
    required this.bestCombo,
    required this.allClears,
    required this.newHighScore,
  });

  final int score;
  final int bestCombo;
  final int allClears;
  final bool newHighScore;
}

/// Drives one classic run. Null state = no run in progress. The rules all
/// live in GameEngine; this notifier only sequences state, persistence,
/// and end-of-run bookkeeping.
class ClassicGameController extends Notifier<GameState?> {
  int? _seed;

  /// Set when a run ends; read by the summary flow.
  RunSummary? lastSummary;

  @override
  GameState? build() {
    // Resume a run that survived an app kill, if any.
    final saved = ref.read(saveDataProvider);
    _seed = saved.classicRunSeed;
    return saved.classicRun;
  }

  bool get isGameOver => state != null && GameEngine.isGameOver(state!);

  /// Bug-reproduction hook: `flutter run --dart-define=SEED=42` pins every
  /// new classic run to that seed. 0 (the default) means "roll randomly".
  static const int _pinnedSeed = int.fromEnvironment('SEED');

  /// Starts a fresh run. [seed] is injectable for tests/reproduction;
  /// normally each run rolls its own from the wall clock.
  void startNew({int? seed}) {
    final s =
        seed ??
        (_pinnedSeed != 0
            ? _pinnedSeed
            : DateTime.now().microsecondsSinceEpoch);
    _seed = s;
    // Classic leans into clears/combos (quest keeps its designed balance).
    final fresh = GameEngine.newGame(s, clearFocus: true);
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
      // Capture BEFORE folding into the save: "new high score" compares
      // against the record as it stood when the run ended.
      lastSummary = RunSummary(
        score: outcome.state.score,
        bestCombo: outcome.state.roundBestCombo,
        allClears: outcome.state.allClears,
        newHighScore:
            outcome.state.score > ref.read(saveDataProvider).classicHighScore,
      );
      save.recordClassicRunEnd(
        score: outcome.state.score,
        bestCombo: outcome.state.roundBestCombo,
        allClears: outcome.state.allClears,
      );
    } else {
      save.storeClassicRun(outcome.state, _seed!);
    }
    // Record per-placement lifetime stats (blocks placed, combo streak).
    save.recordPlacement(
      cellsPlaced: outcome.events.cellsPlaced,
      comboIncreased: outcome.state.combo > 0,
    );
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
