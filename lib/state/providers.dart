import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/game_theme.dart';
import '../services/persistence_service.dart';
import 'save_data_notifier.dart';

/// Overridden with the real instance in main() before runApp.
final sharedPreferencesProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError('Override in main()'),
);

final persistenceProvider = Provider<PersistenceService>(
  (ref) => PersistenceService(ref.watch(sharedPreferencesProvider)),
);

final saveDataProvider = NotifierProvider<SaveDataNotifier, SaveData>(
  SaveDataNotifier.new,
);

final themeProvider = Provider<GameTheme>(
  (ref) => themeById(ref.watch(saveDataProvider).settings.themeId),
);
