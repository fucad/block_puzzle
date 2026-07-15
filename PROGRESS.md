# PROGRESS.md — Block Puzzle

Single source of truth for the build. Read this first, every session. Continue
from the first unchecked `[ ]`. `[~]` = in progress. Mark `[x]` only after
built AND verified (format/analyze clean, tests pass, observed working on a
device/simulator).

## M0 — Skeleton & decisions

- [x] Flutter project scaffold in repo, analyze/format/test CI-able locally
- [x] Decision: Flame vs plain Flutter → **Flame** (user's choice, 2026-07-11)
- [x] Decision: state management → **Riverpod** (user's choice, 2026-07-11)
- [x] ARCHITECTURE.md initial draft; folder structure in place

## M1 — Core engine (pure Dart, fully tested, no UI)

- [x] Board model, piece definitions (data-driven set, 29 pieces)
- [x] Placement legality + line-clear detection (rows & columns, simultaneous)
- [x] Scoring + combo + all-clear rules as pure functions, constants in one file
- [x] Seeded piece generator with fit-weighting; determinism test
- [x] Game-over detection
- [x] Save-data model v1 + serialization round-trip tests; SAVE_MODEL.md

## M2 — Classic mode playable

- [x] Board rendering + drag-and-drop with ghost preview and would-clear
      highlight (verified on emulator incl. mid-drag glow screenshot)
- [x] Tray of 3, refill logic
- [x] Line-clear / multi-line / all-clear effects (clear + ALL CLEAR +300
      popup + confetti verified on device 2026-07-11; frame-rate profile
      pass happens with M4's perf pass)
- [x] Combo popups + praise text + board glow (same code path as the
      verified ALL CLEAR popup; glow/praise appear during normal play)
- [x] Score HUD, high score persistence, game over → Combo Master summary → retry
      (flow covered by widget test classic_flow_test.dart; settings sheet
      with sound/haptics/reset/about wired from the classic HUD gear)
- [x] Resume in-progress classic run after app kill (verified via force-stop)

## NEXT SESSION — resume here

ALL MILESTONES M0–M4 are done except the user-side release checklist
above (keystore, iOS SDK install, store art, repo push). Good follow-ups
when development resumes: a second theme (wood — proves the picker),
lose-screen/80%-banner visual eyeballing during play, a CI workflow
(analyze+test+content validation), and store screenshots.

## M3 — Quest mode

- [x] Quest JSON schema + strict parser + validator CLI/test
      (tool/validate_quests.dart, --update fixes checksums;
      quest_content_test keeps shipped content green)
- [x] Bundled starter pack (15 stages, score+gem goals, 4 hard, 2 pinned
      seeds; ships as assets straight from content/quests/)
- [x] Stage play: pre-placed boards, gem collection, progress UI
      (gem stage s03 + score stage s04 verified on emulator; 80% banner
      built — visual check happens in normal play)
- [x] Win/lose screens; quest map screen with path, hard nodes, progression
      (win flow + map advance verified on device; "So Close!" lose screen
      controller-tested, visual pending normal play)
- [x] GitHub fetch + cache + release-date gating + checksum verify +
      offline fallback (unit-tested with fake fetchers; real fetch 404s
      harmlessly until the repo is pushed)
- [x] Main-menu countdown badge (unit-tested; invisible now — correct,
      since no unreleased pack exists in the manifest yet)

## M4 — Polish & release prep

- [x] Main menu, settings (sound/haptics/reset/about+licenses; the theme
      picker appears automatically once a second GameTheme is added)
- [x] Audio (synthesized in-repo → original CC BY; verified via logcat),
      haptics (light/medium by placement outcome)
- [x] Theme system seam + default theme polish (GameTheme is pure data;
      contributing a skin = one const object)
- [x] Golden tests for menu/map/Combo Master (caught a real overflow);
      perf pass: release APK on emulator, zero Choreographer jank across
      effect-heavy play — real low-end hardware pass deferred (none attached)
- [x] App icon (rendered in-repo by test/tools/render_icon_test.dart,
      adaptive + iOS via flutter_launcher_icons), store copy drafted
      (docs/STORE_LISTING.md), README/CONTRIBUTING/PURPOSE complete
- [~] Release builds: Android verified (aab 50.2MB + apk, release mode
      played on emulator). iOS blocked by local toolchain: Xcode lacks
      the iOS platform SDK (install via Xcode ▸ Settings ▸ Components,
      then `flutter build ios --release --no-codesign`)

## Release checklist (user-side, never in repo)

- [ ] Android upload keystore + key.properties (secrets — keep local)
- [ ] Install iOS platform SDK in Xcode; build + archive
- [ ] Store screenshots + Play feature graphic (docs/STORE_LISTING.md)
- [ ] Push repo to github.com/fucad/block_puzzle (activates quest fetch)
- [ ] Real low-end device perf sanity check

## Deferred work

(none yet — list items here with reason instead of dropping them)

## Decisions log

### 2026-07-11 — Project start
- Repo was empty except LICENSE (MIT). Created PROGRESS.md from the build
  prompt's milestone plan.
- Toolchain: Flutter 3.44.1 stable / Dart 3.12.1 (installed locally).
- Scaffolded with `flutter create --empty --platforms android,ios`,
  org `games.adfree`. Portrait-only, Android + iOS (low-stakes default,
  per prompt).

### 2026-07-11 — M0 decisions (user chose via decision fork)
- **Rendering: Flame** (over plain Flutter / hybrid). Rationale: project
  convention (PURPOSE.md stack is Flutter + Flame across all games) and
  Flame's particle/effects APIs for the heavy line-clear/combo effects.
  Cost accepted: gesture bridging between the Flutter tray and the Flame
  board in M2. Deps: flame ^1.37.0.
- **State management: Riverpod** (flutter_riverpod ^3.3.2) for app/meta
  state only; the game core stays pure Dart with no Riverpod imports.
- **Combo rule: immediate reset** — a placement that clears nothing resets
  the streak to 0. Simplest to understand, test, and communicate.

### 2026-07-11 — M1 core engine
- RNG is a hand-rolled xorshift64* (splitmix64 seeding), NOT dart:math
  Random: sequences must stay stable across Dart upgrades (saved runs and
  pinned quest seeds depend on them) and the state must serialize. Golden
  test locks the sequence; VM-only (int64 wrapping), fine for mobile-only.
- Scoring formulas: line score `10·n(n+1)/2`, combo bonus `10·(combo−1)`
  on each clearing placement, all-clear +300, +1/cell placed. All in
  `lib/systems/game_constants.dart` + `scoring.dart`, tunable.
- Piece-gen deviation from the original plan: the "redraw up to 8 times on
  a dead tray" guarantee was statistically meaningless in the worst case
  (only the rare `single` fits → ~47% dead trays remained). Changed to:
  redraw the last slot from the *fitting pieces only*. A fresh tray is now
  always playable when any piece fits; game overs happen mid-tray. Found
  by the generator test, ARCHITECTURE.md updated to match.
- 64-bit ints (rngState, seed) serialize as strings in the save JSON to
  survive tooling that round-trips numbers through doubles (SAVE_MODEL.md).
- Verified: `dart format` clean, `flutter analyze` 0 issues, 37/37 tests
  pass (placement, clears incl. simultaneous row+col+gems, scoring, combo
  incl. all-clear interaction, generator determinism + fit bias, engine
  determinism over 60 greedy moves, save round-trips). No simulator run —
  M1 is pure logic with no UI; first device verification lands with M2.
- Nothing committed yet (commit only when asked).

### 2026-07-11 — M2 slice A/B (state layer + Flame play area)
- User directive: commit frequently after each verified chunk; no pushing.
  Working on branch `dev` off main.
- Persistence: single JSON document in shared_preferences. A save that
  fails to parse (corruption or future schema) is copied to a quarantine
  key and defaults are used — never silently clobbered.
- Flame layer design: components are added directly to the FlameGame root
  (no camera/world), so canvas coords == widget pixels; geometry math is
  a pure class (BoardGeometry). BoardComponent renders straight from the
  engine GameState each frame; TrayPieceComponent handles dragging (piece
  floats 1.6 cells above the finger at full board scale, per reference
  UX). Rules never enter the Flame layer; placements round-trip through
  ClassicGameController and state flows back via ref.listen → syncState.
- Toolchain fix: local NDK 28.2 download was corrupt (empty dir), so
  android/app pins ndkVersion to the intact 27.0.12077973.

### 2026-07-11 — M2 slice C/D (effects + summary/settings), session end
- Effects layer (lib/game/effects.dart): per-cell bursts + line sweeps,
  praise ladder (Good!→Unbelievable!), Combo N / ALL CLEAR popups,
  confetti, and a combo glow frame (gold ≥3, rainbow ≥6) — visual tuning
  constants live there, rule constants stay in game_constants.dart.
- Verified on emulator with SEED=42: offline sim (tool/simulate.dart)
  matched the device move for move; would-clear glow + row clear + score
  confirmed by screenshot. Particle/popup visuals still pending (timing;
  see NEXT SESSION).
- Combo Master summary replaces the placeholder dialog (game over →
  900ms effects grace → summary → play again/menu), settings sheet
  (sound/haptics toggles persisted, reset-progress with confirm, about).
  Flow covered by a widget test; note: pumpAndSettle hangs with a live
  GameWidget, use fixed pumps.
- Emulator/adb verification recipes captured in docs/DEV_NOTES.md.
- Session ended mid slice-D device verification at user request; all
  code committed on `dev`, working tree clean, 43/43 tests green.

### 2026-07-16 — Playtest round 5: 7 polish items
- Ghost dial-back: nearest-legal snap capped to a 1-cell radius (catches
  grid-line straddling, no longer teleports onto far gaps; over occupied
  blocks it bounces).
- Would-clear line lights up in the dragged piece's color with a bright
  glow (was a small yellow tint) — matches the reference.
- Falling-block + gem effects: cleared cells drop a short distance and
  fade; gem cells instead fly up toward the goal counters. Uses the new
  PlacementOutcome.stampedBoard (pre-clear colors).
- Random tiered combo praise ("Good!" → "Legendary!"), shown above the
  action; the winning praise is reused (animated) on Level Complete.
- Quest goal banner: centered, animated, at stage start.
- Restart round: a Settings action (classic restarts the run, quest
  retries the stage) — classic runs are otherwise persistent.
- Map advance animation: on Continue, the trail fills from the cleared
  node to the next, which then lights up (questJustCompletedProvider +
  fractional _TrailPainter.litUpTo + AnimationController).

### 2026-07-15 — Playtest round 4: preview, quest colors, classic clears
- Ghost preview: over the board it now ALWAYS shows a pre-place, snapping
  to the nearest legal cell (forgiving placement); the drop lands there.
  Return-to-tray only happens when released off the board. Over-board-but-
  no-fit shows a red invalid ghost.
- Quest visual: pre-placed puzzle blocks AND gem cells now render in one
  neutral light tile (Cell.preplaced flag; puzzleBlockLight), so the
  puzzle reads as a unit and the player's vivid pieces stand out (per the
  reference image). Player-placed cells keep palette colors.
- Classic clears much easier: GameState.clearFocus threads a mode flag to
  the generator — breakers boosted ~9×, open boards favor big/long pieces
  for multi-line clears + all-clears, and the deal keeps the set with the
  best clearingPotential. Quest keeps its balance. Deterministic per seed,
  tests added (countCompletedLines, clearingPotential, clearFocus bias).
- iOS: verified the project + all plugins are iOS-ready; can't build here
  (this Mac lacks the iOS platform SDK in Xcode and a signing cert — both
  user-side). Steps for the user in RELEASING.md / final summary.

### 2026-07-15 — Perf: thermal throttling after 5–10 min of play
- User report: sound/vibration/animation all degrade and the phone gets
  hot after 5–10 min. Diagnosed with a monitored on-device soak: a
  bounce-only drag soak (60fps render + haptics, NO audio/blur) plateaued
  safely at ~46.6°C with 0% jank and flat memory, and logcat's "Skipped N
  frames" were the idle-pause engaging — so baseline Flame/render, memory,
  and idle-pause are all fine. NOT Flame or the build; the culprits were
  specific expensive ops the bounce test didn't hit:
  1. **Audio** — `play(AssetSource())` re-decoded each SFX into Android's
     SoundPool every hit, degrading after a few hundred plays ("sound
     lags"). Now: one player per sound, asset preloaded once, replayed via
     seek+resume.
  2. **Per-frame MaskFilter.blur** — the combo glow frame and every gem's
     shadow blurred every frame (blur is the priciest mobile-GPU op).
     Replaced with cheap concentric strokes / a solid offset shadow.
  3. Idle-pause threshold 1.0s → 0.35s (pause sooner between moves).
  4. Tray-gen `canBreak` check made allocation-free
     (placementCompletesLine) to cut per-refill GC churn.

### 2026-07-15 — Playtest round 3: haptics, catch area, snug dealing
- Haptics not felt on Android: root cause was the missing VIBRATE
  permission (so HapticFeedback.vibrate no-op'd) plus Flutter's impact
  haptics being too weak on Samsung. Added VIBRATE + the `vibration`
  package; new HapticService drives explicit duration/amplitude pulses
  (with graceful fallback to HapticFeedback where no amplitude control),
  scaled per event: pickup / place / clear / combo / all-clear pattern.
  Centralized out of both screens into a provider mirroring hapticsOn.
- Tray catch area: pieces are now grabbable anywhere in their tray slot
  zone (bounded to just under half the slot spacing so neighbours don't
  fight over a touch), not just on the blocks.
- Generator snug-fit: added FitProfile.bestContact (how flush a piece
  sits against filled cells/border) in one combined placement scan;
  weight now × (1 + bestContact·snugBoost=3) and breakerBoost raised to
  4. Pieces slot into gaps far more, per feedback that fitting matters
  even more than breaking.

### 2026-07-15 — Opening cascade (all three opening pieces break)
- Playtest: the opening break was too weak — only one of the three tray
  pieces cleared. Strengthened the contract from "≥1 piece breaks" to a
  full **opening cascade**: there must be an order in which ALL THREE
  tray pieces fit and EVERY placement clears ≥1 line (leftover board
  blocks are fine). New solver `openingCascadeExists`; validator now
  enforces it; all 40 stages redesigned with parallel gap rows/columns
  sized to their trays (colors matched to breakers). CONTRIBUTING_QUESTS
  documents the design pattern. Solver + validator tests added.

### 2026-07-14 — Playtest round 2: colors, slowdown investigation
- Block palette brightened (user: too dark next to genre peers);
  icon/splash regenerated to match.
- "Slows down over time + stutters" investigated in profile mode with
  the new PERF overlay define + a component-census log:
  * NOT a leak: PSS flat (~100MB) across 36 effect-heavy cycles and
    census pinned at exactly 7 components — all effects clean up.
  * Primary suspect: sustained 60fps rendering of a turn-based game
    thermally throttling phones (Z Flip3 = Snapdragon 888). Fix: the
    engine now auto-pauses after 1s of no animation and wakes on any
    interaction — verified (identical frames while idle, census
    silent, drag responds instantly from pause).
  * The census caught a real bug in the first pause implementation:
    FlameGame's built-in children (World/Camera/DragDispatcher) made a
    blacklist check read "always animating"; switched to whitelisting
    transient effect types.
  * Thermal confirmation on the Z Flip3 needs the phone replugged.

### 2026-07-14 — Branching model formalized (user decision)
- Topic branches → PR into `dev` (squash) → periodic promotion
  `dev` → `main` (merge commit). Content-only promotions happen fast
  since players get content from `main`; app code batches into release
  promotions. Docs updated (CONTRIBUTING, PR template, quest guides).
  Direct pushes to `dev` end now that contributors are expected; `main`
  is already rule-protected — a `dev` rule can follow when desired.

### 2026-07-13 — CI live
- GitHub Actions on every PR + push to main/dev: format, analyze,
  tests, quest-content validation, Android debug build (~5 min, free
  on public repos). Both branches green; badge in README.
- Goldens are LOCAL-ONLY: Linux renders them >1% different from the
  macOS-generated files (proved by a split CI step), and adopting
  Linux renders needs authenticated artifact access we don't have.
  A tolerant comparator (1% pixel diff) stays for machine-to-machine
  drift. Follow-up: a golden-update workflow committing Linux renders
  would make CI the source of truth.
- Process lesson (cost: one broken push): piping flutter analyze/test
  through `tail` swallows exit codes — the pre-push gate must let the
  real exit codes gate the chain. CI now catches this class anyway.
- USER TODO: branch protection on main (Settings → Branches → add rule
  for main: require PR + require the "checks" status) — gives CI teeth.

### 2026-07-12 — Privacy, issue templates, fucad splash
- PRIVACY.md ("we collect nothing", store-submittable via its GitHub
  URL) + the same policy in-app: Settings → Privacy dialog, offline.
- Issue templates: bug report (asks for repro seed), quest pack
  proposal (non-programmer friendly), feature request (with the
  never-list fit check).
- Splash screen: fucad brand mark (the app icon's block motif + Roboto
  wordmark) rendered in-repo like the icon (test/tools/
  render_splash_test.dart; white-on-transparent — preview on dark),
  applied via flutter_native_splash incl. Android 12. Verified on a
  cold start screenshot.

### 2026-07-12 — Playtest feedback round (7 items)
- Drag: finger movement amplified 1.28× from the grab point so the piece
  runs ahead of the finger (1:1 tracking reads as lag on touch).
- Haptics: strengthened & completed — selectionClick on pickup, medium
  on placement, heavy on clears, vibrate on all-clear. (Earlier testing
  was partly on the emulator, which has no motor.)
- Quest banners now fire at 30/50/80% of the goal (only the highest
  newly-crossed milestone shows on big jumps).
- Screen shake on combos ≥2 / multi-line (scaled), big slam on
  all-clear — canvas jitter in BoardComponent, decayed in game.update.
- Run summary variants (priority order): New High Score → Combo Master
  (combo > 15) → All-Clear Ace (> 5 all-clears) → Try Again. GameState
  now tracks allClears (save-compatible, tolerant default).
- Quest opening trays: stages pin their first 3 pieces ("tray" field) and
  boards were tuned so an opening line-break is always possible — the
  validator enforces both (all 40 stages pass). Colors of the tweaked
  rows match their breaker pieces where practical.
- Tray dealing v2: every deal is playable in SOME order (capped
  backtracking), and pieces that can break a line right now are boosted
  3× — satisfaction-first dealing, still fully deterministic per seed.
- Dev gotcha (expected behavior): unpushed local quest content gets
  masked once the app fetches the older remote pack (fetched wins for
  the same pack id — correct in production where main ⊇ every shipped
  bundle). Push before on-device content verification.

### 2026-07-12 — Treasure-hunt map, 25 new quests, manifest-merge fix
- Quest map redesigned as a treasure hunt: dashed golden trail (lit
  behind the current level), circular nodes, auto-scroll to the current
  level, and a treasure chest at the trail's end that opens when every
  level is cleared — achievement only, grants nothing (zero-extraction).
- Content: Deep Dig (15 stages, live) and Treasure Trail (10 stages,
  release 2026-07-26 — first future-dated pack, activates the menu
  countdown badge, verified "14d 0h" on device). 40 stages total.
- Real bug found during device verification: the fetched manifest used
  to REPLACE the bundled one, so a stale remote (or a stale cache after
  an app update ships new bundled packs) hid newer bundled content.
  Manifests are now merged by pack id (fetched wins conflicts), ordered
  chronologically so level numbering stays stable. Regression-tested.
- CONTRIBUTING_QUESTS.md stays at the repo root (GitHub convention,
  linked from README/CONTRIBUTING); content/quests/README.md added as a
  pointer for authors who land in the content folder first.
- Scrolling: single scrollable handles 40+ nodes fine; if packs ever
  reach hundreds of levels, switch the map body to slivers.

### 2026-07-12 — Git workflow rule adopted
- Conventional Commits + typed branches + squash-merge PRs to `main`,
  documented in CONTRIBUTING.md. Chosen because it's the de-facto OSS
  standard, machine-parseable (future changelog automation), and gives
  AI-assisted contributors an unambiguous format. `content` type added
  for quest packs since merging those to main publishes them to players.
  Applies from v0.1 forward; earlier milestone-prefixed history stands.

### 2026-07-12 — M3 quest mode (all four slices)
- Board-string format (`.`/digits/gem letters) promoted from the test
  helper into lib/models/board_strings.dart — quest packs, tests, and
  docs all share one human-authorable layout syntax.
- Strict parsing (models) is separated from playability validation
  (lib/services/quest_validation.dart: no pre-completed lines, ≥20 empty
  cells, satisfiable gem goals, sane score targets, checksums) — the
  validator CLI, the content test, and downloaded-pack vetting reuse it.
- GitHub-as-backend: single config constant (fucad/block_puzzle),
  content-addressed pack cache in SharedPreferences keyed by sha256,
  12h refresh throttle stamped in SaveData, next-pack pre-caching.
  UI never waits on network; all failures degrade to bundled+cached.
- Quest attempts are NOT persisted mid-stage (retry restarts the
  layout) — matches the reference; only completion is saved.
- Win beats lose when the goal lands on the final possible move.
- tool/simulate.dart gained --stage <pack.json>:<id> for quest replay;
  used it to plan the on-device verification (s03 one-move win).
- Device-verified via adb run-as save injection (recipe worth reusing):
  map render/serpentine/hard nodes/progression, gem blocks + counter,
  score progress pill, Level Complete flow, map advance.

### 2026-07-11 — Reference screenshots received
- 13 Block Blast screenshots supplied; feature observations captured in
  `docs/REFERENCE_UI.md` for M2–M4 (drag lifts piece to full board scale,
  would-clear lines glow while hovering, praise/combo popup styling, quest
  progress-pill and gem-counter HUDs, map with red hard nodes, Combo
  Master summary). Everything extraction-related in them is explicitly
  out of scope.
