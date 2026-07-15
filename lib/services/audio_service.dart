import 'package:audioplayers/audioplayers.dart';

import '../systems/game_engine.dart';

/// All sound effects. Every sound is synthesized in-repo
/// (tool/generate_audio.py) and shipped CC BY.
///
/// One player per distinct sound, each with its asset **preloaded once**
/// in [init] and replayed via seek+resume. Repeatedly calling
/// `play(AssetSource(...))` instead re-decodes the asset into Android's
/// SoundPool on every hit, which backs up and starts lagging after a few
/// hundred plays — the cause of the "sound gets choppy after a while"
/// report. Preloading keeps playback cheap and constant-cost.
class AudioService {
  static const _sounds = ['place', 'clear', 'combo', 'allclear', 'win', 'lose'];

  final Map<String, AudioPlayer> _players = {};
  bool enabled = true;
  bool _ready = false;

  Future<void> init() async {
    for (final name in _sounds) {
      final player = AudioPlayer();
      await player.setReleaseMode(ReleaseMode.stop);
      await player.setSource(AssetSource('audio/$name.wav'));
      await player.setVolume(0.9);
      _players[name] = player;
    }
    _ready = true;
  }

  void _play(String name) {
    if (!enabled || !_ready) return;
    final player = _players[name]!;
    // Fire and forget; restart from the top without re-decoding.
    player.seek(Duration.zero);
    player.resume();
  }

  /// One sound per placement, scaled to what it earned.
  void placement(PlacementEvents events) {
    if (events.allClear) {
      _play('allclear');
    } else if (events.combo >= 2) {
      _play('combo');
    } else if (events.linesCleared > 0) {
      _play('clear');
    } else {
      _play('place');
    }
  }

  void stageWon() => _play('win');

  void runEnded() => _play('lose');

  void dispose() {
    for (final player in _players.values) {
      player.dispose();
    }
  }
}
