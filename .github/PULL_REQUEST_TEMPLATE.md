<!--
Target branch: dev (main only receives dev-promotion PRs).
Title must be a Conventional Commit — it becomes the squash commit:
  feat(ui): ... | fix(engine): ... | content(quests): ... | docs: ...
-->

## What & why

<!-- What does this change, and why this approach? A reviewer can see
     WHAT from the diff — the WHY is what they can't reconstruct. -->

## Checklist

- [ ] `dart format .` and `flutter analyze` are clean
- [ ] `flutter test` is green (new logic has new tests)
- [ ] Ran it on a device/emulator and exercised the affected flow
- [ ] One logical change; title is a valid conventional commit
- [ ] Nothing from the never-list (ads, IAP, analytics, tracking,
      locked content, extra network calls — see CONTRIBUTING.md)

### Quest content only

- [ ] `dart run tool/validate_quests.dart --update` then
      `dart run tool/validate_quests.dart` prints OK
- [ ] Playtested the new stages (opening break feels good)
- [ ] I understand this ships to players as soon as `dev` is promoted
      to `main` (fast for content merges)

## Screenshots

<!-- For anything visual: before/after or a capture of the new state.
     adb capture recipes: docs/DEV_NOTES.md -->
