import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/foundation.dart';

import '../models/game_state.dart';
import '../models/game_theme.dart';
import '../models/piece.dart';
import '../models/piece_catalog.dart';
import '../systems/game_engine.dart';
import '../systems/line_clear.dart';
import '../systems/placement.dart';
import 'board_component.dart';
import 'board_geometry.dart';
import 'effects.dart';
import 'tray_piece_component.dart';

/// What the currently dragged piece would do if dropped where it hovers.
class DragPreview {
  const DragPreview({
    required this.piece,
    required this.row,
    required this.col,
    required this.legal,
    required this.wouldClearRows,
    required this.wouldClearCols,
  });

  final Piece piece;
  final int row;
  final int col;
  final bool legal;
  final List<int> wouldClearRows;
  final List<int> wouldClearCols;
}

/// The Flame layer: renders board + tray and handles dragging. All rules
/// stay in the engine; state changes flow in via [syncState] from the
/// Riverpod listener, and placements flow out through [onPlace].
class BlockPuzzleGame extends FlameGame {
  BlockPuzzleGame({
    required this.theme,
    required GameState initialState,
    required this.onPlace,
    this.onPickup,
  }) : state = initialState;

  final GameTheme theme;
  final PlacementOutcome? Function(int trayIndex, int row, int col) onPlace;

  /// Fired when a tray piece is grabbed (haptic hook).
  final void Function()? onPickup;

  GameState state;
  late BoardGeometry geometry;
  DragPreview? preview;

  // Screen shake, decayed in update(); board rendering reads it.
  double _shakeTime = 0;
  double _shakeDuration = 0;
  double shakeAmplitude = 0;

  bool get shaking => _shakeTime > 0;

  /// Current shake strength, easing out over the shake's lifetime.
  double get shakeStrength =>
      _shakeDuration == 0 ? 0 : shakeAmplitude * (_shakeTime / _shakeDuration);

  void shake({required double amplitude, double duration = 0.35}) {
    shakeAmplitude = amplitude;
    _shakeDuration = duration;
    _shakeTime = duration;
    poke();
  }

  // --- idle auto-pause -------------------------------------------------
  // A turn-based puzzle has no business rendering 60fps while the player
  // thinks: sustained GPU load slowly heats phones into thermal
  // throttling (reported as "gets slow after a while"). When nothing is
  // animating, the engine pauses; any interaction resumes it.
  static const _idleAfterSeconds = 1.0;
  double _idleTime = 0;

  /// Set by the tray piece while a drag is in flight.
  bool dragActive = false;

  // Whitelist the transient effect types rather than blacklisting the
  // static ones: FlameGame owns permanent built-ins (World, Camera,
  // MultiDragDispatcher) that a blacklist would misread as "animating"
  // forever — which is exactly the bug the component census caught.
  bool get _animating =>
      dragActive ||
      shaking ||
      state.combo >= comboGlowMin || // glow frame animates continuously
      children.any(
        (c) =>
            c is ParticleSystemComponent ||
            c is RectangleComponent ||
            c is TextComponent,
      );

  /// Resets the idle clock and wakes the engine if it was paused.
  void poke() {
    _idleTime = 0;
    if (paused) resumeEngine();
  }

  double _censusClock = 0;

  @override
  void update(double dt) {
    super.update(dt);
    if (_shakeTime > 0) _shakeTime = (_shakeTime - dt).clamp(0, _shakeTime);

    if (_animating) {
      _idleTime = 0;
    } else {
      _idleTime += dt;
      if (_idleTime >= _idleAfterSeconds && !paused) pauseEngine();
    }

    // Leak canary for the "slows down over time" report: logs the live
    // component population so any accumulation is visible in logcat.
    if (kDebugMode || kProfileMode) {
      _censusClock += dt;
      if (_censusClock > 5) {
        _censusClock = 0;
        final counts = <String, int>{};
        for (final c in children) {
          counts.update('${c.runtimeType}', (v) => v + 1, ifAbsent: () => 1);
        }
        debugPrint('census: ${children.length} components $counts');
      }
    }
  }

  List<String?> _renderedTray = const [];

  @override
  Color backgroundColor() => const Color(0x00000000);

  @override
  Future<void> onLoad() async {
    geometry = BoardGeometry(size.toSize());
    add(BoardComponent());
    _rebuildTray();
  }

  /// Called by the screen whenever the run state changes.
  void syncState(GameState next) {
    state = next;
    if (!_sameTray(next.tray)) _rebuildTray();
    poke();
  }

  bool _sameTray(List<String?> tray) {
    if (_renderedTray.length != tray.length) return false;
    for (var i = 0; i < tray.length; i++) {
      if (_renderedTray[i] != tray[i]) return false;
    }
    return true;
  }

  void _rebuildTray() {
    children.whereType<TrayPieceComponent>().toList().forEach(remove);
    for (var i = 0; i < state.tray.length; i++) {
      final id = state.tray[i];
      if (id == null) continue;
      add(TrayPieceComponent(trayIndex: i, piece: pieceById[id]!));
    }
    _renderedTray = List.of(state.tray);
  }

  /// Updates [preview] for a piece hovering with its top-left cell corner
  /// at [pieceTopLeft] (canvas coords). Null when off-board/illegal cells
  /// still produce a preview with legal=false so the ghost can hide.
  void updatePreview(Piece piece, Offset pieceTopLeft) {
    final (row, col) = geometry.snapCell(pieceTopLeft);
    final legal = canPlace(state.board, piece, row, col);
    var rows = const <int>[];
    var cols = const <int>[];
    if (legal) {
      final result = clearFullLines(stamp(state.board, piece, row, col));
      rows = result.rows;
      cols = result.cols;
    }
    preview = DragPreview(
      piece: piece,
      row: row,
      col: col,
      legal: legal,
      wouldClearRows: rows,
      wouldClearCols: cols,
    );
  }

  void clearPreview() => preview = null;

  /// Attempts the drop; returns the outcome (null = bounce back to tray).
  PlacementOutcome? tryPlace(int trayIndex, Offset pieceTopLeft) {
    final piece = pieceById[state.tray[trayIndex]!]!;
    final (row, col) = geometry.snapCell(pieceTopLeft);
    if (!canPlace(state.board, piece, row, col)) return null;
    final outcome = onPlace(trayIndex, row, col);
    if (outcome != null) spawnPlacementEffects(this, outcome.events);
    return outcome;
  }
}
