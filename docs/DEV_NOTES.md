# DEV_NOTES.md — local dev & on-device verification recipes

Practical notes for iterating on this repo (AI-assisted sessions included).

## Toolchain quirks (this machine)

- `android/app/build.gradle.kts` pins `ndkVersion = "27.0.12077973"`
  because the 28.2 NDK under `~/Library/Android/sdk/ndk/` is a corrupt,
  empty download. The Gradle warning recommending 28.2 is safe to ignore
  (or delete that dir to let AGP re-download and restore the default).
- No iOS simulator runtimes are installed; use the Android emulator
  `Pixel_3a_API_33_arm64-v8a` (`flutter emulators --launch ...`).

## Deterministic runs

- `flutter run --dart-define=SEED=<n>` pins every new classic run to that
  seed (0/unset = random). Combined with:
- `dart run tool/simulate.dart <seed> [slot,row,col ...]` — replays the
  same run headlessly, printing tray/board/score per move. Plan on-device
  move sequences here first; the device matches move for move.
- Useful seeds: `42` → first tray [line3v, corner3sw, corner3ne];
  `125` → [line3h, line5h, rect3x2] (line5h at 7,0 + line3h at 7,5 makes
  a full bottom row AND an all-clear in two moves — fastest way to see
  clear effects + ALL CLEAR popup + confetti).

## Driving the emulator (Pixel 3a, 1080×2220, dpr 2.75)

- Screenshot: `adb exec-out screencap -p > shot.png`
  (downscale for viewing: `sips -Z 1200 shot.png --out small.png`).
- Layout math for drop coordinates (debug build, current HUD):
  - board origin ≈ logical (12, 167); cell ≈ 46.1 logical; px = logical × 2.75.
  - tray slot centers ≈ px (180, 1830), (540, 1830), (900, 1830).
  - a dragged piece floats 1.6 cells above the finger, so to drop a piece
    with bounding-box top-left at (row, col):
    `finger_logical = (12 + (col + w/2)·46.1, 167 + (row + h/2)·46.1 + 73.7)`
  - drag: `adb shell input swipe x1 y1 x2 y2 700` (use 2000–3000 ms and
    screenshot mid-swipe to inspect ghost/would-clear glow).
- Fresh install state: `adb shell pm clear games.adfree.block_puzzle`.
- Resume-after-kill test: `adb shell am force-stop ...` then
  `am start -n games.adfree.block_puzzle/.MainActivity`.

## Widget tests + Flame

`pumpAndSettle` never settles while a GameWidget is mounted (the game
loop animates forever) — use fixed-duration `pump`s (see
test/classic_flow_test.dart).
