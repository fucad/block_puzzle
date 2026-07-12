import 'dart:math';
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/particles.dart';
import 'package:flame/text.dart';
import 'package:flutter/animation.dart' show Curves;

import '../systems/game_constants.dart';
import '../systems/game_engine.dart';
import 'block_puzzle_game.dart';

/// Visual-only tuning for juice; rule constants stay in game_constants.
const int comboGlowMin = 3; // board glow turns on
const int comboRainbowMin = 6; // ...and goes rainbow
const double _popupSeconds = 0.9;

final _rng = Random();

/// Praise ladder, scaled to the moment (reference: "Good!" → "Unbelievable!").
String? praiseFor(PlacementEvents e) {
  if (e.linesCleared == 0) return null;
  if (e.linesCleared >= 3 || e.combo >= 10) return 'Unbelievable!';
  if (e.linesCleared == 2 || e.combo >= 6) return 'Amazing!';
  if (e.combo >= 4) return 'Great!';
  if (e.combo >= 2) return 'Good!';
  return null;
}

/// Spawns everything a placement earned: line sweeps, per-cell bursts,
/// screen shake, praise + combo popups, and the all-clear celebration.
void spawnPlacementEffects(BlockPuzzleGame game, PlacementEvents events) {
  if (events.linesCleared == 0) return;
  final geo = game.geometry;
  final board = geo.boardRect;

  // Shake scales with the moment: any multi-line or combo rattles the
  // board; an all-clear slams it.
  if (events.allClear) {
    game.shake(amplitude: 12, duration: 0.5);
  } else if (events.combo >= 2 || events.linesCleared >= 2) {
    game.shake(
      amplitude: (3 + events.combo * 1.2 + events.linesCleared * 1.5)
          .clamp(4, 10)
          .toDouble(),
    );
  }

  for (final row in events.clearedRows) {
    _sweep(
      game,
      Rect.fromLTWH(
        board.left,
        board.top + row * geo.cell,
        board.width,
        geo.cell,
      ),
    );
    for (var col = 0; col < boardSize; col++) {
      _cellBurst(game, row, col);
    }
  }
  for (final col in events.clearedCols) {
    _sweep(
      game,
      Rect.fromLTWH(
        board.left + col * geo.cell,
        board.top,
        geo.cell,
        board.height,
      ),
    );
    for (var row = 0; row < boardSize; row++) {
      if (events.clearedRows.contains(row)) continue; // burst once
      _cellBurst(game, row, col);
    }
  }

  final center = Vector2(board.center.dx, board.center.dy);
  final praise = praiseFor(events);
  if (praise != null) {
    game.add(
      _PopupText(
        praise,
        at: center - Vector2(0, geo.cell),
        fontSize: 40,
        color: const Color(0xFFFFFFFF),
      ),
    );
  }
  if (events.combo >= 2) {
    game.add(
      _PopupText(
        'Combo ${events.combo}',
        at: center + Vector2(0, geo.cell * 0.6),
        fontSize: 34,
        color: const Color(0xFFFFD54F),
      ),
    );
  }
  if (events.allClear) {
    game.add(
      _PopupText(
        'ALL CLEAR  +$allClearBonus',
        at: center + Vector2(0, geo.cell * 2.2),
        fontSize: 30,
        color: const Color(0xFFFFF176),
      ),
    );
    for (var i = 0; i < 3; i++) {
      _confetti(game, center, delaySeconds: i * 0.12);
    }
  }
}

void _sweep(BlockPuzzleGame game, Rect rect) {
  final sweep = RectangleComponent(
    position: Vector2(rect.left, rect.top),
    size: Vector2(rect.width, rect.height),
    paint: Paint()..color = const Color(0x80FFFFFF),
    priority: 40,
  );
  sweep.addAll([
    OpacityEffect.fadeOut(
      EffectController(duration: 0.35, curve: Curves.easeOut),
    ),
    RemoveEffect(delay: 0.4),
  ]);
  game.add(sweep);
}

void _cellBurst(BlockPuzzleGame game, int row, int col) {
  final geo = game.geometry;
  final cellSide = geo.cell;
  final origin = geo.cellTopLeft(row, col);
  final palette = game.theme.blockPalette;
  game.add(
    ParticleSystemComponent(
      position: Vector2(origin.dx + cellSide / 2, origin.dy + cellSide / 2),
      priority: 45,
      particle: Particle.generate(
        count: 5,
        lifespan: 0.55,
        generator: (i) {
          final color = palette[_rng.nextInt(palette.length)];
          final side = cellSide * (0.14 + _rng.nextDouble() * 0.12);
          return AcceleratedParticle(
            acceleration: Vector2(0, 1300),
            speed: Vector2(
              (_rng.nextDouble() - 0.5) * 420,
              -_rng.nextDouble() * 380 - 60,
            ),
            child: ComputedParticle(
              renderer: (canvas, particle) {
                final alpha = (1 - particle.progress).clamp(0.0, 1.0);
                canvas.drawRRect(
                  RRect.fromRectAndRadius(
                    Rect.fromCenter(
                      center: Offset.zero,
                      width: side,
                      height: side,
                    ),
                    Radius.circular(side * 0.25),
                  ),
                  Paint()..color = color.withValues(alpha: alpha),
                );
              },
            ),
          );
        },
      ),
    ),
  );
}

void _confetti(
  BlockPuzzleGame game,
  Vector2 center, {
  double delaySeconds = 0,
}) {
  final palette = game.theme.blockPalette;
  game.add(
    ParticleSystemComponent(
      position: center,
      priority: 45,
      particle: Particle.generate(
        count: 36,
        lifespan: 1.1 + delaySeconds,
        generator: (i) {
          final angle = _rng.nextDouble() * 2 * pi;
          final speed = 200 + _rng.nextDouble() * 420;
          final color = palette[_rng.nextInt(palette.length)];
          return AcceleratedParticle(
            acceleration: Vector2(0, 700),
            speed: Vector2(cos(angle), sin(angle)) * speed,
            child: ComputedParticle(
              renderer: (canvas, particle) {
                final alpha = (1 - particle.progress).clamp(0.0, 1.0);
                canvas.drawCircle(
                  Offset.zero,
                  4 + 3 * (1 - particle.progress),
                  Paint()..color = color.withValues(alpha: alpha),
                );
              },
            ),
          );
        },
      ),
    ),
  );
}

/// Pop-in, drift up, disappear. Used for praise, combo, and bonus popups.
class _PopupText extends TextComponent {
  _PopupText(
    String text, {
    required Vector2 at,
    required double fontSize,
    required Color color,
  }) : super(
         text: text,
         anchor: Anchor.center,
         position: at,
         priority: 60,
         textRenderer: TextPaint(
           style: TextStyle(
             fontSize: fontSize,
             fontWeight: FontWeight.w900,
             color: color,
             shadows: const [
               Shadow(
                 color: Color(0xAA000000),
                 blurRadius: 8,
                 offset: Offset(0, 3),
               ),
             ],
           ),
         ),
       );

  @override
  Future<void> onLoad() async {
    scale = Vector2.all(0.3);
    addAll([
      ScaleEffect.to(
        Vector2.all(1),
        EffectController(duration: 0.22, curve: Curves.easeOutBack),
      ),
      MoveByEffect(
        Vector2(0, -34),
        EffectController(duration: _popupSeconds, curve: Curves.easeOut),
      ),
      RemoveEffect(delay: _popupSeconds),
    ]);
  }
}
