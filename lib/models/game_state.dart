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
    this.trayGems = const [],
    this.gemGoal = const {},
  });

  final Board board;

  /// Piece ids of the current tray; `null` = slot already played.
  final List<String?> tray;

  /// Gems carried by each tray slot (quest gem stages): index i maps a
  /// piece-cell index to a gem color. Empty map = a plain piece. Parallel
  /// to [tray]; empty overall in classic and non-gem stages.
  final List<Map<int, GemColor>> trayGems;

  /// The stage's gem target (quest gem stages), so the generator only
  /// spawns colors still needed. Empty otherwise.
  final Map<GemColor, int> gemGoal;

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

  /// Gems for tray slot [i], or an empty map if that slot has none.
  Map<int, GemColor> gemsForSlot(int i) =>
      i < trayGems.length ? trayGems[i] : const {};

  GameState copyWith({
    Board? board,
    List<String?>? tray,
    List<Map<int, GemColor>>? trayGems,
    Map<GemColor, int>? gemGoal,
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
      trayGems: trayGems ?? this.trayGems,
      gemGoal: gemGoal ?? this.gemGoal,
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
    if (trayGems.any((m) => m.isNotEmpty))
      'trayGems': [
        for (final m in trayGems)
          m.map((cell, color) => MapEntry('$cell', color.name)),
      ],
    if (gemGoal.isNotEmpty)
      'gemGoal': gemGoal.map((color, n) => MapEntry(color.name, n)),
    'gems': gemsCollected.map((color, count) => MapEntry(color.name, count)),
  };

  factory GameState.fromJson(Map<String, Object?> json) {
    final gems = (json['gems'] as Map? ?? const {}).cast<String, int>();
    final trayGemsJson = json['trayGems'] as List?;
    final gemGoalJson = (json['gemGoal'] as Map? ?? const {})
        .cast<String, int>();
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
      trayGems: trayGemsJson == null
          ? const []
          : [
              for (final m in trayGemsJson)
                {
                  for (final e in (m as Map).cast<String, String>().entries)
                    int.parse(e.key): GemColor.values.byName(e.value),
                },
            ],
      gemGoal: {
        for (final e in gemGoalJson.entries)
          GemColor.values.byName(e.key): e.value,
      },
      gemsCollected: {
        for (final entry in gems.entries)
          GemColor.values.byName(entry.key): entry.value,
      },
    );
  }
}
