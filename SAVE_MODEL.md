# SAVE_MODEL.md — Persisted data schema

All persistence goes through one service layer (`lib/services/`, M2) and
serializes the versioned `SaveData` model (`lib/models/save_data.dart`).
Storage medium: a single JSON document under the SharedPreferences key
`save`. Cached quest content lives OUTSIDE the save document, in sibling
keys: `quest_manifest` (latest fetched manifest) and
`quest_pack_<sha256>` (content-addressed pack bodies); the save itself
only stores the fetch-throttle timestamp. Unreadable saves are moved to
`save_unreadable`, never overwritten.

Any schema change bumps `version` and adds a migration note here. Loading an
unknown version throws — callers must handle it explicitly rather than
silently discarding progress.

## Version 1

```jsonc
{
  "version": 1,
  "settings": {
    "soundOn": true,
    "hapticsOn": true,
    "themeId": "default"
  },
  "classicHighScore": 0,       // all-time best classic score
  "allTimeBestCombo": 0,       // best combo streak ever (Combo Master screen)
  "classicRun": null,          // in-progress classic run, or null
  "classicRunSeed": "12345",   // seed that run started from (string int64)
  "questCompleted": {          // packId -> sorted stage ids completed
    "starter": ["s01", "s02"]
  },
  "lastQuestFetchEpochMs": null // throttle for the GitHub manifest fetch
}
```

### `classicRun` (GameState snapshot)

```jsonc
{
  "board": [null, {"c": 3}, {"c": 5, "g": "red"}, ...],  // 64 cells row-major
  "tray": ["line3h", null, "square2"],  // null = slot already played
  "rngState": "-8423581294942912",      // GameRng state (string int64)
  "score": 1240,
  "combo": 3,
  "roundBestCombo": 7,
  "allClears": 1,                       // this run; absent in old saves -> 0
  "clearFocus": true,                   // classic mode's easy-clears dealing
  "gemGoal": {"red": 8},                // quest gem stage target (else absent)
  "trayGems": [{"0": "red"}, {}, {}],   // gems on each tray slot (else absent)
  "gems": {"red": 1}                    // collected this run (quest only)
}
```

Notes:
- Board cell: `null` = empty; otherwise `c` = theme palette color index,
  optional `g` = gem color name (quest boards only), optional `p` = true
  for pre-placed quest puzzle blocks (rendered in the neutral light tile).
- 64-bit integers (`rngState`, `classicRunSeed`) are stored as **strings**
  because JSON tooling commonly round-trips numbers through doubles, which
  corrupts values above 2^53.
- Resuming a run needs no replay: board, tray, and RNG state fully determine
  the future. The seed is kept only for bug reproduction.
- Quest progress is a set of completed stage ids per pack, so packs can be
  extended without migrations.
