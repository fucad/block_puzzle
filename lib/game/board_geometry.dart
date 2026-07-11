import 'dart:math';
import 'dart:ui';

import '../systems/game_constants.dart';

/// Pure layout math for the play area (board + tray) inside the Flame
/// canvas. Everything renders in canvas coordinates; no camera transforms.
class BoardGeometry {
  BoardGeometry(Size canvasSize) {
    const pad = 12.0;
    final side = min(canvasSize.width - pad * 2, canvasSize.height * 0.7);
    final left = (canvasSize.width - side) / 2;
    boardRect = Rect.fromLTWH(left, pad, side, side);
    cell = side / boardSize;
    trayCell = cell * 0.55;
    final trayTop = boardRect.bottom + 8;
    final trayCenterY = trayTop + (canvasSize.height - trayTop) / 2;
    traySlotCenters = List.unmodifiable([
      for (var i = 0; i < traySize; i++)
        Offset(canvasSize.width * (2 * i + 1) / (2 * traySize), trayCenterY),
    ]);
  }

  late final Rect boardRect;

  /// Side length of one board cell.
  late final double cell;

  /// Side length of one cell of a piece resting in the tray.
  late final double trayCell;

  late final List<Offset> traySlotCenters;

  /// Board cell whose top-left corner is nearest to [pieceTopLeft] (canvas
  /// coords). May be out of range — the caller validates with canPlace.
  (int row, int col) snapCell(Offset pieceTopLeft) => (
    ((pieceTopLeft.dy - boardRect.top) / cell).round(),
    ((pieceTopLeft.dx - boardRect.left) / cell).round(),
  );

  Offset cellTopLeft(int row, int col) =>
      Offset(boardRect.left + col * cell, boardRect.top + row * cell);
}
