# ARCHITECTURE.md — Block Puzzle

Open-source, ad-free block puzzle (Block Blast style) on an 8×8 grid.
Flutter + Flame, Riverpod for app state. Part of the "Free Ad-free Games"
project — see `../PURPOSE.md` and `PROGRESS.md` (checklist + decisions log).

## Layering

Dependencies point downward only. Everything below `state/` is pure Dart —
no Flutter imports, fully unit-testable without pumping widgets.

```
lib/
  ui/        Menus, quest map, HUD, dialogs (one widget per file)
  game/      Flame game: board rendering, drag & drop, effects/particles
  state/     Riverpod providers: settings, progress, high scores, quest cache
  services/  Persistence, quest fetch/cache (GitHub), audio
  systems/   PURE: placement, line clear, scoring, combo, piece gen, engine
  models/    PURE data: Board, Piece, Placement, QuestStage, SaveData, Theme
```

- `systems/` + `models/` form the **deterministic core**: given
  `(seed, [placements])` the resulting board, score, and combo are exactly
  reproducible in a plain Dart test.
- `game/` (Flame) renders state and emits player intents; it never contains
  rules. `state/` bridges core ↔ UI via Riverpod.
- `services/` owns all I/O. The only network call in the app is the quest
  pack fetch from raw.githubusercontent.com (see section "Quest content").
  No ads, analytics, or trackers — ever.

## Core model

- **Board**: immutable 8×8 grid, `List<Cell>` of 64 in row-major order.
  A `Cell` is empty or occupied with a `colorId` and an optional `gem`
  color (quest mode). Operations return new boards.
- **Piece**: normalized list of `(row, col)` offsets + id + spawn weight.
  No rotation at runtime — every orientation is its own catalog entry.
  The full set lives in one data file: `lib/models/piece_catalog.dart`.
- **Placement**: `(pieceId, row, col)` where `(row, col)` is the top-left
  of the piece's bounding box.

## Game loop (turn-based)

`GameEngine.place(state, placement)` is a pure function returning the next
state plus an event summary (for effects/audio):

1. Validate legality (in bounds, all target cells empty). Illegal → rejected.
2. Stamp the piece; score `+1 per cell`.
3. Detect **simultaneously** full rows and columns; clear their union.
4. Scoring (constants in `lib/systems/game_constants.dart`):
   - line score = `lineClearBase * n * (n + 1) / 2` for `n` lines at once
     (10 / 30 / 60 / 100…), so one multi-line beats separate singles.
   - **Combo**: a placement that clears ≥1 line increments the combo
     counter; a placement that clears nothing **resets it to 0**
     (decision 2026-07-11). Combo bonus = `comboBonusPerLevel * (combo - 1)`
     added on each clearing placement.
   - **All-clear**: board empty after the clear → `+allClearBonus` (300).
   - Gems: any gem in a cleared line is collected (quest win conditions).
5. Remove the piece from the tray; when all 3 slots are used, generate the
   next 3 from the seeded generator.
6. **Game over** when no remaining tray piece fits anywhere on the board.

## Seeded piece generation

Randomness uses a hand-rolled **splitmix64 + xorshift** PRNG
(`lib/systems/rng.dart`), not `dart:math Random`, so sequences are stable
across Dart versions and serializable (the 64-bit state is stored in the
save to resume a run mid-tray).

Tray generation algorithm (documented contract, tested):

1. When the tray refills, compute for each catalog piece whether it fits
   anywhere on the current board, and whether it is a **breaker** (some
   position completes a line right now).
2. Effective weight = base × `fitPenalty` (0.15) if it does NOT fit ×
   `breakerBoost` (3.0) if it is a breaker — clearing lines is the core
   satisfaction, so the deal leans into it.
3. Draw a candidate set of 3 (weighted, with replacement); if the whole
   draw is dead while something fits, redraw the last slot from the
   fitting pieces.
4. Up to `traySetDrawAttempts` (6) candidate sets are drawn; the first
   one that is **playable in some order** (backtracking search over
   placements with clears applied, capped at `solvabilityNodeCap` nodes)
   wins, preferring sets that contain a breaker whenever the board
   allows a break at all. The player might not find the order, but one
   always exists while the board permits it.

Quest stages may pin the FIRST tray via the stage's `tray` field (the
"opening break" design — see CONTRIBUTING_QUESTS.md); the generator
takes over from the second tray on.

Classic rolls a random seed per run (persisted); quest stages may pin a
seed in their data.

## Quest content (GitHub as data store)

No backend. `content/quests/manifest.json` indexes pack files under
`content/quests/packs/`. The app fetches the manifest from
raw.githubusercontent.com (single config constant for the repo URL),
downloads packs whose `release_date` ≤ today, verifies sha256 checksums,
caches locally, and pre-caches the next upcoming pack. Offline or on
failure it uses bundled + cached packs; one starter pack ships in app
assets. Menu countdown badge derives from the next pack's `release_date`.
Schema is versioned and strictly parsed. Details: `CONTRIBUTING_QUESTS.md`.

## Persistence

One service (`lib/services/`); versioned JSON save model documented in
`SAVE_MODEL.md`: settings, classic high score + resumable in-progress run
(board, tray, RNG state, score, combo), quest progress, best combos, quest
cache metadata.

## Key decisions

See the dated Decisions log in `PROGRESS.md`. Highlights:

- **Flame** for the board/effects layer (project convention: Flutter+Flame
  across all Free Ad-free Games; particle/effect APIs).
- **Riverpod** for app/meta state; the game core stays pure Dart.
- **Combo rule**: immediate reset on a non-clearing placement.
- **Portrait-only**, both Android and iOS, safe-area aware.
