import 'package:audioplayers/audioplayers.dart';

import '../systems/game_engine.dart';

/// All sound effects. Fire-and-forget, never blocks gameplay; every sound
/// is synthesized in-repo (tool/generate_audio.py) and shipped CC BY.
class AudioService {
  AudioService() {
    // A small pool so rapid placements don't cut each other off.
    _players = List.generate(3, (_) {
      final p = AudioPlayer();
      p.setPlayerMode(PlayerMode.lowLatency);
      return p;
    });
  }

  late final List<AudioPlayer> _players;
  var _next = 0;

  /// Master switch, mirrored from Settings by the state layer.
  bool enabled = true;

  void _play(String file) {
    if (!enabled) return;
    final player = _players[_next];
    _next = (_next + 1) % _players.length;
    // Ignore failures (e.g. a player still busy); sound is best-effort.
    player.play(AssetSource('audio/$file')).catchError((_) {});
  }

  /// One sound per placement, scaled to what it earned.
  void placement(PlacementEvents events) {
    if (events.allClear) {
      _play('allclear.wav');
    } else if (events.combo >= 2) {
      _play('combo.wav');
    } else if (events.linesCleared > 0) {
      _play('clear.wav');
    } else {
      _play('place.wav');
    }
  }

  void stageWon() => _play('win.wav');

  void runEnded() => _play('lose.wav');

  void dispose() {
    for (final p in _players) {
      p.dispose();
    }
  }
}
