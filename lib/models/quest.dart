/// Quest content models with STRICT parsing: any structural problem throws
/// [FormatException] with a path, so bad packs fail loudly in the validator
/// and never half-load in the app. Schema doc: CONTRIBUTING_QUESTS.md.
library;

import 'board.dart';
import 'board_strings.dart';
import 'cell.dart';
import 'piece_catalog.dart';

const int questSchemaVersion = 1;

/// One entry of content/quests/manifest.json.
class QuestPackRef {
  const QuestPackRef({
    required this.id,
    required this.title,
    required this.releaseDate,
    required this.file,
    required this.checksum,
  });

  final String id;
  final String title;

  /// UTC date; the pack goes live when `releaseDate <= today` (UTC).
  final DateTime releaseDate;

  /// Path relative to content/quests/, e.g. "packs/starter.json".
  final String file;

  /// Lowercase hex sha256 of the pack file bytes.
  final String checksum;

  factory QuestPackRef.fromJson(Map<String, Object?> json) {
    final date = _string(json, 'release_date', 'pack ref');
    if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(date)) {
      throw FormatException('pack release_date must be YYYY-MM-DD: "$date"');
    }
    return QuestPackRef(
      id: _string(json, 'id', 'pack ref'),
      title: _string(json, 'title', 'pack ref'),
      releaseDate: DateTime.parse('${date}T00:00:00Z'),
      file: _string(json, 'file', 'pack ref'),
      checksum: _string(json, 'checksum', 'pack ref'),
    );
  }

  bool releasedBy(DateTime nowUtc) => !releaseDate.isAfter(nowUtc);
}

class QuestManifest {
  const QuestManifest({required this.packs});

  final List<QuestPackRef> packs;

  factory QuestManifest.fromJson(Map<String, Object?> json) {
    _checkSchema(json, 'manifest');
    final packs = [
      for (final p in _list(json, 'packs', 'manifest'))
        QuestPackRef.fromJson(_asMap(p, 'manifest.packs entry')),
    ];
    final ids = packs.map((p) => p.id).toSet();
    if (ids.length != packs.length) {
      throw const FormatException('manifest has duplicate pack ids');
    }
    return QuestManifest(packs: packs);
  }
}

/// Short human description of a goal, for the stage-start banner.
String goalDescription(QuestGoal goal) => switch (goal) {
  ScoreGoal(target: final t) => 'Reach $t points',
  GemsGoal() => 'Collect the gems',
};

sealed class QuestGoal {
  const QuestGoal();

  factory QuestGoal.fromJson(Map<String, Object?> json, String where) {
    switch (json['type']) {
      case 'score':
        final target = json['target'];
        if (target is! int || target <= 0) {
          throw FormatException('$where: score goal needs target > 0');
        }
        return ScoreGoal(target);
      case 'gems':
        final counts = _asMap(json['counts'], '$where gems counts');
        if (counts.isEmpty) {
          throw FormatException('$where: gems goal needs counts');
        }
        return GemsGoal({
          for (final entry in counts.entries)
            _gemColor(entry.key, where): _positive(entry.value, where),
        });
      default:
        throw FormatException('$where: unknown goal type "${json['type']}"');
    }
  }
}

class ScoreGoal extends QuestGoal {
  const ScoreGoal(this.target);
  final int target;
}

class GemsGoal extends QuestGoal {
  const GemsGoal(this.counts);
  final Map<GemColor, int> counts;
}

class QuestStage {
  const QuestStage({
    required this.id,
    required this.board,
    required this.goal,
    required this.hard,
    this.seed,
    this.tray,
  });

  final String id;
  final Board board;
  final QuestGoal goal;
  final bool hard;

  /// Pinned piece-generator seed; null = random per attempt.
  final int? seed;

  /// Optional hand-designed opening tray (exactly 3 catalog piece ids).
  /// Stages use it so the very first moves can break the pre-placed
  /// blocks — the validator enforces that an opening clear exists.
  final List<String>? tray;

  factory QuestStage.fromJson(Map<String, Object?> json) {
    final id = _string(json, 'id', 'stage');
    final where = 'stage "$id"';
    final board = parseBoardRows([
      for (final row in _list(json, 'board', where)) row as String,
    ]);
    final seed = json['seed'];
    if (seed != null && seed is! int) {
      throw FormatException('$where: seed must be an int');
    }
    final hard = json['hard'] ?? false;
    if (hard is! bool) throw FormatException('$where: hard must be a bool');
    List<String>? tray;
    if (json['tray'] != null) {
      tray = [for (final t in _list(json, 'tray', where)) t as String];
      if (tray.length != 3) {
        throw FormatException('$where: tray must have exactly 3 pieces');
      }
      for (final pieceId in tray) {
        if (!pieceById.containsKey(pieceId)) {
          throw FormatException('$where: unknown tray piece "$pieceId"');
        }
      }
    }
    return QuestStage(
      id: id,
      board: board,
      goal: QuestGoal.fromJson(_asMap(json['goal'], '$where goal'), where),
      hard: hard,
      seed: seed as int?,
      tray: tray,
    );
  }
}

class QuestPack {
  const QuestPack({
    required this.id,
    required this.title,
    required this.stages,
  });

  final String id;
  final String title;
  final List<QuestStage> stages;

  factory QuestPack.fromJson(Map<String, Object?> json) {
    _checkSchema(json, 'pack');
    final id = _string(json, 'id', 'pack');
    final stages = [
      for (final s in _list(json, 'stages', 'pack "$id"'))
        QuestStage.fromJson(_asMap(s, 'pack "$id" stage entry')),
    ];
    if (stages.isEmpty) throw FormatException('pack "$id" has no stages');
    final ids = stages.map((s) => s.id).toSet();
    if (ids.length != stages.length) {
      throw FormatException('pack "$id" has duplicate stage ids');
    }
    return QuestPack(
      id: id,
      title: _string(json, 'title', 'pack'),
      stages: stages,
    );
  }
}

// --- strict-access helpers ---

void _checkSchema(Map<String, Object?> json, String where) {
  if (json['schema'] != questSchemaVersion) {
    throw FormatException(
      '$where: unsupported schema ${json['schema']} '
      '(expected $questSchemaVersion)',
    );
  }
}

String _string(Map<String, Object?> json, String key, String where) {
  final value = json[key];
  if (value is! String || value.isEmpty) {
    throw FormatException('$where: "$key" must be a non-empty string');
  }
  return value;
}

List<Object?> _list(Map<String, Object?> json, String key, String where) {
  final value = json[key];
  if (value is! List) throw FormatException('$where: "$key" must be a list');
  return value;
}

Map<String, Object?> _asMap(Object? value, String where) {
  if (value is! Map) throw FormatException('$where must be an object');
  return value.cast<String, Object?>();
}

GemColor _gemColor(String name, String where) {
  try {
    return GemColor.values.byName(name);
  } on ArgumentError {
    throw FormatException('$where: unknown gem color "$name"');
  }
}

int _positive(Object? value, String where) {
  if (value is! int || value <= 0) {
    throw FormatException('$where: gem counts must be positive ints');
  }
  return value;
}
