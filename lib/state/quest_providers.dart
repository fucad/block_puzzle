import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/quest_config.dart';
import '../services/quest_service.dart';
import 'providers.dart';

/// The level number (1-based) just completed, set on the Level Complete
/// screen and consumed once by the map to animate the advance to the next
/// stage. Null when there's nothing to animate.
class QuestJustCompleted extends Notifier<int?> {
  @override
  int? build() => null;
  void set(int? value) => state = value;
}

final questJustCompletedProvider = NotifierProvider<QuestJustCompleted, int?>(
  QuestJustCompleted.new,
);

final questServiceProvider = Provider<QuestService>(
  (ref) => QuestService(
    prefs: ref.watch(sharedPreferencesProvider),
    bundleLoader: (path) async {
      try {
        return await rootBundle.loadString('content/quests/$path');
      } on Exception {
        return null;
      }
    },
  ),
);

/// Bundled + cached packs, immediately. If a network refresh is due it
/// runs in the background and re-resolves this provider when new content
/// actually landed — the UI never waits on the network.
final questCatalogProvider = FutureProvider<QuestCatalog>((ref) async {
  final service = ref.watch(questServiceProvider);
  final now = DateTime.now().toUtc();

  final lastFetchMs = ref.read(saveDataProvider).lastQuestFetchEpochMs;
  final due =
      lastFetchMs == null ||
      now.millisecondsSinceEpoch - lastFetchMs >
          questRefreshInterval.inMilliseconds;
  if (due) {
    // Fire and forget; throttle is stamped even on failure so a dead
    // network isn't retried on every app open.
    Future(() async {
      final fetched = await service.refresh(now);
      ref
          .read(saveDataProvider.notifier)
          .markQuestFetch(now.millisecondsSinceEpoch);
      if (fetched) ref.invalidateSelf();
    });
  }

  return service.loadCatalog(now);
});
