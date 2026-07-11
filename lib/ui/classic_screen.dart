import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../game/block_puzzle_game.dart';
import '../models/game_state.dart';
import '../state/classic_game_controller.dart';
import '../state/providers.dart';

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
      onPlace: (trayIndex, row, col) {
        final outcome = controller.place(trayIndex, row, col);
        if (outcome != null && ref.read(saveDataProvider).settings.hapticsOn) {
          outcome.events.linesCleared > 0
              ? HapticFeedback.mediumImpact()
              : HapticFeedback.lightImpact();
        }
        return outcome;
      },
    );
  }

  void _onStateChanged(GameState? next) {
    if (next == null) return;
    _game.syncState(next);
    if (!_gameOverShown && ref.read(classicGameProvider.notifier).isGameOver) {
      _gameOverShown = true;
      _showGameOver(next);
    }
  }

  Future<void> _showGameOver(GameState finished) async {
    // Placeholder until the Combo Master summary flow (M2 final slice).
    final restart = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Game over'),
        content: Text(
          'Score ${finished.score}\n'
          'Best combo this round: ${finished.roundBestCombo}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Menu'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Play again'),
          ),
        ],
      ),
    );
    if (!mounted) return;
    final controller = ref.read(classicGameProvider.notifier);
    controller.clearFinishedRun();
    if (restart == true) {
      _gameOverShown = false;
      controller.startNew();
    } else {
      Navigator.pop(context);
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
                      // Settings sheet lands with the polish slice.
                      onPressed: null,
                      icon: const Icon(Icons.settings),
                      color: Colors.white38,
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
