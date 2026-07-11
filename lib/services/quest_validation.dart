/// Content-level sanity checks shared by the validator CLI, the content
/// test, and (for downloaded packs) the quest service. Parsing strictness
/// lives in the models; these rules catch *playability* problems.
library;

import 'dart:convert';

import 'package:crypto/crypto.dart';

import '../models/cell.dart';
import '../models/quest.dart';
import '../systems/line_clear.dart';

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

    if (stage.goal case GemsGoal(counts: final counts)) {
      final onBoard = <GemColor, int>{};
      for (final cell in stage.board.cells) {
        final gem = cell?.gem;
        if (gem != null) onBoard[gem] = (onBoard[gem] ?? 0) + 1;
      }
      counts.forEach((color, needed) {
        final available = onBoard[color] ?? 0;
        if (available < needed) {
          problems.add(
            '$where: goal needs $needed ${color.name} gems but the board '
            'only has $available',
          );
        }
      });
    }

    if (stage.goal case ScoreGoal(target: final target)) {
      if (target < 50 || target > 20000) {
        problems.add('$where: score target $target out of sane range');
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
