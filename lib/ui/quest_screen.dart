import 'dart:async';

import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../game/block_puzzle_game.dart';
import '../models/cell.dart';
import '../models/game_theme.dart' as gt;
import '../models/quest.dart';
import '../state/providers.dart';
import '../state/quest_game_controller.dart';
import '../systems/game_engine.dart';
import 'quest_result_screen.dart';
import 'settings_sheet.dart';

/// One quest stage: goal HUD (score pill or gem counters), the play area,
/// the 80% encouragement banner, and navigation to win/lose screens.
/// Expects the controller's run to be started before this screen mounts.
class QuestScreen extends ConsumerStatefulWidget {
  const QuestScreen({super.key});

  @override
  ConsumerState<QuestScreen> createState() => _QuestScreenState();
}

class _QuestScreenState extends ConsumerState<QuestScreen> {
  late final BlockPuzzleGame _game;
  bool _resultShown = false;

  /// Encouragement banners at rising goal-progress milestones.
  static const _bannerThresholds = [0.3, 0.5, 0.8];
  final _shownBanners = <double>{};
  String? _bannerText;
  bool _bannerVisible = false;

  @override
  void initState() {
    super.initState();
    final controller = ref.read(questGameProvider.notifier);
    _game = BlockPuzzleGame(
      theme: ref.read(themeProvider),
      initialState: ref.read(questGameProvider)!.game,
      onPickup: () {
        if (ref.read(saveDataProvider).settings.hapticsOn) {
          HapticFeedback.selectionClick();
        }
      },
      onPlace: (trayIndex, row, col) {
        final outcome = controller.place(trayIndex, row, col);
        if (outcome != null) {
          ref.read(audioProvider).placement(outcome.events);
          _placementHaptic(outcome.events);
        }
        return outcome;
      },
    );
  }

  void _placementHaptic(PlacementEvents events) {
    if (!ref.read(saveDataProvider).settings.hapticsOn) return;
    if (events.allClear) {
      HapticFeedback.vibrate();
    } else if (events.linesCleared > 0) {
      HapticFeedback.heavyImpact();
    } else {
      HapticFeedback.mediumImpact();
    }
  }

  void _onRunChanged(QuestRun? run) {
    if (run == null) return;
    _game.syncState(run.game);

    if (run.status == QuestStatus.playing) {
      // Show only the highest newly crossed milestone (a big jump
      // shouldn't queue three banners).
      final crossed = _bannerThresholds
          .where((t) => run.progress >= t && !_shownBanners.contains(t))
          .toList();
      if (crossed.isNotEmpty) {
        _shownBanners.addAll(crossed);
        setState(() {
          _bannerText = '${(crossed.last * 100).round()}% Done!';
          _bannerVisible = true;
        });
        Timer(const Duration(milliseconds: 1800), () {
          if (mounted) setState(() => _bannerVisible = false);
        });
      }
    }

    if (run.status != QuestStatus.playing && !_resultShown) {
      _resultShown = true;
      run.status == QuestStatus.won
          ? ref.read(audioProvider).stageWon()
          : ref.read(audioProvider).runEnded();
      // Let the final clear's effects play out first.
      Future.delayed(const Duration(milliseconds: 900), () {
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const QuestResultScreen()),
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(questGameProvider, (_, next) => _onRunChanged(next));
    final theme = ref.watch(themeProvider);
    final run = ref.watch(questGameProvider);
    if (run == null) return const SizedBox.shrink();

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
          child: Stack(
            children: [
              Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Row(
                      children: [
                        IconButton(
                          onPressed: () {
                            ref.read(questGameProvider.notifier).quit();
                            Navigator.pop(context);
                          },
                          icon: const Icon(Icons.arrow_back_ios_new_rounded),
                          color: Colors.white70,
                        ),
                        Expanded(
                          child: Text(
                            'Level ${run.levelNumber}',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () => showSettingsSheet(context),
                          icon: const Icon(Icons.settings),
                          color: Colors.white70,
                        ),
                      ],
                    ),
                  ),
                  _GoalHud(run: run),
                  Expanded(child: GameWidget(game: _game)),
                ],
              ),
              // "80% Done" encouragement ribbon.
              Positioned(
                top: 140,
                left: 0,
                right: 0,
                child: IgnorePointer(
                  child: AnimatedOpacity(
                    opacity: _bannerVisible ? 1 : 0,
                    duration: const Duration(milliseconds: 300),
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 28,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE05B3A),
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: const [
                            BoxShadow(color: Colors.black38, blurRadius: 10),
                          ],
                        ),
                        child: Text(
                          _bannerText ?? '',
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFFFFD54F),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Score goal → progress pill (current score sliding toward the target).
/// Gems goal → one counter per color, ✓ when done.
class _GoalHud extends StatelessWidget {
  const _GoalHud({required this.run});

  final QuestRun run;

  @override
  Widget build(BuildContext context) {
    switch (run.stage.goal) {
      case ScoreGoal(target: final target):
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 6),
          child: Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(9),
                  child: LinearProgressIndicator(
                    value: run.progress,
                    minHeight: 18,
                    backgroundColor: const Color(0xFF1C2645),
                    valueColor: const AlwaysStoppedAnimation(Color(0xFF56CCF2)),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                '${run.game.score} / $target',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFFF2C94C),
                ),
              ),
            ],
          ),
        );
      case GemsGoal(counts: final counts):
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (final entry in counts.entries) ...[
                _GemCounter(
                  color: entry.key,
                  remaining:
                      entry.value - (run.game.gemsCollected[entry.key] ?? 0),
                ),
                const SizedBox(width: 24),
              ],
            ],
          ),
        );
    }
  }
}

class _GemCounter extends StatelessWidget {
  const _GemCounter({required this.color, required this.remaining});

  final GemColor color;
  final int remaining;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(Icons.star_rounded, size: 34, color: gt.gemColors[color]),
        remaining <= 0
            ? const Icon(Icons.check_circle, size: 20, color: Color(0xFF6FCF97))
            : Text(
                '$remaining',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
      ],
    );
  }
}
