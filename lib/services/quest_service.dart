import 'dart:convert';

import 'package:flutter/foundation.dart' show debugPrint, kDebugMode;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/quest.dart';
import 'quest_config.dart';
import 'quest_validation.dart';

/// What the rest of the app consumes: released+parsed packs in manifest
/// order, plus the next unreleased pack for the menu countdown.
class QuestCatalog {
  const QuestCatalog({required this.playable, required this.nextUpcoming});

  final List<QuestPack> playable;
  final QuestPackRef? nextUpcoming;
}

typedef Fetcher = Future<String?> Function(Uri uri);
typedef BundleLoader = Future<String?> Function(String relativePath);

/// GitHub-as-backend quest content:
/// - bundled assets make first launch fully offline,
/// - [refresh] fetches the manifest + missing packs (sha256-verified) into
///   SharedPreferences, keyed by checksum (content-addressed),
/// - [loadCatalog] merges: freshest manifest wins, cache beats bundle,
///   anything unreleased or unverifiable is simply not playable yet.
/// Every network failure degrades silently to bundled + cached content.
class QuestService {
  QuestService({
    required this.prefs,
    required this.bundleLoader,
    Fetcher? fetcher,
  }) : fetcher = fetcher ?? _httpFetcher;

  final SharedPreferences prefs;
  final BundleLoader bundleLoader;
  final Fetcher fetcher;

  static const _manifestKey = 'quest_manifest';
  static String _packKey(String checksum) => 'quest_pack_$checksum';

  // Failures degrade silently for players, but say why in debug builds —
  // a swallowed reason cost real diagnosis time once already.
  static Future<String?> _httpFetcher(Uri uri) async {
    try {
      final response = await http.get(uri).timeout(questFetchTimeout);
      if (response.statusCode != 200) {
        if (kDebugMode) {
          debugPrint('quest fetch $uri -> ${response.statusCode}');
        }
        return null;
      }
      return response.body;
    } on Exception catch (e) {
      if (kDebugMode) debugPrint('quest fetch $uri failed: $e');
      return null;
    }
  }

  QuestManifest? _parseManifest(String? json) {
    if (json == null) return null;
    try {
      return QuestManifest.fromJson(
        (jsonDecode(json) as Map).cast<String, Object?>(),
      );
    } on Exception {
      return null;
    }
  }

  Future<QuestManifest?> _bestManifest() async =>
      _parseManifest(prefs.getString(_manifestKey)) ??
      _parseManifest(await bundleLoader('manifest.json'));

  Future<QuestCatalog> loadCatalog(DateTime nowUtc) async {
    final manifest = await _bestManifest();
    if (manifest == null) {
      return const QuestCatalog(playable: [], nextUpcoming: null);
    }

    final playable = <QuestPack>[];
    for (final ref in manifest.packs.where((r) => r.releasedBy(nowUtc))) {
      // Cache first: a fetched pack is newer than the installed bundle.
      var body = prefs.getString(_packKey(ref.checksum));
      body ??= await bundleLoader(ref.file);
      if (body == null) continue;
      try {
        playable.add(
          QuestPack.fromJson((jsonDecode(body) as Map).cast<String, Object?>()),
        );
      } on Exception {
        continue; // an unparseable pack is just unavailable
      }
    }

    final upcoming = manifest.packs.where((r) => !r.releasedBy(nowUtc)).toList()
      ..sort((a, b) => a.releaseDate.compareTo(b.releaseDate));
    return QuestCatalog(playable: playable, nextUpcoming: upcoming.firstOrNull);
  }

  /// Fetches the manifest and downloads released packs that are missing
  /// from the cache, plus pre-caches the next upcoming pack. Returns true
  /// if the manifest was fetched (used to stamp the throttle time).
  Future<bool> refresh(DateTime nowUtc) async {
    final manifestBody = await fetcher(
      Uri.parse('$questContentBaseUrl/manifest.json'),
    );
    final manifest = _parseManifest(manifestBody);
    if (manifest == null) return false;
    await prefs.setString(_manifestKey, manifestBody!);

    final upcoming = manifest.packs.where((r) => !r.releasedBy(nowUtc)).toList()
      ..sort((a, b) => a.releaseDate.compareTo(b.releaseDate));
    final wanted = [
      ...manifest.packs.where((r) => r.releasedBy(nowUtc)),
      if (upcoming.isNotEmpty) upcoming.first,
    ];

    for (final ref in wanted) {
      if (prefs.containsKey(_packKey(ref.checksum))) continue;
      // If the installed bundle already has this exact content, skip.
      final bundled = await bundleLoader(ref.file);
      if (bundled != null && sha256Hex(utf8.encode(bundled)) == ref.checksum) {
        continue;
      }
      final body = await fetcher(Uri.parse('$questContentBaseUrl/${ref.file}'));
      if (body == null) continue;
      if (sha256Hex(utf8.encode(body)) != ref.checksum) continue;
      try {
        final pack = QuestPack.fromJson(
          (jsonDecode(body) as Map).cast<String, Object?>(),
        );
        if (validatePack(pack).isNotEmpty) continue;
      } on Exception {
        continue;
      }
      await prefs.setString(_packKey(ref.checksum), body);
    }
    return true;
  }
}
