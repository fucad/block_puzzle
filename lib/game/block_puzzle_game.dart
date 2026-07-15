import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/foundation.dart';

import '../models/board.dart';
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
  // Short: a puzzle spends most of its time static between moves, so
  // pause quickly. Gestures and state changes resume instantly.
  static const _idleAfterSeconds = 0.35;
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

  /// Updates [preview] while a piece hovers with its top-left cell corner
  /// at [pieceTopLeft]. Behaviour (per playtest feedback):
  /// - off the board → no preview (the drop will bounce back to the tray),
  /// - over the board → always show a ghost. Snap to the nearest legal
  ///   spot so there is always a pre-place, and the drop lands there —
  ///   you don't have to hit the exact cell.
  /// - over the board but the piece fits nowhere → an invalid (red) ghost
  ///   at the clamped position; the drop bounces.
  void updatePreview(Piece piece, Offset pieceTopLeft) {
    final cell = geometry.cell;
    final center =
        pieceTopLeft + Offset(piece.width * cell / 2, piece.height * cell / 2);
    if (!geometry.boardRect.inflate(cell * 0.6).contains(center)) {
      preview = null; // off the grid
      return;
    }
    final (rawRow, rawCol) = geometry.snapCell(pieceTopLeft);
    final resolved = _nearestLegal(piece, rawRow, rawCol);
    if (resolved == null) {
      preview = DragPreview(
        piece: piece,
        row: rawRow.clamp(0, Board.size - piece.height),
        col: rawCol.clamp(0, Board.size - piece.width),
        legal: false,
        wouldClearRows: const [],
        wouldClearCols: const [],
      );
      return;
    }
    final (row, col) = resolved;
    final result = clearFullLines(stamp(state.board, piece, row, col));
    preview = DragPreview(
      piece: piece,
      row: row,
      col: col,
      legal: true,
      wouldClearRows: result.rows,
      wouldClearCols: result.cols,
    );
  }

  /// Closest legal placement to the raw snap (Euclidean in cell space),
  /// or null if the piece fits nowhere.
  (int, int)? _nearestLegal(Piece piece, int rawRow, int rawCol) {
    final maxRow = Board.size - piece.height;
    final maxCol = Board.size - piece.width;
    if (maxRow < 0 || maxCol < 0) return null;
    (int, int)? best;
    var bestDist = 1 << 30;
    for (var r = 0; r <= maxRow; r++) {
      for (var c = 0; c <= maxCol; c++) {
        if (!canPlace(state.board, piece, r, c)) continue;
        final d = (r - rawRow) * (r - rawRow) + (c - rawCol) * (c - rawCol);
        if (d < bestDist) {
          bestDist = d;
          best = (r, c);
        }
      }
    }
    return best;
  }

  void clearPreview() => preview = null;

  /// Drops [trayIndex] at the resolved preview cell. Returns null (bounce
  /// to tray) when there is no legal preview — i.e. off-grid or no fit.
  PlacementOutcome? tryPlace(int trayIndex) {
    final p = preview;
    if (p == null || !p.legal) return null;
    final outcome = onPlace(trayIndex, p.row, p.col);
    if (outcome != null) spawnPlacementEffects(this, outcome.events);
    return outcome;
  }
}
