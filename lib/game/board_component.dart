import 'dart:ui';

import 'package:flame/components.dart';

import '../models/board.dart';
import 'block_painter.dart';
import 'block_puzzle_game.dart';

/// Renders the 8×8 board every frame straight from game.state: background,
/// settled cells, would-clear line glow, and the snapped ghost preview.
class BoardComponent extends PositionComponent
    with HasGameReference<BlockPuzzleGame> {
  @override
  Future<void> onLoad() async {
    position = Vector2(
      game.geometry.boardRect.left,
      game.geometry.boardRect.top,
    );
    size = Vector2.all(game.geometry.boardRect.width);
  }

  @override
  void render(Canvas canvas) {
    final theme = game.theme;
    final cell = game.geometry.cell;
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

    // Ghost: the piece at 45% opacity on its snapped cells.
    final color = theme.blockColor(preview.piece.colorId);
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
