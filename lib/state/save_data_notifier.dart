import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/game_state.dart';
import '../models/save_data.dart';
import 'providers.dart';

export '../models/save_data.dart';

/// Owns the persisted SaveData: every mutation goes through here and is
/// written to disk immediately (writes are fire-and-forget; the in-memory
/// state is the source of truth for the session).
class SaveDataNotifier extends Notifier<SaveData> {
  @override
  SaveData build() => ref.watch(persistenceProvider).load();

  void _update(SaveData next) {
    state = next;
    ref.read(persistenceProvider).save(next);
  }

  void updateSettings(Settings settings) =>
      _update(state.copyWith(settings: settings));

  /// Persists the in-progress classic run so an app kill can resume it.
  void storeClassicRun(GameState run, int seed) =>
      _update(state.copyWith(classicRun: run, classicRunSeed: seed));

  /// Ends the classic run: folds its score/combo/allClears into the all-time
  /// bests and drops the resumable snapshot.
  void recordClassicRunEnd({
    required int score,
    required int bestCombo,
    required int allClears,
  }) {
    _update(
      state.copyWith(
        classicHighScore: score > state.classicHighScore
            ? score
            : state.classicHighScore,
        allTimeBestCombo: bestCombo > state.allTimeBestCombo
            ? bestCombo
            : state.allTimeBestCombo,
        bestAllClearsInRun: allClears > state.bestAllClearsInRun
            ? allClears
            : state.bestAllClearsInRun,
        clearClassicRun: true,
      ),
    );
  }

  /// Called on every placement (any mode) to accumulate lifetime stats.
  void recordPlacement({
    required int cellsPlaced,
    required bool comboIncreased,
  }) {
    _update(
      state.copyWith(
        totalBlocksPlaced: state.totalBlocksPlaced + cellsPlaced,
        totalCombos: comboIncreased ? state.totalCombos + 1 : null,
      ),
    );
  }

  /// Called at the end of a quest stage win to fold in all-clears.
  void recordQuestWin({required int allClears}) {
    if (allClears > state.bestAllClearsInRun) {
      _update(state.copyWith(bestAllClearsInRun: allClears));
    }
  }

  /// Persists the in-progress quest attempt so leaving the stage (or an
  /// app kill) resumes it exactly where it was.
  void storeQuestRun(
    GameState run, {
    required String packId,
    required String stageId,
    required int levelNumber,
  }) => _update(
    state.copyWith(
      questRun: run,
      questRunPackId: packId,
      questRunStageId: stageId,
      questRunLevelNumber: levelNumber,
    ),
  );

  /// Drops the resumable quest snapshot (stage won, lost, or abandoned via
  /// retry from scratch).
  void clearQuestRun() => _update(state.copyWith(clearQuestRun: true));

  /// Stamps the quest-fetch throttle (see questCatalogProvider).
  void markQuestFetch(int epochMs) =>
      _update(state.copyWith(lastQuestFetchEpochMs: epochMs));

  void markStageCompleted(String packId, String stageId) {
    final completed = {
      for (final entry in state.questCompleted.entries)
        entry.key: {...entry.value},
    };
    (completed[packId] ??= {}).add(stageId);
    _update(state.copyWith(questCompleted: completed));
  }

  /// Settings → "reset progress". Irreversible; caller confirms with the
  /// player first.
  void resetAllProgress() => _update(SaveData(settings: state.settings));
}
