# SCREENSHOTS.md — regenerating store art

Two reproducible steps, no touch-driving needed.

1. **Raw captures** (iOS simulator, 1320×2868):
   ```sh
   tool/capture_screenshots.sh                 # all scenes
   SCENES="classic gems" tool/capture_screenshots.sh   # a subset
   ```
   Builds a debug simulator app per scene with `--dart-define=SHOT=<scene>`.
   `lib/dev/screenshot_mode.dart` seeds a deterministic save (classic
   board from seed 125, 19 quest levels done, sample lifetime stats, quest
   fetch disabled) and opens straight onto the scene: `menu`, `classic`,
   `map`, `gems` (starter s09 after its opening cascade), `stats`.
   The status bar is pinned to 9:41 / full battery. Output: `docs/store/raw/`.
   Normal builds never set `SHOT`, so the mode is inert in release.

2. **Framed store images** (captions EN + KO):
   ```sh
   python3 -m venv .venv && .venv/bin/pip install pillow
   .venv/bin/python tool/compose_store_art.py
   ```
   Writes `docs/store/ios/{en,ko}/` (1320×2868, App Store 6.9"),
   `docs/store/play/{en,ko}/` (1080×1920, Play phone),
   `docs/store/play/feature_graphic.png` (1024×500) and
   `docs/store/play/icon_512.png`. Captions live in the `SHOTS` table at
   the top of the script.

When the UI changes, rerun both steps and commit the PNGs.
