import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/game_state.dart';
import '../models/quest.dart';
import '../systems/game_engine.dart';
import 'providers.dart';

enum QuestStatus { playing, won, lost }

/// One quest attempt. Unlike Classic, attempts are not persisted — a
/// closed stage restarts from its layout (reference behavior).
class QuestRun {
  const QuestRun({
    required this.pack,
    required this.stage,
    required this.levelNumber,
    required this.game,
    required this.status,
  });

  final QuestPack pack;
  final QuestStage stage;

  /// 1-based global level number (across packs) for the HUD.
  final int levelNumber;

  final GameState game;
  final QuestStatus status;

  /// Goal completion in [0, 1] — drives the progress pill and the
  /// mid-stage encouragement banner.
  double get progress => switch (stage.goal) {
    ScoreGoal(target: final target) => (game.score / target).clamp(0.0, 1.0),
    GemsGoal(counts: final counts) => () {
      final needed = counts.values.fold(0, (a, b) => a + b);
      var collected = 0;
      counts.forEach((color, n) {
        final have = game.gemsCollected[color] ?? 0;
        collected += have > n ? n : have;
      });
      return needed == 0 ? 1.0 : collected / needed;
    }(),
  };

  QuestRun copyWith({GameState? game, QuestStatus? status}) => QuestRun(
    pack: pack,
    stage: stage,
    levelNumber: levelNumber,
    game: game ?? this.game,
    status: status ?? this.status,
  );
}

bool goalMet(QuestGoal goal, GameState game) => switch (goal) {
  ScoreGoal(target: final target) => game.score >= target,
  GemsGoal(counts: final counts) => counts.entries.every(
    (e) => (game.gemsCollected[e.key] ?? 0) >= e.value,
  ),
};

class QuestGameController extends Notifier<QuestRun?> {
  @override
  QuestRun? build() => null;

  void start(QuestPack pack, QuestStage stage, {required int levelNumber}) {
    final seed = stage.seed ?? DateTime.now().microsecondsSinceEpoch;
    state = QuestRun(
      pack: pack,
      stage: stage,
      levelNumber: levelNumber,
      game: GameEngine.newGame(
        seed,
        board: stage.board,
        initialTray: stage.tray,
      ),
      status: QuestStatus.playing,
    );
  }

  void retry() {
    final run = state;
    if (run != null) {
      start(run.pack, run.stage, levelNumber: run.levelNumber);
    }
  }

  /// Win beats lose when the goal lands on the final possible move.
  PlacementOutcome? place(int trayIndex, int row, int col) {
    final run = state;
    if (run == null || run.status != QuestStatus.playing) return null;
    final outcome = GameEngine.place(run.game, trayIndex, row, col);
    if (outcome == null) return null;

    var status = QuestStatus.playing;
    if (goalMet(run.stage.goal, outcome.state)) {
      status = QuestStatus.won;
      ref
          .read(saveDataProvider.notifier)
          .markStageCompleted(run.pack.id, run.stage.id);
    } else if (GameEngine.isGameOver(outcome.state)) {
      status = QuestStatus.lost;
    }
    state = run.copyWith(game: outcome.state, status: status);
    return outcome;
  }

  void quit() => state = null;

  /// Injects an arbitrary run state to set up deterministic tests.
  @visibleForTesting
  void debugLoadRun(QuestRun run) => state = run;
}

final questGameProvider = NotifierProvider<QuestGameController, QuestRun?>(
  QuestGameController.new,
);
