import 'dart:convert';
import 'dart:io';

import 'package:block_puzzle/services/quest_service.dart';
import 'package:block_puzzle/services/quest_validation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Serves the real repo content/quests/ files as the "bundled assets".
Future<String?> repoBundle(String path) async {
  final file = File('content/quests/$path');
  return file.existsSync() ? file.readAsString() : null;
}

Future<QuestService> makeService({
  Map<String, Object> initialPrefs = const {},
  Fetcher? fetcher,
  BundleLoader? bundle,
}) async {
  SharedPreferences.setMockInitialValues(initialPrefs);
  final prefs = await SharedPreferences.getInstance();
  return QuestService(
    prefs: prefs,
    bundleLoader: bundle ?? repoBundle,
    fetcher: fetcher ?? (_) async => null,
  );
}

/// A tiny valid pack + manifest pair for fetch scenarios.
const _packBody = '''
{
  "schema": 1, "id": "extra", "title": "Extra",
  "stages": [{
    "id": "e1",
    "board": ["........","........","........","........",
              "........","........","3r33.r33","333.3333"],
    "goal": {"type": "gems", "counts": {"red": 2}}
  }]
}''';

String manifestWith(List<Map<String, Object>> packs) =>
    jsonEncode({'schema': 1, 'packs': packs});

Map<String, Object> extraRef({String date = '2026-07-01'}) => {
  'id': 'extra',
  'title': 'Extra',
  'release_date': date,
  'file': 'packs/extra.json',
  'checksum': sha256Hex(utf8.encode(_packBody)),
};

final now = DateTime.utc(2026, 7, 12);

void main() {
  test('offline first launch: bundled starter pack is playable', () async {
    final service = await makeService();
    final catalog = await service.loadCatalog(now);
    expect(catalog.playable.map((p) => p.id), ['starter']);
    expect(catalog.playable.single.stages, hasLength(15));
    expect(catalog.nextUpcoming, isNull);
  });

  test('refresh downloads, verifies, and caches a new released pack', () async {
    final urls = <String>[];
    final service = await makeService(
      fetcher: (uri) async {
        urls.add(uri.path);
        if (uri.path.endsWith('manifest.json')) {
          return manifestWith([extraRef()]);
        }
        if (uri.path.endsWith('packs/extra.json')) return _packBody;
        return null;
      },
    );
    expect(await service.refresh(now), isTrue);
    final catalog = await service.loadCatalog(now);
    expect(catalog.playable.map((p) => p.id), ['extra']);
    expect(urls.any((u) => u.contains('fucad/block_puzzle')), isTrue);
  });

  test('a pack with a bad checksum is rejected', () async {
    final ref = extraRef()..['checksum'] = 'deadbeef';
    final service = await makeService(
      fetcher: (uri) async =>
          uri.path.endsWith('manifest.json') ? manifestWith([ref]) : _packBody,
    );
    await service.refresh(now);
    final catalog = await service.loadCatalog(now);
    expect(
      catalog.playable,
      isEmpty,
    ); // bundled starter absent from new manifest
  });

  test(
    'future packs are pre-cached but not playable; badge sees them',
    () async {
      var packFetches = 0;
      final service = await makeService(
        fetcher: (uri) async {
          if (uri.path.endsWith('manifest.json')) {
            return manifestWith([extraRef(date: '2026-07-20')]);
          }
          packFetches++;
          return _packBody;
        },
      );
      await service.refresh(now);
      expect(packFetches, 1); // pre-cached
      final catalog = await service.loadCatalog(now);
      expect(catalog.playable, isEmpty);
      expect(catalog.nextUpcoming!.id, 'extra');
      expect(catalog.nextUpcoming!.releaseDate, DateTime.utc(2026, 7, 20));

      // ...and on release day it plays from cache with no further network.
      final later = await service.loadCatalog(DateTime.utc(2026, 7, 20));
      expect(later.playable.map((p) => p.id), ['extra']);
    },
  );

  test(
    'network failure and corrupt cached manifest degrade gracefully',
    () async {
      final service = await makeService(
        initialPrefs: {'quest_manifest': '{not json'},
      );
      expect(await service.refresh(now), isFalse);
      final catalog = await service.loadCatalog(now);
      expect(catalog.playable.map((p) => p.id), [
        'starter',
      ]); // bundled fallback
    },
  );
}
