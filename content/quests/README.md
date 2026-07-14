# Quest content

These JSON files ARE the live quest levels — `main` is what players'
apps download, and content changes get promoted from `dev` to `main`
quickly after merging. No app update needed, ever.

**Want to author levels?** Full guide: [CONTRIBUTING_QUESTS.md](../../CONTRIBUTING_QUESTS.md)
(kept at the repo root where GitHub surfaces contribution docs).

Quick reference:

- `manifest.json` — the pack index (release dates gate visibility;
  checksums are maintained by the validator).
- `packs/*.json` — one file per pack; boards are 8 strings of 8 chars
  (`.` empty, `0`-`7` colored block, `r b p y g` gem block).

Before any PR:

```sh
dart run tool/validate_quests.dart --update && dart run tool/validate_quests.dart
```
