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

  /// Gems collected so far this run (quest mode).
  final Map<GemColor, int> gemsCollected;

  GameState copyWith({
    Board? board,
    List<String?>? tray,
    int? rngState,
    int? score,
    int? combo,
    int? roundBestCombo,
    Map<GemColor, int>? gemsCollected,
  }) {
    return GameState(
      board: board ?? this.board,
      tray: tray ?? this.tray,
      rngState: rngState ?? this.rngState,
      score: score ?? this.score,
      combo: combo ?? this.combo,
      roundBestCombo: roundBestCombo ?? this.roundBestCombo,
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
      gemsCollected: {
        for (final entry in gems.entries)
          GemColor.values.byName(entry.key): entry.value,
      },
    );
  }
}
