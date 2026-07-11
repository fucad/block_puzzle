import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/events.dart';
import 'package:flutter/animation.dart' show Curves;

import '../models/piece.dart';
import 'block_painter.dart';
import 'block_puzzle_game.dart';

/// A piece waiting in the tray. Renders at tray scale; while dragged it
/// scales up to full board-cell size and floats above the finger (the
/// reference UX), driving the ghost/would-clear preview.
class TrayPieceComponent extends PositionComponent
    with DragCallbacks, HasGameReference<BlockPuzzleGame> {
  TrayPieceComponent({required this.trayIndex, required this.piece});

  final int trayIndex;
  final Piece piece;

  bool _dragging = false;

  /// How far the dragged piece floats above the finger, in board cells.
  static const _liftCells = 1.6;

  double get _trayCell => game.geometry.trayCell;
  double get _boardCell => game.geometry.cell;

  Offset get _slotCenter => game.geometry.traySlotCenters[trayIndex];

  @override
  Future<void> onLoad() async {
    anchor = Anchor.center;
    size = Vector2(piece.width * _trayCell, piece.height * _trayCell);
    position = Vector2(_slotCenter.dx, _slotCenter.dy);
  }

  @override
  void render(Canvas canvas) {
    final cellSide = _trayCell;
    final color = game.theme.blockColor(piece.colorId);
    for (final (r, c) in piece.cells) {
      paintBlock(
        canvas,
        Rect.fromLTWH(c * cellSide, r * cellSide, cellSide, cellSide),
        color,
      );
    }
  }

  // Generous hit area for fat fingers around small pieces.
  @override
  bool containsLocalPoint(Vector2 point) {
    final pad = _trayCell * 0.9;
    return point.x >= -pad &&
        point.y >= -pad &&
        point.x <= size.x + pad &&
        point.y <= size.y + pad;
  }

  @override
  void onDragStart(DragStartEvent event) {
    super.onDragStart(event);
    _dragging = true;
    priority = 100;
    scale = Vector2.all(_boardCell / _trayCell);
    _followFinger(event.canvasPosition);
  }

  @override
  void onDragUpdate(DragUpdateEvent event) {
    if (!_dragging) return;
    _followFinger(event.canvasEndPosition);
  }

  void _followFinger(Vector2 canvasPoint) {
    position = canvasPoint + Vector2(0, -_liftCells * _boardCell);
    game.updatePreview(piece, _topLeftCorner());
  }

  /// Canvas position of the piece's bounding-box top-left corner at the
  /// current (scaled) render size.
  Offset _topLeftCorner() {
    final w = piece.width * _boardCell;
    final h = piece.height * _boardCell;
    return Offset(position.x - w / 2, position.y - h / 2);
  }

  @override
  void onDragEnd(DragEndEvent event) {
    super.onDragEnd(event);
    if (!_dragging) return;
    _dragging = false;
    final dropped = game.tryPlace(trayIndex, _topLeftCorner());
    game.clearPreview();
    if (dropped == null) _returnToTray();
    // On success the state listener rebuilds the tray, removing this
    // component; nothing else to do here.
  }

  @override
  void onDragCancel(DragCancelEvent event) {
    super.onDragCancel(event);
    _dragging = false;
    game.clearPreview();
    _returnToTray();
  }

  void _returnToTray() {
    priority = 0;
    addAll([
      MoveToEffect(
        Vector2(_slotCenter.dx, _slotCenter.dy),
        EffectController(duration: 0.18, curve: Curves.easeOut),
      ),
      ScaleEffect.to(
        Vector2.all(1),
        EffectController(duration: 0.18, curve: Curves.easeOut),
      ),
    ]);
  }
}
