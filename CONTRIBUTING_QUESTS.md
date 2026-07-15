# CONTRIBUTING_QUESTS.md — how to author a quest pack

Quest packs are plain JSON files in this repo. Once your pull request is
merged and promoted to `main` (quick for content — see CONTRIBUTING.md),
the pack goes live for every player **without an app-store release** —
the app fetches `content/quests/` from GitHub at launch. No programming
required.

## The files

- `content/quests/manifest.json` — the index of all packs.
- `content/quests/packs/<your-pack>.json` — one file per pack.

## Pack file format (schema 1)

```jsonc
{
  "schema": 1,
  "id": "winter-2026",          // unique, lowercase, no spaces
  "title": "Winter Wonders",    // shown to players
  "stages": [
    {
      "id": "s01",              // unique within the pack
      "board": [                // exactly 8 strings of exactly 8 chars
        "........",
        "........",
        "........",
        "........",
        "........",
        "........",
        "3r33.r33",
        "333.3333"
      ],
      "goal": { "type": "score", "target": 300 },
      "seed": 7,                // optional: pins piece order (else random)
      "hard": true,             // optional: red "hard" node on the map
      "tray": ["line2h", "line3h", "square2"]  // opening tray, see below
    }
  ]
}
```

### The opening tray (`tray`)

Every stage opens with a **full cascade**: the three hand-picked tray
pieces must slot into gaps you design into the board, and there must be
an order in which EVERY one of the three placements clears at least one
line. Leftover blocks on the board are fine — a placement that doesn't
break is not. The validator enforces this whenever `tray` is present.
After the opening tray is used up, pieces come from the normal
generator.

Design tips that make cascades easy to reason about:

- Keep the opening lines **parallel** (all rows, or all columns) —
  lines that cross steal cells from each other when they clear.
- Multi-line pieces are the spice: `square2`/`sH`/`zH`/`corner3*`
  spanning two nearly-full rows clear both at once; `square3`,
  `rect3x2`, `corner5*`, `sV`/`zV`, `tRight`/`tLeft` can clear three.
- Match each line's block color to the piece that completes it
  (piece colors are in `lib/models/piece_catalog.dart`).
- Gems inside cascade lines collect instantly (great feel); keep some
  gems outside the cascade so the goal continues past the opening.

Piece ids are the entries in `lib/models/piece_catalog.dart` (`single`,
`line2h`…`line5v`, `square2`, `square3`, `rect2x3`, `rect3x2`,
`corner3nw/ne/se/sw`, `corner5nw/ne/se/sw`, `tUp/tDown/tLeft/tRight`,
`sH/sV/zH/zV`).

### Board characters

| char | meaning |
|------|---------|
| `.` | empty cell |
| `0`–`7` | block in palette color 0–7 (red, green, orange, yellow, blue, purple, cyan, pink) |
| `r` `b` `p` `y` `g` | light tile holding a red / blue / purple / yellow / green **gem** |

Gems are collected when any completed line containing them clears. For a
gem GOAL you normally leave these out of the board entirely — gems come
from the tray (see Goals). The gem letters remain available if you want a
few decorative pre-placed gems, but they are not required and not counted
toward what's reachable.

### Goals

- Score: `{ "type": "score", "target": 700 }` — reach the score.
- Gems: `{ "type": "gems", "counts": { "red": 8, "purple": 6 } }` —
  collect *at least* the listed count of each color. Gems ride on the
  generated tray pieces (spawned only for colors you still need), so the
  goal does NOT depend on gems being pre-placed on the board — you don't
  put gems in the board at all for a gem goal, and counts can be large.
  Collecting more than the goal is fine. Once a color is fully collected
  it stops appearing on new pieces.

### Rules the validator enforces

- Boards are exactly 8×8 with only the characters above.
- No row or column may start out already complete.
- At least 20 empty cells (otherwise the stage is likely unplayable).
- Gem goals must be satisfiable by the gems on the board.
- Score targets between 50 and 20000.
- Stage ids unique within a pack; pack ids unique in the manifest.
- The manifest checksum must match the pack file.

## Manifest entry

Add your pack to `content/quests/manifest.json`:

```jsonc
{
  "id": "winter-2026",
  "title": "Winter Wonders",
  "release_date": "2026-12-01",   // UTC; players see it at 00:00 UTC
  "file": "packs/winter-2026.json",
  "checksum": "<filled by the validator>"
}
```

A future `release_date` is fine — the app pre-caches the pack and shows a
countdown on the main menu until it unlocks.

## Validate before opening a PR

From the repo root (needs the Flutter SDK):

```sh
dart run tool/validate_quests.dart --update   # fills in checksums
dart run tool/validate_quests.dart            # must print OK
flutter test test/quest_content_test.dart     # same checks as CI
```

Playtest your stages if you can: run the app and play them
(`flutter run`). For deterministic testing, pin a `seed` and use
`dart run tool/simulate.dart <seed> [slot,row,col ...]` to replay piece
sequences headlessly (see docs/DEV_NOTES.md).

## Design tips

- Early stages: bottom-heavy boards, one near-complete line, score
  targets under 300.
- Gem stages read best when gems sit on lines the player is naturally
  finishing; a full column of gems (see starter `s13`) is a great "aha".
- `hard: true` stages should demand planning ahead, not luck — avoid
  boards where only one exact piece can prevent a lock-up.
- Keep packs to 10–20 stages with a difficulty ramp.
