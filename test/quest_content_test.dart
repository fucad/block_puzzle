import 'dart:io';

import 'package:block_puzzle/services/quest_validation.dart';
import 'package:flutter_test/flutter_test.dart';

/// Keeps the shipped content honest: `flutter test` fails if any pack in
/// content/quests/ is malformed, unplayable, or has a stale checksum.
void main() {
  test('repo quest content validates', () {
    final manifest = File('content/quests/manifest.json').readAsStringSync();
    final packs = <String, List<int>>{};
    for (final entity in Directory('content/quests/packs').listSync()) {
      if (entity is File && entity.path.endsWith('.json')) {
        final rel = 'packs/${entity.uri.pathSegments.last}';
        packs[rel] = entity.readAsBytesSync();
      }
    }
    expect(validateContent(manifest, packs), isEmpty);
  });
}
