# RELEASING.md — how app releases work

Two kinds of "release" exist here, and only one needs this doc:

- **Quest content** — merging a content PR to `main` ships it to every
  player on their next launch. No version bump, no store, no this file.
- **App binaries** — everything below.

## Versioning

`pubspec.yaml` holds `version: X.Y.Z+N`:

- `X.Y.Z` is the player-visible version (semver-ish: new modes/features
  bump minor, fixes bump patch).
- `+N` is the build number; it must strictly increase for every store
  upload, never resets.

## Release steps

1. Branch, bump `version:` in pubspec.yaml, PR it
   (`chore(release): v0.2.0`), merge on green.
2. Tag the merge commit: `git tag v0.2.0 && git push origin v0.2.0`.
3. Changelog: the conventional-commit history IS the changelog —
   `git log --oneline v0.1.0..v0.2.0` and summarize the `feat`/`fix`
   lines for the store notes.
4. Build:
   - Android: `flutter build appbundle --release` (requires the local
     upload keystore + `android/key.properties`; both are secrets and
     never enter the repo).
   - iOS: `flutter build ipa` and upload via Xcode/Transporter.
5. Upload, staged rollout at the store's discretion, done.

## Sanity checks before tagging

- CI green on `main` (it always should be — branch protection).
- Play the release build on a real device: classic run, one quest
  stage, resume-after-kill, sound/haptics toggles.
- `dart run tool/validate_quests.dart` (CI ran it, but it's cheap).
