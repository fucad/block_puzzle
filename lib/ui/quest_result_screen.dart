import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/quest.dart';
import '../state/quest_game_controller.dart';
import '../state/quest_providers.dart';
import 'quest_screen.dart';

/// Stage outcome. Win → dramatic fanfare. Lose → progress recap + Retry.
class QuestResultScreen extends ConsumerWidget {
  const QuestResultScreen({super.key, this.praise});

  final String? praise;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final run = ref.watch(questGameProvider);
    if (run == null) return const SizedBox.shrink();
    final won = run.status == QuestStatus.won;

    return Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: won
                ? const [Color(0xFF1A3A1A), Color(0xFF0A1F0A)]
                : const [Color(0xFF2D7DD2), Color(0xFF1B4E9B)],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              if (won) const _ConfettiLayer(),
              Column(
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
                  if (won) ...[
                    _WinContent(praise: praise),
                  ] else ...[
                    const Text(
                      'So Close!',
                      style: TextStyle(
                        fontSize: 44,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF9BDCFF),
                        shadows: [Shadow(color: Colors.black26, blurRadius: 8)],
                      ),
                    ),
                    const SizedBox(height: 24),
                    _ProgressRecap(run: run),
                  ],
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
                            MaterialPageRoute(
                              builder: (_) => const QuestScreen(),
                            ),
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
            ],
          ),
        ),
      ),
    );
  }

  void _backToMap(BuildContext context, WidgetRef ref) {
    final run = ref.read(questGameProvider);
    if (run != null && run.status == QuestStatus.won) {
      ref.read(questJustCompletedProvider.notifier).set(run.levelNumber);
    }
    ref.read(questGameProvider.notifier).quit();
    Navigator.pop(context);
  }
}

// ── Win content ──────────────────────────────────────────────────────────────

class _WinContent extends StatefulWidget {
  const _WinContent({this.praise});
  final String? praise;

  @override
  State<_WinContent> createState() => _WinContentState();
}

class _WinContentState extends State<_WinContent>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..forward();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bounce = CurvedAnimation(parent: _c, curve: Curves.elasticOut);
    final fade = CurvedAnimation(parent: _c, curve: Curves.easeIn);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ScaleTransition(
          scale: bounce,
          child: const Text('🏆', style: TextStyle(fontSize: 80)),
        ),
        const SizedBox(height: 16),
        FadeTransition(
          opacity: fade,
          child: const Text(
            'Level Complete!',
            style: TextStyle(
              fontSize: 44,
              fontWeight: FontWeight.w900,
              color: Color(0xFFFFE082),
              shadows: [Shadow(color: Colors.black38, blurRadius: 12)],
            ),
          ),
        ),
        if (widget.praise != null) ...[
          const SizedBox(height: 14),
          FadeTransition(
            opacity: fade,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0x33FFE082),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                widget.praise!,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFFFFE082),
                ),
              ),
            ),
          ),
        ],
        const SizedBox(height: 24),
        FadeTransition(
          opacity: fade,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Text('⭐', style: TextStyle(fontSize: 36)),
              SizedBox(width: 8),
              Text('⭐', style: TextStyle(fontSize: 44)),
              SizedBox(width: 8),
              Text('⭐', style: TextStyle(fontSize: 36)),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Confetti ─────────────────────────────────────────────────────────────────

class _ConfettiLayer extends StatefulWidget {
  const _ConfettiLayer();

  @override
  State<_ConfettiLayer> createState() => _ConfettiLayerState();
}

class _ConfettiLayerState extends State<_ConfettiLayer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2800),
  )..forward();

  static final _rng = Random(42);
  static final _pieces = List.generate(40, (_) {
    return _Confetto(
      x: _rng.nextDouble(),
      startY: -0.05 - _rng.nextDouble() * 0.2,
      speed: 0.5 + _rng.nextDouble() * 0.5,
      angle: _rng.nextDouble() * pi * 2,
      spin: (_rng.nextDouble() - 0.5) * 6,
      size: 6 + _rng.nextDouble() * 8,
      color: [
        const Color(0xFFF2C94C),
        const Color(0xFFEB5757),
        const Color(0xFF56CCF2),
        const Color(0xFF6FCF97),
        const Color(0xFFBB6BFF),
        const Color(0xFFFF8A00),
      ][_rng.nextInt(6)],
    );
  });

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return AnimatedBuilder(
      animation: _c,
      builder: (_, _) => CustomPaint(
        size: size,
        painter: _ConfettiPainter(pieces: _pieces, t: _c.value),
      ),
    );
  }
}

class _Confetto {
  const _Confetto({
    required this.x,
    required this.startY,
    required this.speed,
    required this.angle,
    required this.spin,
    required this.size,
    required this.color,
  });
  final double x, startY, speed, angle, spin, size;
  final Color color;
}

class _ConfettiPainter extends CustomPainter {
  const _ConfettiPainter({required this.pieces, required this.t});
  final List<_Confetto> pieces;
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in pieces) {
      final y = p.startY + t * p.speed * 1.3;
      if (y > 1.1) continue;
      final px = p.x * size.width + sin(t * 3 + p.angle) * 18;
      final py = y * size.height;
      canvas.save();
      canvas.translate(px, py);
      canvas.rotate(t * p.spin);
      canvas.drawRect(
        Rect.fromCenter(
          center: Offset.zero,
          width: p.size,
          height: p.size * 0.55,
        ),
        Paint()..color = p.color.withValues(alpha: (1 - t * 0.6).clamp(0, 1)),
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) => old.t != t;
}

// ── Lose: progress recap ─────────────────────────────────────────────────────

class _ProgressRecap extends StatelessWidget {
  const _ProgressRecap({required this.run});
  final QuestRun run;

  @override
  Widget build(BuildContext context) {
    final goal = run.stage.goal;
    return Column(
      children: [
        const Text(
          'Progress',
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
            ScoreGoal(target: final t) => '${run.game.score} / $t points',
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
