import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../state/classic_game_controller.dart';
import '../state/providers.dart';

/// Post-run summary: big animated score, variant title, stat chips, retry.
class RunSummaryScreen extends ConsumerStatefulWidget {
  const RunSummaryScreen({super.key, required this.summary});

  final RunSummary summary;

  @override
  ConsumerState<RunSummaryScreen> createState() => _RunSummaryScreenState();
}

class _RunSummaryScreenState extends ConsumerState<RunSummaryScreen>
    with SingleTickerProviderStateMixin {
  static const _comboMasterMin = 16;
  static const _allClearAceMin = 6;

  // Single controller: icon/title animate from 0–60%, score from 20–90%.
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..forward();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  ({String title, IconData icon, List<Color> bg}) get _variant {
    final s = widget.summary;
    if (s.newHighScore) {
      return (
        title: 'New Best!',
        icon: Icons.emoji_events_rounded,
        bg: const [Color(0xFF3A2A00), Color(0xFF1E1500)],
      );
    }
    if (s.bestCombo >= _comboMasterMin) {
      return (
        title: 'Combo King!',
        icon: Icons.bolt_rounded,
        bg: const [Color(0xFF2A0050), Color(0xFF150028)],
      );
    }
    if (s.allClears >= _allClearAceMin) {
      return (
        title: 'Flawless!',
        icon: Icons.auto_awesome_rounded,
        bg: const [Color(0xFF002A40), Color(0xFF001520)],
      );
    }
    return (
      title: 'Well Done!',
      icon: Icons.thumb_up_rounded,
      bg: const [Color(0xFF1A2540), Color(0xFF0D1526)],
    );
  }

  @override
  Widget build(BuildContext context) {
    final save = ref.watch(saveDataProvider);
    final variant = _variant;
    final s = widget.summary;

    final iconBounce = CurvedAnimation(
      parent: _c,
      curve: const Interval(0.0, 0.65, curve: Curves.elasticOut),
    );
    final fade = CurvedAnimation(
      parent: _c,
      curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
    );
    final scoreBounce = CurvedAnimation(
      parent: _c,
      curve: const Interval(0.18, 0.85, curve: Curves.elasticOut),
    );

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
                  onPressed: () => _leave(context, restart: false),
                  icon: const Icon(Icons.arrow_back_ios_new_rounded),
                  color: Colors.white70,
                ),
              ),
              const Spacer(),

              // Icon + title
              ScaleTransition(
                scale: iconBounce,
                child: Icon(
                  variant.icon,
                  size: 68,
                  color: const Color(0xFFFFE082),
                ),
              ),
              const SizedBox(height: 10),
              FadeTransition(
                opacity: fade,
                child: Text(
                  variant.title,
                  style: const TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFFFFE082),
                  ),
                ),
              ),

              const Spacer(),

              // Big score card
              FadeTransition(
                opacity: fade,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 20,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0x1AFFFFFF),
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                        color: s.newHighScore
                            ? const Color(0x99F2C94C)
                            : const Color(0x22FFFFFF),
                        width: s.newHighScore ? 2 : 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        ScaleTransition(
                          scale: scoreBounce,
                          child: Text(
                            '${s.score}',
                            style: const TextStyle(
                              fontSize: 72,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              height: 1,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          s.newHighScore
                              ? 'New Personal Best!'
                              : 'Score',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: s.newHighScore
                                ? const Color(0xFFF2C94C)
                                : Colors.white38,
                            letterSpacing: 1,
                          ),
                        ),
                        if (s.newHighScore) ...[
                          const SizedBox(height: 4),
                          Text(
                            'Previous: ${save.classicHighScore > s.score ? save.classicHighScore : 'N/A'}',
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.white38,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Stat chips
              FadeTransition(
                opacity: fade,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _StatChip(
                      label: 'Best Combo',
                      value: '×${s.bestCombo}',
                      color: const Color(0xFFFF6B35),
                    ),
                    if (s.allClears > 0) ...[
                      const SizedBox(width: 12),
                      _StatChip(
                        label: 'All-Clears',
                        value: '${s.allClears}',
                        color: const Color(0xFF56CCF2),
                      ),
                    ],
                  ],
                ),
              ),

              const Spacer(flex: 2),

              // Retry button
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
                  onPressed: () => _leave(context, restart: true),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(
                          Icons.play_arrow_rounded,
                          size: 36,
                          color: Colors.white,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Play Again',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ],
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

  void _leave(BuildContext context, {required bool restart}) {
    final controller = ref.read(classicGameProvider.notifier);
    controller.clearFinishedRun();
    if (restart) {
      controller.startNew();
      Navigator.pop(context);
    } else {
      Navigator.of(context)
        ..pop()
        ..pop();
    }
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.label,
    required this.value,
    required this.color,
  });
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.4), width: 1),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: color,
              height: 1,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: Colors.white54),
          ),
        ],
      ),
    );
  }
}
