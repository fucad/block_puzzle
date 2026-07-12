import 'dart:convert';
import 'dart:io';

import 'package:block_puzzle/models/quest.dart';
import 'package:block_puzzle/services/quest_service.dart';
import 'package:block_puzzle/state/providers.dart';
import 'package:block_puzzle/state/quest_providers.dart';
import 'package:block_puzzle/state/classic_game_controller.dart';
import 'package:block_puzzle/ui/run_summary_screen.dart';
import 'package:block_puzzle/ui/main_menu_screen.dart';
import 'package:block_puzzle/ui/quest_map_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Layout-regression goldens for the static screens (fonts render as the
/// test-default Ahem boxes; that's expected and stable). Regenerate after
/// intentional UI changes:  flutter test --update-goldens test/golden_test.dart
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<Widget> app(
    Widget home, {
    Map<String, Object> prefsInit = const {},
  }) async {
    SharedPreferences.setMockInitialValues(prefsInit);
    final prefs = await SharedPreferences.getInstance();
    final starter = QuestPack.fromJson(
      (jsonDecode(File('content/quests/packs/starter.json').readAsStringSync())
              as Map)
          .cast<String, Object?>(),
    );
    return ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        questCatalogProvider.overrideWith(
          (ref) async => QuestCatalog(playable: [starter], nextUpcoming: null),
        ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(useMaterial3: true, brightness: Brightness.dark),
        home: home,
      ),
    );
  }

  testWidgets('main menu golden', (tester) async {
    await tester.binding.setSurfaceSize(const Size(392, 807));
    await tester.pumpWidget(await app(const MainMenuScreen()));
    await tester.pump(const Duration(milliseconds: 100));
    await expectLater(
      find.byType(MainMenuScreen),
      matchesGoldenFile('goldens/main_menu.png'),
    );
  });

  testWidgets('quest map golden (levels 1-2 done, 3 current)', (tester) async {
    await tester.binding.setSurfaceSize(const Size(392, 807));
    await tester.pumpWidget(
      await app(
        const QuestMapScreen(),
        prefsInit: {
          'save':
              '{"version":1,"settings":{},"classicHighScore":0,'
              '"allTimeBestCombo":0,"classicRun":null,"classicRunSeed":null,'
              '"questCompleted":{"starter":["s01","s02"]},'
              '"lastQuestFetchEpochMs":null}',
        },
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));
    await expectLater(
      find.byType(QuestMapScreen),
      matchesGoldenFile('goldens/quest_map.png'),
    );
  });

  testWidgets('run summary golden (Try Again variant)', (tester) async {
    await tester.binding.setSurfaceSize(const Size(392, 807));
    await tester.pumpWidget(
      await app(
        const RunSummaryScreen(
          summary: RunSummary(
            score: 1234,
            bestCombo: 7,
            allClears: 1,
            newHighScore: false,
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));
    await expectLater(
      find.byType(RunSummaryScreen),
      matchesGoldenFile('goldens/run_summary.png'),
    );
  });
}
