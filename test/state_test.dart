import 'package:block_puzzle/models/board.dart';
import 'package:block_puzzle/models/cell.dart';
import 'package:block_puzzle/models/game_state.dart';
import 'package:block_puzzle/state/classic_game_controller.dart';
import 'package:block_puzzle/state/providers.dart';
import 'package:block_puzzle/systems/game_engine.dart';
import 'package:block_puzzle/state/save_data_notifier.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<ProviderContainer> makeContainer({
  Map<String, Object> initialPrefs = const {},
}) async {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues(initialPrefs);
  final prefs = await SharedPreferences.getInstance();
  final container = ProviderContainer(
    overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  test('fresh install loads defaults', () async {
    final container = await makeContainer();
    final save = container.read(saveDataProvider);
    expect(save.classicHighScore, 0);
    expect(save.classicRun, isNull);
    expect(container.read(themeProvider).id, 'default');
  });

  test('settings changes persist across a reload', () async {
    final container = await makeContainer();
    container
        .read(saveDataProvider.notifier)
        .updateSettings(const Settings(soundOn: false, hapticsOn: false));

    final prefs = container.read(sharedPreferencesProvider);
    final reloaded = await makeContainer(
      initialPrefs: {'save': prefs.getString('save')!},
    );
    expect(reloaded.read(saveDataProvider).settings.soundOn, isFalse);
    expect(reloaded.read(saveDataProvider).settings.hapticsOn, isFalse);
  });

  test('unreadable save is quarantined, not overwritten', () async {
    final container = await makeContainer(
      initialPrefs: {'save': '{"version": 999, "future": true}'},
    );
    expect(container.read(saveDataProvider).classicHighScore, 0);
    final prefs = container.read(sharedPreferencesProvider);
    expect(prefs.getString('save_unreadable'), contains('999'));
  });

  test('classic run: start, place, persist, resume', () async {
    final container = await makeContainer();
    final controller = container.read(classicGameProvider.notifier);
    controller.startNew(seed: 42);
    final started = container.read(classicGameProvider)!;

    // Place the first tray piece at the first legal spot.
    final slot = started.tray.indexWhere((id) => id != null);
    PlacementOutcome? outcome;
    for (var row = 0; row < 8 && outcome == null; row++) {
      for (var col = 0; col < 8 && outcome == null; col++) {
        outcome = controller.place(slot, row, col);
      }
    }
    expect(outcome, isNotNull);
    final placed = container.read(classicGameProvider)!;
    expect(placed.score, greaterThan(0));

    // Simulate app kill: a new container over the same prefs resumes.
    final prefs = container.read(sharedPreferencesProvider);
    final revived = await makeContainer(
      initialPrefs: {'save': prefs.getString('save')!},
    );
    final resumed = revived.read(classicGameProvider);
    expect(resumed, isNotNull);
    expect(resumed!.score, placed.score);
    expect(resumed.rngState, placed.rngState);
    expect(resumed.tray, placed.tray);
  });

  test('game over folds score and combo into all-time bests', () async {
    final container = await makeContainer();
    final controller = container.read(classicGameProvider.notifier);
    controller.startNew(seed: 7);

    // Diagonal holes keep every row/column non-full (a legal mid-game
    // board), plus (0,4)/(4,0) so filling (0,0) still completes no line.
    // The remaining big pieces then have no legal move: run over.
    const holes = {0, 9, 18, 27, 36, 45, 54, 63, 4, 32};
    controller.debugLoadRun(
      GameState(
        board: Board.fromCells([
          for (var i = 0; i < 64; i++) holes.contains(i) ? null : const Cell(1),
        ]),
        tray: const ['single', 'square3', 'line5h'],
        rngState: 1,
        score: 500,
        combo: 2,
        roundBestCombo: 9,
      ),
      seed: 7,
    );
    final outcome = controller.place(0, 0, 0);
    expect(outcome, isNotNull);
    expect(controller.isGameOver, isTrue);

    final save = container.read(saveDataProvider);
    expect(save.classicHighScore, 501); // 500 + 1 cell
    expect(save.allTimeBestCombo, 9);
    expect(save.classicRun, isNull, reason: 'finished run is not resumable');

    // Summary screens can still read the finished run until dismissed.
    expect(container.read(classicGameProvider)!.score, 501);
    controller.clearFinishedRun();
    expect(container.read(classicGameProvider), isNull);
  });
}
