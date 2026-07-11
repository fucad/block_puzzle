import 'game_constants.dart';

/// Score for clearing [lines] lines in a single placement:
/// `lineClearBase * n * (n + 1) / 2` — 10, 30, 60, 100...
int lineScore(int lines) => lineClearBase * lines * (lines + 1) ~/ 2;

/// Bonus for a clearing placement at combo level [combo] (the level AFTER
/// incrementing; first clear of a streak is combo 1 and earns no bonus).
int comboBonus(int combo) => combo >= 2 ? comboBonusPerLevel * (combo - 1) : 0;
