import 'dart:convert';

import 'package:block_puzzle/models/cell.dart';
import 'package:block_puzzle/models/game_state.dart';
import 'package:block_puzzle/models/save_data.dart';
import 'package:block_puzzle/systems/game_engine.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

/// Round-trips through actual JSON text, like the persistence layer will.
SaveData roundTrip(SaveData data) => SaveData.fromJson(
  (jsonDecode(jsonEncode(data.toJson())) as Map).cast<String, Object?>(),
);

void main() {
  test('defaults survive a JSON round trip', () {
    final restored = roundTrip(const SaveData());
    expect(restored.settings.soundOn, isTrue);
    expect(restored.settings.hapticsOn, isTrue);
    expect(restored.settings.themeId, 'default');
    expect(restored.classicHighScore, 0);
    expect(restored.classicRun, isNull);
    expect(restored.questCompleted, isEmpty);
  });

  test('a real in-progress run survives a JSON round trip exactly', () {
    // Build a state with a played tray slot and a nontrivial board.
    var state = GameEngine.newGame(987654321);
    final slot = state.tray.indexWhere((id) => id != null);
    outer:
    for (var row = 0; row < 8; row++) {
      for (var col = 0; col < 8; col++) {
        final outcome = GameEngine.place(state, slot, row, col);
        if (outcome != null) {
          state = outcome.state;
          break outer;
        }
      }
    }

    final data = SaveData(
      settings: const Settings(soundOn: false, themeId: 'wood'),
      classicHighScore: 227906,
      allTimeBestCombo: 33,
      classicRun: state,
      classicRunSeed: 987654321,
      questCompleted: {
        'starter': {'s01', 's02'},
      },
      lastQuestFetchEpochMs: 1752200000000,
    );
    final restored = roundTrip(data);

    expect(restored.settings.soundOn, isFalse);
    expect(restored.settings.themeId, 'wood');
    expect(restored.classicHighScore, 227906);
    expect(restored.allTimeBestCombo, 33);
    expect(restored.classicRunSeed, 987654321);
    expect(restored.questCompleted, {
      'starter': {'s01', 's02'},
    });
    expect(restored.lastQuestFetchEpochMs, 1752200000000);

    final run = restored.classicRun!;
    expect(run.tray, state.tray);
    expect(run.rngState, state.rngState);
    expect(run.score, state.score);
    expect(run.combo, state.combo);
    expect(run.roundBestCombo, state.roundBestCombo);
    expect(render(run.board), render(state.board));
  });

  test('rngState round-trips as a string even for extreme values', () {
    final state = GameEngine.newGame(1).copyWith(rngState: -8423581294942912);
    final json = jsonDecode(jsonEncode(state.toJson())) as Map;
    expect(json['rngState'], isA<String>());
    final restored = GameState.fromJson(json.cast<String, Object?>());
    expect(restored.rngState, -8423581294942912);
  });

  test('tray gems and gem goal round-trip through JSON', () {
    final state = GameEngine.newGame(1).copyWith(
      tray: ['single', 'line2h', null],
      trayGems: [
        {0: GemColor.red},
        {1: GemColor.blue},
        const {},
      ],
      gemGoal: {GemColor.red: 5, GemColor.blue: 3},
    );
    final restored = GameState.fromJson(
      (jsonDecode(jsonEncode(state.toJson())) as Map).cast<String, Object?>(),
    );
    expect(restored.trayGems, [
      {0: GemColor.red},
      {1: GemColor.blue},
      const <int, GemColor>{},
    ]);
    expect(restored.gemGoal, {GemColor.red: 5, GemColor.blue: 3});
  });

  test('an in-progress quest run survives a JSON round trip', () {
    final questRun = GameEngine.newGame(
      42,
      gemGoal: {GemColor.red: 5, GemColor.blue: 5, GemColor.green: 5},
    ).copyWith(score: 120, gemsCollected: {GemColor.red: 2});

    final data = SaveData(
      questRun: questRun,
      questRunPackId: 'starter',
      questRunStageId: 's07',
      questRunLevelNumber: 7,
    );
    final restored = roundTrip(data);

    expect(restored.questRunPackId, 'starter');
    expect(restored.questRunStageId, 's07');
    expect(restored.questRunLevelNumber, 7);
    expect(restored.questRun, isNotNull);
    expect(restored.questRun!.score, 120);
    expect(restored.questRun!.gemGoal, {
      GemColor.red: 5,
      GemColor.blue: 5,
      GemColor.green: 5,
    });
    expect(restored.questRun!.gemsCollected, {GemColor.red: 2});
  });

  test('clearing the quest run drops all of its fields', () {
    final data = SaveData(
      questRun: GameEngine.newGame(1),
      questRunPackId: 'starter',
      questRunStageId: 's01',
      questRunLevelNumber: 1,
    );
    final cleared = data.copyWith(clearQuestRun: true);
    expect(cleared.questRun, isNull);
    expect(cleared.questRunPackId, isNull);
    expect(cleared.questRunStageId, isNull);
    expect(cleared.questRunLevelNumber, isNull);
    // And a run-free save omits the keys entirely.
    expect(roundTrip(cleared).questRun, isNull);
  });

  test('unknown save version throws instead of silently loading', () {
    expect(
      () => SaveData.fromJson(const {'version': 999}),
      throwsFormatException,
    );
    expect(() => SaveData.fromJson(const {}), throwsFormatException);
  });
}
