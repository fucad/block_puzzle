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

  /// Ends the classic run: folds its score/combo into the all-time bests
  /// and drops the resumable snapshot.
  void recordClassicRunEnd({required int score, required int bestCombo}) {
    _update(
      state.copyWith(
        classicHighScore: score > state.classicHighScore
            ? score
            : state.classicHighScore,
        allTimeBestCombo: bestCombo > state.allTimeBestCombo
            ? bestCombo
            : state.allTimeBestCombo,
        clearClassicRun: true,
      ),
    );
  }

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
