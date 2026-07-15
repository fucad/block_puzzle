import 'dart:math';
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flutter/painting.dart' show HSVColor;

import '../models/board.dart';
import '../models/game_theme.dart';
import 'block_painter.dart';
import 'block_puzzle_game.dart';
import 'effects.dart';

/// Renders the 8×8 board every frame straight from game.state: background,
/// settled cells, combo glow frame, would-clear line glow, and the snapped
/// ghost preview.
class BoardComponent extends PositionComponent
    with HasGameReference<BlockPuzzleGame> {
  double _time = 0;

  @override
  Future<void> onLoad() async {
    position = Vector2(
      game.geometry.boardRect.left,
      game.geometry.boardRect.top,
    );
    size = Vector2.all(game.geometry.boardRect.width);
  }

  @override
  void update(double dt) => _time += dt;

  static final _shakeRng = Random();

  @override
  void render(Canvas canvas) {
    final theme = game.theme;
    final cell = game.geometry.cell;

    // Combo/clear screen shake: jitter the whole board while it decays.
    if (game.shaking) {
      final s = game.shakeStrength;
      canvas.translate(
        (_shakeRng.nextDouble() * 2 - 1) * s,
        (_shakeRng.nextDouble() * 2 - 1) * s,
      );
    }

    // Combo streak glow around the frame: gold when warm, hue-cycling
    // rainbow when hot (reference UX). Drawn as a few concentric
    // translucent strokes rather than a MaskFilter.blur — a per-frame
    // blur is one of the most expensive mobile-GPU ops and, sustained
    // during a hot streak, was a real thermal-throttling contributor.
    final combo = game.state.combo;
    if (combo >= comboGlowMin) {
      final rainbow = combo >= comboRainbowMin;
      final baseColor = rainbow
          ? HSVColor.fromAHSV(1, (_time * 160) % 360, 0.7, 1).toColor()
          : const Color(0xFFF2C94C);
      final pulse = 0.7 + 0.3 * sin(_time * 5);
      for (var i = 0; i < 3; i++) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(
              -6.0 - i * 5,
              -6.0 - i * 5,
              size.x + 12 + i * 10,
              size.y + 12 + i * 10,
            ),
            Radius.circular(14 + i * 3),
          ),
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 6 - i * 1.5
            ..color = baseColor.withValues(alpha: pulse * (0.5 - i * 0.15)),
        );
      }
    }

    final boardPaint = Paint()..color = theme.boardBackground;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(-6, -6, size.x + 12, size.y + 12),
        const Radius.circular(12),
      ),
      boardPaint,
    );

    for (var row = 0; row < Board.size; row++) {
      for (var col = 0; col < Board.size; col++) {
        final rect = Rect.fromLTWH(col * cell, row * cell, cell, cell);
        final occupant = game.state.board.at(row, col);
        if (occupant == null) {
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              rect.deflate(cell * 0.03),
              Radius.circular(cell * 0.12),
            ),
            Paint()..color = theme.emptyCell,
          );
        } else if (occupant.gem != null) {
          paintBlock(canvas, rect, gemBlockGold);
          _paintGem(canvas, rect, gemColors[occupant.gem]!);
        } else {
          paintBlock(canvas, rect, theme.blockColor(occupant.colorId));
        }
      }
    }

    final preview = game.preview;
    if (preview == null || !preview.legal) return;

    // Would-clear lines glow across their full length.
    final glow = Paint()..color = theme.lineHighlight;
    for (final row in preview.wouldClearRows) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(0, row * cell, size.x, cell).deflate(cell * 0.06),
          Radius.circular(cell * 0.12),
        ),
        glow,
      );
    }
    for (final col in preview.wouldClearCols) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(col * cell, 0, cell, size.y).deflate(cell * 0.06),
          Radius.circular(cell * 0.12),
        ),
        glow,
      );
    }

    _renderPreviewGhost(canvas, preview, cell);
  }

  /// Eight-point star, the quest gem sitting inside its gold block.
  void _paintGem(Canvas canvas, Rect cellRect, Color color) {
    final center = cellRect.center;
    final outer = cellRect.shortestSide * 0.30;
    final inner = outer * 0.45;
    final path = Path();
    for (var i = 0; i < 16; i++) {
      final radius = i.isEven ? outer : inner;
      final angle = i * pi / 8 - pi / 2;
      final point = Offset(
        center.dx + radius * cos(angle),
        center.dy + radius * sin(angle),
      );
      i == 0
          ? path.moveTo(point.dx, point.dy)
          : path.lineTo(point.dx, point.dy);
    }
    path.close();
    // Cheap solid drop shadow (offset, no blur) instead of a per-frame
    // MaskFilter.blur per gem — boards can hold many gems and this ran
    // every frame.
    canvas.save();
    canvas.translate(outer * 0.12, outer * 0.14);
    canvas.drawPath(path, Paint()..color = const Color(0x40000000));
    canvas.restore();
    canvas.drawPath(path, Paint()..color = color);
    canvas.drawCircle(
      center.translate(-outer * 0.25, -outer * 0.25),
      outer * 0.16,
      Paint()..color = const Color(0xAAFFFFFF),
    );
  }

  void _renderPreviewGhost(Canvas canvas, DragPreview preview, double cell) {
    // Ghost: the piece at 45% opacity on its snapped cells.
    final color = game.theme.blockColor(preview.piece.colorId);
    for (final (r, c) in preview.piece.cells) {
      final rect = Rect.fromLTWH(
        (preview.col + c) * cell,
        (preview.row + r) * cell,
        cell,
        cell,
      );
      paintBlock(canvas, rect, color, opacity: 0.45);
    }
  }
}
