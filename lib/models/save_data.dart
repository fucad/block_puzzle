import 'game_state.dart';

/// Player-visible preferences. Persisted inside [SaveData].
class Settings {
  const Settings({
    this.soundOn = true,
    this.hapticsOn = true,
    this.themeId = 'default',
  });

  final bool soundOn;
  final bool hapticsOn;
  final String themeId;

  Settings copyWith({bool? soundOn, bool? hapticsOn, String? themeId}) =>
      Settings(
        soundOn: soundOn ?? this.soundOn,
        hapticsOn: hapticsOn ?? this.hapticsOn,
        themeId: themeId ?? this.themeId,
      );

  Map<String, Object?> toJson() => {
    'soundOn': soundOn,
    'hapticsOn': hapticsOn,
    'themeId': themeId,
  };

  factory Settings.fromJson(Map<String, Object?> json) => Settings(
    soundOn: json['soundOn'] as bool? ?? true,
    hapticsOn: json['hapticsOn'] as bool? ?? true,
    themeId: json['themeId'] as String? ?? 'default',
  );
}

/// Versioned root of everything persisted. Schema documented in
/// SAVE_MODEL.md — bump [schemaVersion] and migrate there on any change.
class SaveData {
  const SaveData({
    this.settings = const Settings(),
    this.classicHighScore = 0,
    this.allTimeBestCombo = 0,
    this.classicRun,
    this.classicRunSeed,
    this.questRun,
    this.questRunPackId,
    this.questRunStageId,
    this.questRunLevelNumber,
    this.questCompleted = const {},
    this.lastQuestFetchEpochMs,
  });

  static const int schemaVersion = 1;

  final Settings settings;
  final int classicHighScore;
  final int allTimeBestCombo;

  /// In-progress classic run to resume after app kill; null when none.
  final GameState? classicRun;

  /// Seed the resumable run started from (diagnostics / bug reproduction).
  final int? classicRunSeed;

  /// In-progress quest attempt to resume after leaving the stage or an app
  /// kill; null when none. Reconstructing the full [QuestRun] needs the
  /// pack/stage from the catalog, so we also store the ids and level.
  final GameState? questRun;
  final String? questRunPackId;
  final String? questRunStageId;
  final int? questRunLevelNumber;

  /// Completed quest stage ids, keyed by pack id.
  final Map<String, Set<String>> questCompleted;

  /// When the quest manifest was last fetched (throttles refetching).
  final int? lastQuestFetchEpochMs;

  SaveData copyWith({
    Settings? settings,
    int? classicHighScore,
    int? allTimeBestCombo,
    GameState? classicRun,
    bool clearClassicRun = false,
    int? classicRunSeed,
    GameState? questRun,
    String? questRunPackId,
    String? questRunStageId,
    int? questRunLevelNumber,
    bool clearQuestRun = false,
    Map<String, Set<String>>? questCompleted,
    int? lastQuestFetchEpochMs,
  }) {
    return SaveData(
      settings: settings ?? this.settings,
      classicHighScore: classicHighScore ?? this.classicHighScore,
      allTimeBestCombo: allTimeBestCombo ?? this.allTimeBestCombo,
      classicRun: clearClassicRun ? null : (classicRun ?? this.classicRun),
      classicRunSeed: clearClassicRun
          ? null
          : (classicRunSeed ?? this.classicRunSeed),
      questRun: clearQuestRun ? null : (questRun ?? this.questRun),
      questRunPackId: clearQuestRun
          ? null
          : (questRunPackId ?? this.questRunPackId),
      questRunStageId: clearQuestRun
          ? null
          : (questRunStageId ?? this.questRunStageId),
      questRunLevelNumber: clearQuestRun
          ? null
          : (questRunLevelNumber ?? this.questRunLevelNumber),
      questCompleted: questCompleted ?? this.questCompleted,
      lastQuestFetchEpochMs:
          lastQuestFetchEpochMs ?? this.lastQuestFetchEpochMs,
    );
  }

  Map<String, Object?> toJson() => {
    'version': schemaVersion,
    'settings': settings.toJson(),
    'classicHighScore': classicHighScore,
    'allTimeBestCombo': allTimeBestCombo,
    'classicRun': classicRun?.toJson(),
    'classicRunSeed': classicRunSeed?.toString(),
    if (questRun != null) ...{
      'questRun': questRun!.toJson(),
      'questRunPackId': questRunPackId,
      'questRunStageId': questRunStageId,
      'questRunLevelNumber': questRunLevelNumber,
    },
    'questCompleted': questCompleted.map(
      (packId, stages) => MapEntry(packId, stages.toList()..sort()),
    ),
    'lastQuestFetchEpochMs': lastQuestFetchEpochMs,
  };

  /// Strict on version: unknown versions throw [FormatException] so the
  /// caller can decide (never silently drop a player's progress).
  factory SaveData.fromJson(Map<String, Object?> json) {
    final version = json['version'] as int?;
    if (version != schemaVersion) {
      throw FormatException('Unsupported save version: $version');
    }
    final run = json['classicRun'] as Map?;
    final seed = json['classicRunSeed'] as String?;
    final questRun = json['questRun'] as Map?;
    return SaveData(
      settings: Settings.fromJson(
        (json['settings'] as Map? ?? const {}).cast<String, Object?>(),
      ),
      classicHighScore: json['classicHighScore'] as int? ?? 0,
      allTimeBestCombo: json['allTimeBestCombo'] as int? ?? 0,
      classicRun: run == null
          ? null
          : GameState.fromJson(run.cast<String, Object?>()),
      classicRunSeed: seed == null ? null : int.parse(seed),
      questRun: questRun == null
          ? null
          : GameState.fromJson(questRun.cast<String, Object?>()),
      questRunPackId: json['questRunPackId'] as String?,
      questRunStageId: json['questRunStageId'] as String?,
      questRunLevelNumber: json['questRunLevelNumber'] as int?,
      questCompleted: {
        for (final entry
            in (json['questCompleted'] as Map? ?? const {})
                .cast<String, Object?>()
                .entries)
          entry.key: (entry.value as List).cast<String>().toSet(),
      },
      lastQuestFetchEpochMs: json['lastQuestFetchEpochMs'] as int?,
    );
  }
}
