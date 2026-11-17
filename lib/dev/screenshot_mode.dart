// Store-screenshot mode. Inert unless the app is launched with
// `--dart-define=SHOT=<scene>`; see docs/SCREENSHOTS.md.
//
// Each scene seeds a deterministic save (no randomness, no network) and
// opens straight onto one screen, so screenshots can be captured with
// `xcrun simctl io booted screenshot` without driving touches.
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/game_state.dart';
import '../models/save_data.dart';
import '../systems/game_engine.dart';
import '../state/quest_providers.dart';
import '../state/quest_game_controller.dart';
import '../ui/classic_screen.dart';
import '../ui/main_menu_screen.dart';
import '../ui/personal_screen.dart';
import '../ui/quest_map_screen.dart';
import '../ui/quest_screen.dart';

/// Scene name from `--dart-define=SHOT=...`; empty in every normal build.
const String screenshotScene = String.fromEnvironment('SHOT');

/// Scenes: menu, classic, map, gems, stats.
bool get screenshotModeOn => screenshotScene.isNotEmpty;

/// Classic seed + how far the fixture search plays.
const int _classicSeed = 125;
const int _classicMoves = 80;

/// Plays up to [moves] greedy placements (best immediate score; first
/// found wins ties, so the result is stable) from [seed] and returns the
/// most screenshot-worthy state seen: a fresh 3-piece tray on a busy
/// (24–40 filled cells) board, highest score first.
GameState greedyClassicRun(int seed, int moves) {
  var state = GameEngine.newGame(seed, clearFocus: true);
  GameState? showcase;
  for (var m = 0; m < moves; m++) {
    PlacementOutcome? best;
    for (var slot = 0; slot < state.tray.length; slot++) {
      if (state.tray[slot] == null) continue;
      for (var r = 0; r < 8; r++) {
        for (var c = 0; c < 8; c++) {
          final o = GameEngine.place(state, slot, r, c);
          if (o == null || GameEngine.isGameOver(o.state)) continue;
          if (best == null || o.events.scoreDelta > best.events.scoreDelta) {
            best = o;
          }
        }
      }
    }
    if (best == null) break;
    state = best.state;
    final filled = state.board.cells.where((c) => c != null).length;
    final freshTray = state.tray.every((p) => p != null);
    if (freshTray &&
        filled >= 24 &&
        filled <= 40 &&
        (showcase == null || state.score > showcase.score)) {
      showcase = state;
    }
  }
  return showcase ?? state;
}

const int _questOpeningMoves = 3;

/// Highest-scoring legal (slot, row, col) that doesn't end the game.
(int, int, int)? _bestMove(GameState state) {
  (int, int, int)? best;
  var bestScore = -1;
  for (var slot = 0; slot < state.tray.length; slot++) {
    if (state.tray[slot] == null) continue;
    for (var r = 0; r < 8; r++) {
      for (var c = 0; c < 8; c++) {
        final o = GameEngine.place(state, slot, r, c);
        if (o == null || GameEngine.isGameOver(o.state)) continue;
        if (o.events.scoreDelta > bestScore) {
          bestScore = o.events.scoreDelta;
          best = (slot, r, c);
        }
      }
    }
  }
  return best;
}

/// Writes the scene's save fixture before the ProviderScope reads it.
Future<void> seedScreenshotSave(SharedPreferences prefs) async {
  final run = greedyClassicRun(_classicSeed, _classicMoves);
  final save = SaveData(
    classicHighScore: 4820,
    allTimeBestCombo: 9,
    bestAllClearsInRun: 3,
    totalBlocksPlaced: 3127,
    totalCombos: 412,
    classicRun: run,
    classicRunSeed: _classicSeed,
    questCompleted: {
      'starter': {for (var i = 1; i <= 15; i++) 's${_two(i)}'},
      'deep-dig': {for (var i = 1; i <= 4; i++) 'd${_two(i)}'},
    },
    // Far-future stamp: never fetch while capturing.
    lastQuestFetchEpochMs: DateTime(2100).millisecondsSinceEpoch,
  );
  await prefs.setString('save', jsonEncode(save.toJson()));
}

String _two(int i) => i.toString().padLeft(2, '0');

Widget screenshotHome() => switch (screenshotScene) {
  'classic' => const ClassicScreen(),
  'map' => const QuestMapScreen(),
  'stats' => const PersonalScreen(),
  'gems' => const _QuestStageBoot(packId: 'starter', stageId: 's09'),
  _ => const MainMenuScreen(),
};

/// Starts one quest stage from the bundled catalog, then swaps itself for
/// the stage screen.
class _QuestStageBoot extends ConsumerStatefulWidget {
  const _QuestStageBoot({required this.packId, required this.stageId});

  final String packId;
  final String stageId;

  @override
  ConsumerState<_QuestStageBoot> createState() => _QuestStageBootState();
}

class _QuestStageBootState extends ConsumerState<_QuestStageBoot> {
  @override
  void initState() {
    super.initState();
    Future(() async {
      final catalog = await ref.read(questCatalogProvider.future);
      var level = 0;
      for (final pack in catalog.playable) {
        for (final stage in pack.stages) {
          level++;
          if (pack.id == widget.packId && stage.id == widget.stageId) {
            final controller = ref.read(questGameProvider.notifier)
              ..start(pack, stage, levelNumber: level);
            // Play the designed (gem-free) opening so the tray on screen
            // carries gems and some are already collected.
            for (var m = 0; m < _questOpeningMoves; m++) {
              final move = _bestMove(ref.read(questGameProvider)!.game);
              if (move == null) break;
              controller.place(move.$1, move.$2, move.$3);
            }
            if (!mounted) return;
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const QuestScreen()),
            );
            return;
          }
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) => const ColoredBox(color: Colors.black);
}
