import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../state/classic_game_controller.dart';
import '../state/providers.dart';

/// Post-run summary. The headline scales to the run (best first match):
/// new high score → combo master (combo > 15) → all-clear ace (> 5
/// all-clears) → plain "Try Again". Same stats + retry flow either way.
class RunSummaryScreen extends ConsumerWidget {
  const RunSummaryScreen({super.key, required this.summary});

  final RunSummary summary;

  static const comboMasterMin = 16; // "more than 15 combos"
  static const allClearAceMin = 6; // "more than 5 all-clears"

  ({String title, IconData icon, List<Color> bg}) get _variant {
    if (summary.newHighScore) {
      return (
        title: 'New High Score!',
        icon: Icons.emoji_events,
        bg: const [Color(0xFFB98A44), Color(0xFF8A6432)],
      );
    }
    if (summary.bestCombo >= comboMasterMin) {
      return (
        title: 'Combo Master',
        icon: Icons.bolt_rounded,
        bg: const [Color(0xFF7B4397), Color(0xFF4527A0)],
      );
    }
    if (summary.allClears >= allClearAceMin) {
      return (
        title: 'All-Clear Ace!',
        icon: Icons.auto_awesome,
        bg: const [Color(0xFF2D7DD2), Color(0xFF1B4E9B)],
      );
    }
    return (
      title: 'Try Again',
      icon: Icons.replay_rounded,
      bg: const [Color(0xFF3B4E8C), Color(0xFF232F56)],
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final save = ref.watch(saveDataProvider);
    final variant = _variant;
    return Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: variant.bg,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  onPressed: () => _leave(context, ref, restart: false),
                  icon: const Icon(Icons.arrow_back_ios_new_rounded),
                  color: Colors.white70,
                ),
              ),
              const Spacer(),
              Icon(variant.icon, size: 72, color: const Color(0xFFFFE082)),
              const SizedBox(height: 8),
              Text(
                variant.title,
                style: const TextStyle(
                  fontSize: 42,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFFFFE082),
                  shadows: [Shadow(color: Colors.black26, blurRadius: 8)],
                ),
              ),
              const Spacer(),
              _Stat(label: 'Score', value: '${summary.score}'),
              const SizedBox(height: 24),
              _Stat(label: 'Round Best', value: 'Combo ${summary.bestCombo}'),
              const SizedBox(height: 24),
              _Stat(
                label: 'All Time Combo',
                value: 'Combo ${save.allTimeBestCombo}',
              ),
              if (summary.allClears > 0) ...[
                const SizedBox(height: 24),
                _Stat(label: 'All-Clears', value: '${summary.allClears}'),
              ],
              const Spacer(flex: 2),
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
                  onPressed: () => _leave(context, ref, restart: true),
                  child: const Icon(
                    Icons.play_arrow_rounded,
                    size: 44,
                    color: Colors.white,
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

  void _leave(BuildContext context, WidgetRef ref, {required bool restart}) {
    final controller = ref.read(classicGameProvider.notifier);
    controller.clearFinishedRun();
    if (restart) {
      controller.startNew();
      Navigator.pop(context); // back to the classic screen, fresh run
    } else {
      // Pop the summary AND the classic screen underneath: back to menu.
      Navigator.of(context)
        ..pop()
        ..pop();
    }
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: Color(0xFFE8C98A),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w900,
            color: Colors.white,
            shadows: [Shadow(color: Colors.black26, blurRadius: 6)],
          ),
        ),
      ],
    );
  }
}
