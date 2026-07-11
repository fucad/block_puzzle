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

- [ ] Board rendering + drag-and-drop with ghost preview and would-clear highlight
- [ ] Tray of 3, refill logic
- [ ] Line-clear / multi-line / all-clear effects at 60fps
- [ ] Combo popups + praise text + board glow
- [ ] Score HUD, high score persistence, game over → Combo Master summary → retry
- [ ] Resume in-progress classic run after app kill

## M3 — Quest mode

- [ ] Quest JSON schema + strict parser + validator CLI/test
- [ ] Bundled starter pack (author ~15 stages: mix of score & gem goals, a few hard)
- [ ] Stage play: pre-placed boards, gem collection, progress UI, 80% banner
- [ ] Win/lose screens; quest map screen with path, hard nodes, progression
- [ ] GitHub fetch + cache + release-date gating + checksum verify + offline fallback
- [ ] Main-menu countdown badge

## M4 — Polish & release prep

- [ ] Main menu, settings (sound/haptics/theme/reset/about+licenses)
- [ ] Audio (CC-compatible), haptics
- [ ] Theme system seam + default theme polish
- [ ] Golden tests for HUD/menu; low-end device perf pass
- [ ] App icons, store metadata, README/CONTRIBUTING docs complete
- [ ] Android + iOS release builds verified

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

### 2026-07-11 — Reference screenshots received
- 13 Block Blast screenshots supplied; feature observations captured in
  `docs/REFERENCE_UI.md` for M2–M4 (drag lifts piece to full board scale,
  would-clear lines glow while hovering, praise/combo popup styling, quest
  progress-pill and gem-counter HUDs, map with red hard nodes, Combo
  Master summary). Everything extraction-related in them is explicitly
  out of scope.
