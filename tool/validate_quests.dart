// ignore_for_file: avoid_print
// Quest content validator (see CONTRIBUTING_QUESTS.md).
//
//   dart run tool/validate_quests.dart            # check content/quests/
//   dart run tool/validate_quests.dart --update   # also fix checksums
import 'dart:convert';
import 'dart:io';

import 'package:block_puzzle/services/quest_validation.dart';

void main(List<String> args) {
  final update = args.contains('--update');
  final root = Directory('content/quests');
  final manifestFile = File('${root.path}/manifest.json');
  if (!manifestFile.existsSync()) {
    print('No ${manifestFile.path} found — run from the repo root.');
    exit(2);
  }

  var manifestJson = manifestFile.readAsStringSync();

  if (update) {
    final manifest = (jsonDecode(manifestJson) as Map).cast<String, Object?>();
    for (final packEntry in (manifest['packs'] as List)) {
      final pack = (packEntry as Map).cast<String, Object?>();
      final file = File('${root.path}/${pack['file']}');
      if (!file.existsSync()) continue;
      pack['checksum'] = sha256Hex(file.readAsBytesSync());
    }
    manifestJson = '${const JsonEncoder.withIndent('  ').convert(manifest)}\n';
    manifestFile.writeAsStringSync(manifestJson);
    print('Checksums updated.');
  }

  final packBytes = <String, List<int>>{};
  for (final packEntry in (jsonDecode(manifestJson) as Map)['packs'] as List) {
    final rel = ((packEntry as Map)['file'] ?? '') as String;
    final file = File('${root.path}/$rel');
    if (file.existsSync()) packBytes[rel] = file.readAsBytesSync();
  }

  final problems = validateContent(manifestJson, packBytes);
  if (problems.isEmpty) {
    print('OK: ${packBytes.length} pack(s) valid.');
  } else {
    problems.forEach(print);
    exit(1);
  }
}
