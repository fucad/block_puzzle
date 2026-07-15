import 'board.dart';
import 'cell.dart';

/// Immutable snapshot of one run (Classic or a Quest stage). Advanced only
/// by GameEngine; serialized as-is into the save file (see SAVE_MODEL.md).
class GameState {
  const GameState({
    required this.board,
    required this.tray,
    required this.rngState,
    required this.score,
    required this.combo,
    required this.roundBestCombo,
    this.allClears = 0,
    this.clearFocus = false,
    this.gemsCollected = const {},
  });

  final Board board;

  /// Piece ids of the current tray; `null` = slot already played.
  final List<String?> tray;

  /// GameRng state to draw the next tray from.
  final int rngState;

  final int score;

  /// Current streak: placements in a row that each cleared ≥1 line.
  final int combo;

  final int roundBestCombo;

  /// All-clears earned this run (drives the end-of-run summary variants).
  final int allClears;

  /// Classic mode: bias tray generation hard toward clears/combos.
  final bool clearFocus;

  /// Gems collected so far this run (quest mode).
  final Map<GemColor, int> gemsCollected;

  GameState copyWith({
    Board? board,
    List<String?>? tray,
    int? rngState,
    int? score,
    int? combo,
    int? roundBestCombo,
    int? allClears,
    bool? clearFocus,
    Map<GemColor, int>? gemsCollected,
  }) {
    return GameState(
      board: board ?? this.board,
      tray: tray ?? this.tray,
      rngState: rngState ?? this.rngState,
      score: score ?? this.score,
      combo: combo ?? this.combo,
      roundBestCombo: roundBestCombo ?? this.roundBestCombo,
      allClears: allClears ?? this.allClears,
      clearFocus: clearFocus ?? this.clearFocus,
      gemsCollected: gemsCollected ?? this.gemsCollected,
    );
  }

  Map<String, Object?> toJson() => {
    'board': board.toJson(),
    'tray': tray,
    // As a string: JSON round-trips through doubles in some tooling, which
    // would corrupt a 64-bit state.
    'rngState': rngState.toString(),
    'score': score,
    'combo': combo,
    'roundBestCombo': roundBestCombo,
    'allClears': allClears,
    if (clearFocus) 'clearFocus': true,
    'gems': gemsCollected.map((color, count) => MapEntry(color.name, count)),
  };

  factory GameState.fromJson(Map<String, Object?> json) {
    final gems = (json['gems'] as Map? ?? const {}).cast<String, int>();
    return GameState(
      board: Board.fromJson(json['board'] as List<Object?>),
      tray: (json['tray'] as List).cast<String?>(),
      rngState: int.parse(json['rngState'] as String),
      score: json['score'] as int,
      combo: json['combo'] as int,
      roundBestCombo: json['roundBestCombo'] as int,
      // Tolerant default: saves written before this field existed.
      allClears: json['allClears'] as int? ?? 0,
      clearFocus: json['clearFocus'] as bool? ?? false,
      gemsCollected: {
        for (final entry in gems.entries)
          GemColor.values.byName(entry.key): entry.value,
      },
    );
  }
}
