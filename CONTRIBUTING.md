# Contributing to Block Puzzle

Thanks for helping build a game that treats players like people, not
inventory. Ground rules first, then the practical stuff.

## The hard rules (from PURPOSE.md)

PRs adding any of the following are closed without discussion: ads or ad
SDKs, in-app purchases, analytics/tracking of any kind, cross-promotion,
locked or paywalled content, push notifications, accounts, or any network
call other than the quest-content fetch from this repo.

## Ways to contribute

- **Quest packs** — no programming needed; see
  [CONTRIBUTING_QUESTS.md](CONTRIBUTING_QUESTS.md).
- **Themes/skins** — a theme is pure data (`lib/models/game_theme.dart`).
  Add a `GameTheme` to `allThemes`, and the settings picker appears
  automatically. Every theme is free for every player, always.
- **Bug fixes & features** — see below. Discuss non-trivial features in
  an issue first.
- **Art, sound, translations** — must be original or CC BY-compatible,
  with provenance stated in the PR.

## Working on the code

Read [ARCHITECTURE.md](ARCHITECTURE.md) first — the core invariant is
that all rules live in pure Dart (`lib/systems/`, `lib/models/`) with no
Flutter imports, and stay deterministic from a seed. AI-assisted
contributions are welcome; you are responsible for understanding and
testing what you submit.

Definition of done for a PR:

1. `dart format .` and `flutter analyze` — clean.
2. `flutter test` — green, with new tests for any rule/logic change.
3. Ran it on a device or emulator and exercised the affected flow.
4. One logical change per commit; say *why* in the message.

Handy: `--dart-define=SEED=42` pins classic runs;
`dart run tool/simulate.dart` replays runs headlessly (see
docs/DEV_NOTES.md for more, including emulator drive-by-adb recipes).

## Design bar

Match the reference feel documented in `docs/REFERENCE_UI.md`: readable
at arm's length, chunky and juicy, 60fps during effects. When a design
choice is genuinely open, open an issue instead of guessing.
