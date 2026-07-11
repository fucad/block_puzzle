import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/quest.dart';
import '../state/quest_game_controller.dart';
import 'quest_screen.dart';

/// Stage outcome. Win: "Level Complete!" + back to the map. Lose: the
/// reference "So Close!" screen — progress toward the goal, Retry, back.
/// Replaces the QuestScreen route; Retry pushes a fresh one.
class QuestResultScreen extends ConsumerWidget {
  const QuestResultScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final run = ref.watch(questGameProvider);
    if (run == null) return const SizedBox.shrink();
    final won = run.status == QuestStatus.won;

    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF2D7DD2), Color(0xFF1B4E9B)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  onPressed: () => _backToMap(context, ref),
                  icon: const Icon(Icons.arrow_back_ios_new_rounded),
                  color: Colors.white70,
                ),
              ),
              const Spacer(),
              Text(
                won ? 'Level Complete!' : 'So Close!',
                style: const TextStyle(
                  fontSize: 44,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF9BDCFF),
                  shadows: [Shadow(color: Colors.black26, blurRadius: 8)],
                ),
              ),
              const Spacer(),
              if (won)
                const Icon(
                  Icons.emoji_events,
                  size: 96,
                  color: Color(0xFFFFD54F),
                )
              else
                _ProgressRecap(run: run),
              const Spacer(flex: 2),
              if (!won)
                SizedBox(
                  width: 240,
                  height: 60,
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF43A047),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: () {
                      ref.read(questGameProvider.notifier).retry();
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => const QuestScreen()),
                      );
                    },
                    icon: const Icon(Icons.refresh_rounded, size: 30),
                    label: const Text(
                      'Retry',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                )
              else
                SizedBox(
                  width: 240,
                  height: 60,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFF2A93B),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: () => _backToMap(context, ref),
                    child: const Text(
                      'Continue',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }

  void _backToMap(BuildContext context, WidgetRef ref) {
    ref.read(questGameProvider.notifier).quit();
    Navigator.pop(context);
  }
}

/// "Score: how far you got" for score goals; gem tally otherwise.
class _ProgressRecap extends StatelessWidget {
  const _ProgressRecap({required this.run});

  final QuestRun run;

  @override
  Widget build(BuildContext context) {
    final goal = run.stage.goal;
    return Column(
      children: [
        const Text(
          'Score',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Color(0xFF9BDCFF),
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 60),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: LinearProgressIndicator(
              value: run.progress,
              minHeight: 24,
              backgroundColor: const Color(0xFF123A75),
              valueColor: const AlwaysStoppedAnimation(Color(0xFF6EC1F5)),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          switch (goal) {
            ScoreGoal(target: final t) => '${run.game.score} / $t',
            GemsGoal() => '${(run.progress * 100).round()}% of gems',
          },
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
      ],
    );
  }
}
