import 'package:block_puzzle/models/board.dart';
import 'package:block_puzzle/models/cell.dart';
import 'package:block_puzzle/models/game_state.dart';
import 'package:block_puzzle/state/classic_game_controller.dart';
import 'package:block_puzzle/state/providers.dart';
import 'package:block_puzzle/ui/classic_screen.dart';
import 'package:block_puzzle/ui/combo_master_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A legal mid-game board (no full lines) where only (0,0) accepts the
/// tray's single; afterwards nothing fits: placing it ends the run.
GameState nearGameOverState() {
  const holes = {0, 9, 18, 27, 36, 45, 54, 63, 4, 32};
  return GameState(
    board: Board.fromCells([
      for (var i = 0; i < 64; i++) holes.contains(i) ? null : const Cell(1),
    ]),
    tray: const ['single', 'square3', 'line5h'],
    rngState: 1,
    score: 777,
    combo: 0,
    roundBestCombo: 5,
  );
}

void main() {
  testWidgets('game over pushes Combo Master; play again starts a new run', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    );
    addTearDown(container.dispose);

    final controller = container.read(classicGameProvider.notifier);
    controller.startNew(seed: 1);
    controller.debugLoadRun(nearGameOverState(), seed: 1);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: ClassicScreen()),
      ),
    );
    await tester.pump();
    expect(find.text('777'), findsOneWidget);

    // End the run through the controller (drag gestures are exercised on
    // the emulator; here we verify the screen flow reacts to game over).
    final outcome = controller.place(0, 0, 0);
    expect(outcome, isNotNull);
    expect(controller.isGameOver, isTrue);

    // Fixed pumps: pumpAndSettle never settles while the Flame game loop
    // is animating.
    await tester.pump(); // listener fires
    await tester.pump(const Duration(milliseconds: 950)); // effects delay
    await tester.pump(const Duration(milliseconds: 400)); // route animation
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.byType(ComboMasterScreen), findsOneWidget);
    expect(find.text('778'), findsOneWidget); // 777 + 1 cell
    // Fresh save: round best 5 became the all-time best too, so the text
    // appears in both stats.
    expect(find.text('Combo 5'), findsNWidgets(2));

    // Play again: back to the classic screen with a fresh run.
    await tester.tap(find.byIcon(Icons.play_arrow_rounded));
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byType(ComboMasterScreen), findsNothing);
    final fresh = container.read(classicGameProvider);
    expect(fresh, isNotNull);
    expect(fresh!.score, 0);
    expect(controller.isGameOver, isFalse);
  });
}
