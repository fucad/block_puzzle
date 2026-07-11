/// Deterministic PRNG for piece generation.
///
/// Hand-rolled xorshift64* seeded through one splitmix64 round instead of
/// `dart:math` [Random], so sequences are stable across Dart versions and the
/// 64-bit state can be persisted to resume a run mid-tray. Relies on native
/// 64-bit int wrapping — VM (Android/iOS) only, not web-safe.
class GameRng {
  GameRng(int seed) : _state = _mix(seed) {
    // xorshift has a fixed point at 0; splitmix64 maps exactly one seed there.
    if (_state == 0) _state = 0x9E3779B97F4A7C15;
  }

  GameRng.fromState(int state) : _state = state == 0 ? 1 : state;

  int _state;

  /// Serializable state; restore with [GameRng.fromState].
  int get state => _state;

  static int _mix(int seed) {
    var z = seed + 0x9E3779B97F4A7C15;
    z = (z ^ (z >>> 30)) * 0xBF58476D1CE4E5B9;
    z = (z ^ (z >>> 27)) * 0x94D049BB133111EB;
    return z ^ (z >>> 31);
  }

  int _next() {
    var x = _state;
    x ^= x >>> 12;
    x ^= x << 25;
    x ^= x >>> 27;
    _state = x;
    return x * 0x2545F4914F6CDD1D;
  }

  /// Uniform double in [0, 1).
  double nextDouble() => (_next() >>> 11) * (1.0 / (1 << 53));

  /// Uniform int in [0, max).
  int nextInt(int max) => (nextDouble() * max).floor();
}
