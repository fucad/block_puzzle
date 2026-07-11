import 'package:block_puzzle/models/cell.dart';
import 'package:block_puzzle/models/quest.dart';
import 'package:block_puzzle/state/providers.dart';
import 'package:block_puzzle/state/quest_game_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<ProviderContainer> makeContainer() async {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final container = ProviderContainer(
    overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
  );
  addTearDown(container.dispose);
  return container;
}

QuestPack packWith(QuestStage stage) =>
    QuestPack(id: 'test', title: 'Test', stages: [stage]);

/// Row 7 needs only (7,7); the gem at (7,0) rides along when it clears.
final gemStage = QuestStage.fromJson({
  'id': 'g1',
  'board': [
    '........',
    '........',
    '........',
    '........',
    '........',
    '........',
    '........',
    'r111111.',
  ],
  'goal': {
    'type': 'gems',
    'counts': {'red': 1},
  },
  'seed': 1,
});

// The stray block at (0,0) prevents an all-clear from skewing the score.
final scoreStage = QuestStage.fromJson({
  'id': 's1',
  'board': [
    '1.......',
    '........',
    '........',
    '........',
    '........',
    '........',
    '........',
    '1111111.',
  ],
  'goal': {'type': 'score', 'target': 11},
  'seed': 1,
});

/// Places the first playable tray piece at the first legal spot.
void placeAnywhere(QuestGameController controller, QuestRun run) {
  for (var slot = 0; slot < run.game.tray.length; slot++) {
    if (run.game.tray[slot] == null) continue;
    for (var row = 0; row < 8; row++) {
      for (var col = 0; col < 8; col++) {
        if (controller.place(slot, row, col) != null) return;
      }
    }
  }
  fail('no legal placement found');
}

void main() {
  test('collecting the required gem wins and records completion', () async {
    final container = await makeContainer();
    final controller = container.read(questGameProvider.notifier);
    controller.start(packWith(gemStage), gemStage, levelNumber: 1);

    // Force a known tray so we can complete row 7 deterministically.
    var run = container.read(questGameProvider)!;
    expect(run.status, QuestStatus.playing);
    controller.debugLoadRun(
      run.copyWith(
        game: run.game.copyWith(tray: ['single', 'single', 'single']),
      ),
    );
    final outcome = controller.place(0, 7, 7)!;
    expect(outcome.events.gems, {GemColor.red: 1});

    run = container.read(questGameProvider)!;
    expect(run.status, QuestStatus.won);
    expect(run.progress, 1.0);
    expect(
      container.read(saveDataProvider).questCompleted['test'],
      contains('g1'),
    );
  });

  test('score goal wins; progress tracks the ratio', () async {
    final container = await makeContainer();
    final controller = container.read(questGameProvider.notifier);
    controller.start(packWith(scoreStage), scoreStage, levelNumber: 2);
    var run = container.read(questGameProvider)!;
    controller.debugLoadRun(
      run.copyWith(
        game: run.game.copyWith(tray: ['single', 'single', 'single']),
      ),
    );
    // 1 cell + 10 line = 11 = target.
    controller.place(0, 7, 7);
    run = container.read(questGameProvider)!;
    expect(run.status, QuestStatus.won);
    expect(run.game.score, 11);
  });

  test('locking up before the goal loses; retry restarts the layout', () async {
    final container = await makeContainer();
    final controller = container.read(questGameProvider.notifier);
    controller.start(packWith(scoreStage), scoreStage, levelNumber: 2);
    var run = container.read(questGameProvider)!;

    // Tray of big pieces over an almost-jammed board: one legal placement
    // (square3 at top-left), then nothing fits and the goal is unmet.
    controller.debugLoadRun(
      run.copyWith(
        game: run.game.copyWith(
          board: QuestStage.fromJson({
            'id': 'jam',
            'board': [
              '...1.1.1',
              '...1.1.1',
              '....1.1.',
              '1111.1.1',
              '.1.1.1.1',
              '1.1.1.1.',
              '.1.1.1.1',
              '1.1.1.1.',
            ],
            'goal': {'type': 'score', 'target': 100},
          }).board,
          tray: ['square3', 'square3', 'square3'],
        ),
      ),
    );
    controller.place(0, 0, 0);
    run = container.read(questGameProvider)!;
    expect(run.status, QuestStatus.lost);
    expect(run.game.score, lessThan(100));

    controller.retry();
    run = container.read(questGameProvider)!;
    expect(run.status, QuestStatus.playing);
    expect(run.game.score, 0);
    // Retry restores the stage's original pre-placed layout.
    expect(run.game.board.at(7, 0), isNotNull);
    expect(run.game.board.at(7, 7), isNull);
  });

  test('quit clears the run', () async {
    final container = await makeContainer();
    final controller = container.read(questGameProvider.notifier);
    controller.start(packWith(scoreStage), scoreStage, levelNumber: 1);
    controller.quit();
    expect(container.read(questGameProvider), isNull);
  });
}
