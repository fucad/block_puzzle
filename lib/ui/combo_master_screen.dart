import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../state/classic_game_controller.dart';
import '../state/providers.dart';

/// Post-run summary (reference: gold "Combo Master" screen): final score,
/// round best combo, all-time best combo, play again or back to menu.
class ComboMasterScreen extends ConsumerWidget {
  const ComboMasterScreen({
    super.key,
    required this.score,
    required this.roundBestCombo,
  });

  final int score;
  final int roundBestCombo;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final save = ref.watch(saveDataProvider);
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFB98A44), Color(0xFF8A6432)],
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
              const Icon(
                Icons.emoji_events,
                size: 72,
                color: Color(0xFFFFE082),
              ),
              const SizedBox(height: 8),
              const Text(
                'Combo Master',
                style: TextStyle(
                  fontSize: 44,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFFFFE082),
                  shadows: [Shadow(color: Colors.black26, blurRadius: 8)],
                ),
              ),
              const Spacer(),
              _Stat(label: 'Score', value: '$score'),
              const SizedBox(height: 28),
              _Stat(label: 'Round Best', value: 'Combo $roundBestCombo'),
              const SizedBox(height: 28),
              _Stat(
                label: 'All Time Combo',
                value: 'Combo ${save.allTimeBestCombo}',
              ),
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
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Color(0xFFE8C98A),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 34,
            fontWeight: FontWeight.w900,
            color: Colors.white,
            shadows: [Shadow(color: Colors.black26, blurRadius: 6)],
          ),
        ),
      ],
    );
  }
}
