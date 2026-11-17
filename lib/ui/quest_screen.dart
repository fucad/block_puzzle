import 'dart:async';

import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../game/block_puzzle_game.dart';
import '../models/cell.dart';
import '../models/game_theme.dart' as gt;
import '../models/quest.dart';
import '../state/providers.dart';
import '../state/quest_game_controller.dart';
import 'quest_result_screen.dart';
import 'settings_sheet.dart';

class QuestScreen extends ConsumerStatefulWidget {
  const QuestScreen({super.key});

  @override
  ConsumerState<QuestScreen> createState() => _QuestScreenState();
}

class _QuestScreenState extends ConsumerState<QuestScreen>
    with SingleTickerProviderStateMixin {
  late final BlockPuzzleGame _game;
  bool _resultShown = false;

  static const _bannerThresholds = [0.3, 0.5, 0.8];
  final _shownBanners = <double>{};
  String? _bannerText;
  bool _bannerVisible = false;

  bool _goalVisible = false;

  // Controller for milestone banner bounce.
  late final AnimationController _bannerAnim = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 400),
  );

  void _showGoalBanner() {
    setState(() => _goalVisible = true);
    // Quicker dismissal: 1.1 s visible, 300 ms fade.
    Timer(const Duration(milliseconds: 1100), () {
      if (mounted) setState(() => _goalVisible = false);
    });
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _showGoalBanner();
    });
    final controller = ref.read(questGameProvider.notifier);
    _game = BlockPuzzleGame(
      theme: ref.read(themeProvider),
      initialState: ref.read(questGameProvider)!.game,
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

  @override
  void dispose() {
    _bannerAnim.dispose();
    super.dispose();
  }

  void _onRunChanged(QuestRun? run) {
    if (run == null) return;
    _game.syncState(run.game);

    if (run.status == QuestStatus.playing) {
      final crossed = _bannerThresholds
          .where((t) => run.progress >= t && !_shownBanners.contains(t))
          .toList();
      if (crossed.isNotEmpty) {
        _shownBanners.addAll(crossed);
        final pct = (crossed.last * 100).round();
        setState(() {
          _bannerText = pct == 80 ? '🔥 $pct% Almost there!' : '⭐ $pct% Done!';
          _bannerVisible = true;
        });
        _bannerAnim.forward(from: 0);
        Timer(const Duration(milliseconds: 1000), () {
          if (mounted) setState(() => _bannerVisible = false);
        });
      }
    }

    if (run.status != QuestStatus.playing && !_resultShown) {
      _resultShown = true;
      if (run.status == QuestStatus.won) {
        ref.read(audioProvider).stageWon();
        ref.read(hapticProvider).stageWon();
      } else {
        ref.read(audioProvider).runEnded();
      }
      final praise = _game.lastPraise;
      Future.delayed(const Duration(milliseconds: 900), () {
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => QuestResultScreen(praise: praise)),
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
                          onPressed: () => showSettingsSheet(
                            context,
                            onRestart: () {
                              _resultShown = false;
                              _shownBanners.clear();
                              ref.read(questGameProvider.notifier).retry();
                              _showGoalBanner();
                            },
                          ),
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

              // Milestone ribbon — bounces in, fades out quickly.
              Positioned(
                top: 140,
                left: 0,
                right: 0,
                child: IgnorePointer(
                  child: AnimatedOpacity(
                    opacity: _bannerVisible ? 1 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: Center(
                      child: AnimatedBuilder(
                        animation: _bannerAnim,
                        builder: (_, child) {
                          final t = Curves.elasticOut.transform(
                            _bannerAnim.value,
                          );
                          return Transform.scale(
                            scale: 0.6 + t * 0.4,
                            child: child,
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 28,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE05B3A),
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: const [
                              BoxShadow(color: Colors.black38, blurRadius: 12),
                            ],
                          ),
                          child: Text(
                            _bannerText ?? '',
                            style: const TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFFFFD54F),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // Stage-start goal popup — quick, punchy, specific.
              Center(
                child: IgnorePointer(
                  child: AnimatedScale(
                    scale: _goalVisible ? 1 : 0.7,
                    duration: const Duration(milliseconds: 280),
                    curve: Curves.easeOutBack,
                    child: AnimatedOpacity(
                      opacity: _goalVisible ? 1 : 0,
                      duration: const Duration(milliseconds: 200),
                      child: _GoalPopup(run: run),
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

/// Compact popup shown at stage start — the specific target, not just the
/// type. Designed to be read in under a second.
class _GoalPopup extends StatelessWidget {
  const _GoalPopup({required this.run});
  final QuestRun run;

  @override
  Widget build(BuildContext context) {
    final (icon, headline, detail) = switch (run.stage.goal) {
      ScoreGoal(target: final t) => ('🎯', 'Score $t', 'points to win'),
      GemsGoal(counts: final c) => ('💎', _gemHeadline(c), 'gems to collect'),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xEE1A2540),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF2C94C), width: 2),
        boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 20)],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(icon, style: const TextStyle(fontSize: 32)),
          const SizedBox(height: 4),
          Text(
            headline,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              height: 1.1,
            ),
          ),
          Text(
            detail,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFFF2C94C),
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }

  static String _gemHeadline(Map<GemColor, int> counts) {
    final total = counts.values.fold(0, (a, b) => a + b);
    if (counts.length == 1) {
      final color = counts.keys.first.name;
      return '${counts.values.first} ${color[0].toUpperCase()}${color.substring(1)}';
    }
    return '$total across ${counts.length} colors';
  }
}

/// Score progress pill + gem counters in the HUD above the board.
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
                const SizedBox(width: 20),
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
    final done = remaining <= 0;
    return Column(
      children: [
        Icon(
          done ? Icons.star_rounded : Icons.star_outline_rounded,
          size: 30,
          color: gt.gemColors[color],
        ),
        done
            ? const Icon(Icons.check_circle, size: 18, color: Color(0xFF6FCF97))
            : Text(
                '$remaining',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
      ],
    );
  }
}
