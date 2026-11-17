/// Content-level sanity checks shared by the validator CLI, the content
/// test, and (for downloaded packs) the quest service. Parsing strictness
/// lives in the models; these rules catch *playability* problems.
library;

import 'dart:convert';

import 'package:crypto/crypto.dart';

import '../models/piece_catalog.dart';
import '../models/quest.dart';
import '../systems/line_clear.dart';
import '../systems/solvability.dart';

String sha256Hex(List<int> bytes) => sha256.convert(bytes).toString();

/// Returns a list of human-readable problems; empty = valid.
List<String> validatePack(QuestPack pack) {
  final problems = <String>[];
  for (final stage in pack.stages) {
    final where = 'stage "${stage.id}"';

    // A legal board never contains an already-complete line.
    final clear = clearFullLines(stage.board);
    if (clear.lineCount > 0) {
      problems.add(
        '$where: board has pre-completed lines '
        '(rows ${clear.rows}, cols ${clear.cols})',
      );
    }

    final empty = stage.board.cells.where((c) => c == null).length;
    if (empty < 20) {
      problems.add('$where: only $empty empty cells — likely unplayable');
    }

    // Gems now ride on generated tray pieces (spawned only for colors
    // still needed), so a gem goal is satisfiable regardless of what's on
    // the board — only sanity-check the counts.
    if (stage.goal case GemsGoal(counts: final counts)) {
      counts.forEach((color, needed) {
        if (needed < 1 || needed > 60) {
          problems.add(
            '$where: gem goal for ${color.name} is $needed (want 1..60)',
          );
        }
      });
    }

    if (stage.goal case ScoreGoal(target: final target)) {
      if (target < 50 || target > 20000) {
        problems.add('$where: score target $target out of sane range');
      }
      // A score stage must not be winnable by the opening tray alone. If
      // the opening can all-clear, that +300 is included in the ceiling —
      // the target has to sit above it so real play is required.
      final tray = stage.tray;
      if (tray != null) {
        final pieces = [for (final id in tray) pieceById[id]!];
        final ceiling = maxOpeningScore(stage.board, pieces);
        if (target <= ceiling) {
          problems.add(
            '$where: score target $target ≤ opening ceiling $ceiling — the '
            'opening cascade (all-clear bonus included) would win the stage; '
            'raise the target above $ceiling',
          );
        }
      }
    }

    // Opening-cascade contract (strengthened 2026-07-14 after playtest
    // feedback): there must be an order in which ALL THREE tray pieces
    // fit into the designed board with EVERY placement breaking at
    // least one line. Leftover blocks are fine; a dud placement is not.
    final tray = stage.tray;
    if (tray != null) {
      final pieces = [for (final id in tray) pieceById[id]!];
      if (!openingCascadeExists(stage.board, pieces)) {
        problems.add(
          '$where: no full opening cascade — all three tray pieces must '
          'be placeable in some order with every placement clearing a '
          'line (design the board gaps to fit the tray)',
        );
      }
    }
  }
  return problems;
}

/// Parses manifest + packs from raw JSON strings and cross-checks
/// checksums. [packBytesByFile] maps each manifest `file` to its bytes.
List<String> validateContent(
  String manifestJson,
  Map<String, List<int>> packBytesByFile,
) {
  final problems = <String>[];
  final QuestManifest manifest;
  try {
    manifest = QuestManifest.fromJson(
      (jsonDecode(manifestJson) as Map).cast<String, Object?>(),
    );
  } on FormatException catch (e) {
    return ['manifest: ${e.message}'];
  }

  for (final ref in manifest.packs) {
    final bytes = packBytesByFile[ref.file];
    if (bytes == null) {
      problems.add('pack "${ref.id}": file ${ref.file} missing');
      continue;
    }
    final actual = sha256Hex(bytes);
    if (actual != ref.checksum) {
      problems.add(
        'pack "${ref.id}": checksum mismatch — manifest has '
        '"${ref.checksum}", file is "$actual"',
      );
    }
    try {
      final pack = QuestPack.fromJson(
        (jsonDecode(utf8.decode(bytes)) as Map).cast<String, Object?>(),
      );
      if (pack.id != ref.id) {
        problems.add('pack "${ref.id}": file declares id "${pack.id}" instead');
      }
      problems.addAll(validatePack(pack));
    } on FormatException catch (e) {
      problems.add('pack "${ref.id}": ${e.message}');
    }
  }
  return problems;
}
