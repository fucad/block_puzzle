import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../game/block_puzzle_game.dart';
import '../models/game_state.dart';
import '../state/classic_game_controller.dart';
import '../state/providers.dart';
import 'run_summary_screen.dart';
import 'settings_sheet.dart';

/// Classic mode: HUD (high score, current score, settings) over the Flame
/// play area. Rules live in the engine; this screen only wires state to
/// the game and reacts to run-over.
class ClassicScreen extends ConsumerStatefulWidget {
  const ClassicScreen({super.key});

  @override
  ConsumerState<ClassicScreen> createState() => _ClassicScreenState();
}

class _ClassicScreenState extends ConsumerState<ClassicScreen> {
  late final BlockPuzzleGame _game;
  bool _gameOverShown = false;

  @override
  void initState() {
    super.initState();
    // The menu (or the retry flow) guarantees a run before this screen
    // mounts; mutating providers here, mid-build, is not allowed.
    final controller = ref.read(classicGameProvider.notifier);
    _game = BlockPuzzleGame(
      theme: ref.read(themeProvider),
      initialState: ref.read(classicGameProvider)!,
      onPickup: () => ref.read(hapticProvider).pickup(),
      onPlace: (trayIndex, row, col) {
        final outcome = controller.place(trayIndex, row, col);
        if (outcome != null) {
          ref.read(audioProvider).placement(outcome.events);
          ref.read(hapticProvider).placement(outcome.events);
        }
        return outcome;
      },
    );
  }

  void _onStateChanged(GameState? next) {
    if (next == null) return;
    _game.syncState(next);
    final controller = ref.read(classicGameProvider.notifier);
    if (controller.isGameOver) {
      if (_gameOverShown) return;
      _gameOverShown = true;
      ref.read(audioProvider).runEnded();
      final summary =
          controller.lastSummary ??
          RunSummary(
            score: next.score,
            bestCombo: next.roundBestCombo,
            allClears: next.allClears,
            newHighScore: false,
          );
      // Let the last clear's effects play before the summary takes over.
      Future.delayed(const Duration(milliseconds: 900), () {
        if (!mounted) return;
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => RunSummaryScreen(summary: summary)),
        );
      });
    } else {
      _gameOverShown = false; // a fresh run arrived (retry flow)
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(classicGameProvider, (_, next) => _onStateChanged(next));
    final theme = ref.watch(themeProvider);
    final save = ref.watch(saveDataProvider);
    final run = ref.watch(classicGameProvider);

    return Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(theme.background.toARGB32()),
              Color(theme.backgroundAccent.toARGB32()),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back_ios_new_rounded),
                      color: Colors.white70,
                    ),
                    const Icon(Icons.emoji_events, color: Color(0xFFF2C94C)),
                    const SizedBox(width: 4),
                    Text(
                      '${save.classicHighScore}',
                      style: const TextStyle(
                        color: Color(0xFFF2C94C),
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => showSettingsSheet(context),
                      icon: const Icon(Icons.settings),
                      color: Colors.white70,
                    ),
                  ],
                ),
              ),
              Text(
                '${run?.score ?? 0}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 56,
                  fontWeight: FontWeight.w900,
                  shadows: [Shadow(color: Colors.black38, blurRadius: 8)],
                ),
              ),
              Expanded(child: GameWidget(game: _game)),
            ],
          ),
        ),
      ),
    );
  }
}
