import 'dart:math';
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/particles.dart';
import 'package:flame/text.dart';
import 'package:flutter/animation.dart' show Curves;

import '../models/board.dart';
import '../models/cell.dart';
import '../models/game_theme.dart';
import '../systems/game_constants.dart';
import '../systems/game_engine.dart';
import 'block_painter.dart';
import 'block_puzzle_game.dart';

/// Visual-only tuning for juice; rule constants stay in game_constants.
const int comboGlowMin = 3; // board glow turns on
const int comboRainbowMin = 6; // ...and goes rainbow
const double _popupSeconds = 0.9;

final _rng = Random();

/// Random praise, in tiers of rising excitement — a clear picks a message
/// from the tier matching how big the moment was. The chosen string is
/// also reused on the quest Level Complete screen.
const List<List<String>> praiseTiers = [
  ['Good!', 'Nice!', 'Good job!', 'Sweet!'],
  ['Great!', 'Well done!', 'Awesome!', 'Cool!'],
  ['Fantastic!', 'Amazing!', 'Brilliant!', 'Superb!'],
  ['Unbelievable!', 'Incredible!', 'The Best!', 'Legendary!'],
];

int _praiseTier(PlacementEvents e) {
  if (e.allClear || e.combo >= 10 || e.linesCleared >= 3) return 3;
  if (e.combo >= 6 || e.linesCleared == 2) return 2;
  if (e.combo >= 3) return 1;
  return 0;
}

/// A random praise for the moment, or null if nothing cleared.
String? praiseFor(PlacementEvents e) {
  if (e.linesCleared == 0) return null;
  final tier = praiseTiers[_praiseTier(e)];
  return tier[_rng.nextInt(tier.length)];
}

/// Spawns everything a placement earned: falling cleared blocks, gem
/// collect fly-ups, line sweeps, screen shake, praise + combo popups, and
/// the all-clear celebration. [stamped] is the board just before the
/// clear, so the vanishing cells' colors/gems are known.
void spawnPlacementEffects(
  BlockPuzzleGame game,
  PlacementEvents events,
  Board stamped,
) {
  if (events.linesCleared == 0) return;
  final geo = game.geometry;
  final board = geo.boardRect;

  // Every cleared cell drops a short distance and fades; gem cells instead
  // fly up (toward the goal counters).
  final clearedCells = <(int, int)>{};
  for (final row in events.clearedRows) {
    for (var c = 0; c < boardSize; c++) {
      clearedCells.add((row, c));
    }
  }
  for (final col in events.clearedCols) {
    for (var r = 0; r < boardSize; r++) {
      clearedCells.add((r, col));
    }
  }
  for (final (r, c) in clearedCells) {
    final occupant = stamped.at(r, c);
    if (occupant == null) continue;
    final origin = geo.cellTopLeft(r, c);
    if (occupant.gem != null) {
      _gemFlyUp(game, origin, occupant.gem!);
    } else {
      final color = occupant.preplaced
          ? puzzleBlockLight
          : game.theme.blockColor(occupant.colorId);
      _fallingBlock(game, origin, color);
    }
  }

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
    game.lastPraise = praise; // reused on the quest Level Complete screen
    game.add(
      _PopupText(
        praise,
        // Above the action, near the top of the board.
        at: Vector2(board.center.dx, board.top + geo.cell * 1.4),
        fontSize: 42,
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

/// A cleared block drops a short distance and fades (not all the way
/// down — just enough to read as "knocked loose").
void _fallingBlock(BlockPuzzleGame game, Offset origin, Color color) {
  game.add(
    _FallingBlock(origin: origin, size: game.geometry.cell, color: color),
  );
}

/// A collected gem floats up toward the goal counters and fades.
void _gemFlyUp(BlockPuzzleGame game, Offset origin, GemColor gem) {
  game.add(
    _FlyingGem(
      origin: origin,
      cell: game.geometry.cell,
      color: gemColors[gem]!,
    ),
  );
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

/// A cleared block: renders the block falling a short distance while
/// fading out. Self-removes when done.
class _FallingBlock extends PositionComponent {
  _FallingBlock({
    required Offset origin,
    required double size,
    required this.color,
  }) : _cell = size,
       super(position: Vector2(origin.dx, origin.dy), priority: 42);

  final double _cell;
  final Color color;

  static const _life = 0.45;
  double _t = 0;

  @override
  void update(double dt) {
    _t += dt;
    // Ease-in fall (gravity feel), a little over one cell.
    position.y += (_cell * 3.2) * _t * dt / _life;
    if (_t >= _life) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    final alpha = (1 - _t / _life).clamp(0.0, 1.0);
    paintBlock(
      canvas,
      Rect.fromLTWH(0, 0, _cell, _cell),
      color,
      opacity: alpha,
    );
  }
}

/// A collected gem: an 8-point star drifting up toward the goal counters,
/// shrinking and fading.
class _FlyingGem extends PositionComponent {
  _FlyingGem({required Offset origin, required this.cell, required this.color})
    : super(
        position: Vector2(origin.dx + cell / 2, origin.dy + cell / 2),
        priority: 55,
      );

  final double cell;
  final Color color;

  static const _life = 0.7;
  double _t = 0;

  @override
  void update(double dt) {
    _t += dt;
    position.y -= cell * 4 * dt; // rise toward the counters above
    if (_t >= _life) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    final progress = _t / _life;
    final alpha = (1 - progress).clamp(0.0, 1.0);
    final r = cell * 0.3 * (1 - 0.4 * progress);
    final path = Path();
    for (var i = 0; i < 16; i++) {
      final radius = i.isEven ? r : r * 0.45;
      final angle = i * pi / 8 - pi / 2;
      final p = Offset(radius * cos(angle), radius * sin(angle));
      i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
    }
    path.close();
    canvas.drawPath(path, Paint()..color = color.withValues(alpha: alpha));
  }
}
