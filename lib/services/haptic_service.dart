import 'package:flutter/services.dart';
import 'package:vibration/vibration.dart';

import '../systems/game_engine.dart';

/// Which built-in level to fall back to when explicit vibration is
/// unavailable.
enum _Level { selection, medium, heavy }

/// Gameplay haptics with real, felt strength. Flutter's built-in
/// [HapticFeedback] impacts route through Android's touch-feedback path,
/// which many phones (notably Samsung) render too weak to notice — so
/// when the device has an amplitude-controlled vibrator we drive explicit
/// duration+amplitude pulses instead, falling back to HapticFeedback only
/// where that isn't available.
class HapticService {
  bool enabled = true;

  bool _probed = false;
  bool _hasVibrator = false;
  bool _hasAmplitude = false;

  Future<void> init() async {
    _hasVibrator = await Vibration.hasVibrator();
    _hasAmplitude = _hasVibrator && await Vibration.hasAmplitudeControl();
    _probed = true;
  }

  bool get _canVibrate => enabled && _probed && _hasVibrator;

  void _pulse(int ms, int amplitude, _Level fallback) {
    if (!enabled) return;
    if (!_canVibrate) {
      _fallback(fallback);
      return;
    }
    if (_hasAmplitude) {
      Vibration.vibrate(duration: ms, amplitude: amplitude);
    } else {
      // No amplitude control: duration alone still conveys intensity.
      Vibration.vibrate(duration: ms);
    }
  }

  void _fallback(_Level level) {
    switch (level) {
      case _Level.selection:
        HapticFeedback.selectionClick();
      case _Level.medium:
        HapticFeedback.mediumImpact();
      case _Level.heavy:
        HapticFeedback.heavyImpact();
    }
  }

  /// A tray piece was grabbed.
  void pickup() => _pulse(12, 90, _Level.selection);

  /// One placement, scaled to what it earned.
  void placement(PlacementEvents events) {
    if (events.allClear) {
      _canVibrate
          ? Vibration.vibrate(pattern: [0, 60, 50, 60, 50, 120])
          : _fallback(_Level.heavy);
    } else if (events.linesCleared >= 2 || events.combo >= 2) {
      _pulse(45, 255, _Level.heavy);
    } else if (events.linesCleared == 1) {
      _pulse(30, 200, _Level.heavy);
    } else {
      _pulse(18, 140, _Level.medium);
    }
  }

  void stageWon() {
    _canVibrate
        ? Vibration.vibrate(pattern: [0, 50, 40, 90])
        : _fallback(_Level.heavy);
  }
}
