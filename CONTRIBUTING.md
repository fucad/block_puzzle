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

## Git workflow

Two long-lived branches:

- **`main`** — the live branch. The app fetches `content/quests/` from
  it, so **whatever is on `main` is what players have**. Protected:
  PRs only, CI must be green.
- **`dev`** — the integration branch. All work lands here first.

The flow: topic branch → PR into `dev` → maintainers periodically
**promote `dev` to `main`** (a merge-commit PR). App-code changes batch
up into release promotions; content-only changes get promoted quickly
so new quest packs reach players without waiting on a release.

**Branches:** `<type>/<short-topic>` off `dev`, e.g. `feat/wood-theme`,
`fix/tray-hitbox`, `content/winter-2026-pack`.

**Commits:** [Conventional Commits](https://www.conventionalcommits.org):

```
<type>(<optional scope>): <imperative summary, ≤72 chars>

Body: what problem this solves and WHY this approach — the decision
context a reviewer or future contributor can't get from the diff.
```

Types used here:

| type | for |
|------|-----|
| `feat` | player-visible features |
| `fix` | bug fixes (state the root cause in the body) |
| `content` | quest packs and other data-only changes |
| `docs` | documentation only |
| `test` | tests only |
| `refactor` | no behavior change |
| `perf` | performance |
| `chore` | tooling, deps, CI, release plumbing |

Scopes (optional, use when it helps): `engine`, `game`, `ui`, `state`,
`services`, `quests`, `audio`, `android`, `ios`.

**PRs:** one logical change per PR, targeting `dev`; squash-merged so
`dev` stays one-change-per-commit, with the squash title itself a valid
conventional commit. Promotions `dev` → `main` use a merge commit
(keeping the shared history) titled e.g. `chore(promote): quest packs`
or `chore(release): v0.2.0`. If AI assistance produced part of the
change, keep whatever attribution trailer your tool adds (e.g.
`Co-Authored-By`) — transparency is part of the project ethos.

History note: commits before v0.1 predate this rule and use milestone
prefixes (`M2b: ...`); the convention applies from v0.1 onward.

## Opening a PR, step by step

1. **Fork** the repo (external contributors) or branch off `dev`.
2. **Branch**: `<type>/<short-topic>` (e.g. `content/winter-pack`).
3. Make the change; keep it to one logical thing. If you're unsure the
   idea will be accepted, open an issue first and save yourself work.
4. **Run the checks** — the same ones the PR template asks about:
   ```sh
   dart format . && flutter analyze && flutter test
   dart run tool/validate_quests.dart   # if you touched content/quests/
   ```
5. Exercise your change in the app on a device or emulator; grab a
   screenshot for anything visual (capture recipes: docs/DEV_NOTES.md).
6. **Open the PR** against `dev` with a conventional-commit title. The
   template will prompt you for the why and the checklist.
7. **Review**: a maintainer reviews for correctness, the architecture
   rules (pure logic stays in `lib/systems`/`lib/models`), and the
   zero-extraction principles. Expect questions about *why* rather than
   nitpicks about style — the formatter owns style.
8. **Merge & promote**: maintainers squash-merge into `dev`, then
   promote `dev` → `main` — quickly for quest content (players receive
   it on their next launch, no release needed — that's the fun part,
   and the reason review is careful), in batches for app code.

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
