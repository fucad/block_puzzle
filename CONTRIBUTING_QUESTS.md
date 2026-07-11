# CONTRIBUTING_QUESTS.md — how to author a quest pack

Quest packs are plain JSON files in this repo. When your pull request is
merged, the pack goes live for every player **without an app-store
release** — the app fetches `content/quests/` from GitHub at launch.
No programming required.

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
      "hard": true              // optional: red "hard" node on the map
    }
  ]
}
```

### Board characters

| char | meaning |
|------|---------|
| `.` | empty cell |
| `0`–`7` | block in palette color 0–7 (red, green, orange, yellow, blue, purple, cyan, pink) |
| `r` `b` `p` `y` `g` | gold block holding a red / blue / purple / yellow / green **gem** |

Gems are collected when any completed line containing them clears.

### Goals

- Score: `{ "type": "score", "target": 700 }` — reach the score.
- Gems: `{ "type": "gems", "counts": { "red": 2, "purple": 3 } }` —
  collect all listed gems. Every color you require must actually exist on
  the board in at least that quantity.

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
