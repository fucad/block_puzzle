# RELEASE_CHECKLIST.md — Block Puzzle v1.0.0 (owner-only steps)

Everything that could be done in the repo is done (see "Already prepared").
What is left needs your accounts, money, secrets, or a real phone. Work top
to bottom; each step says where and what to paste. Copy for every text
field lives in `docs/STORE_LISTING.md`.

## Already prepared (no action)

- [x] `flutter analyze` clean, all tests pass, quest content validates
- [x] Version `1.0.0+1`; Android id `games.adfree.block_puzzle`, iOS id `games.adfree.blockPuzzle`
- [x] Android release signing reads `android/key.properties` (gitignored; template: `android/key.properties.example`)
- [x] `flutter build appbundle --release` and `flutter build ios --release --no-codesign` both succeed locally
- [x] iOS: iPhone-only, portrait-only, `ITSAppUsesNonExemptEncryption=false`, team `DCL6T6WR64` set
- [x] Icons (adaptive Android + iOS catalog), splash, Play 512 icon, feature graphic, screenshots (`docs/store/`)
- [x] Store copy EN + KO, questionnaire answers, review notes (`docs/STORE_LISTING.md`)
- [x] Privacy policy page `fucad.github.io/privacy/block-puzzle.html` (EN + KO) — goes live when the site repo is pushed
- [x] CI `release.yml`: on a `v*` tag builds a signed AAB (if secrets exist) + unsigned iOS compile check

---

## A. Android / Google Play

**A1. Developer account** (once, USD 25)
- https://play.google.com/console/signup — personal or organization.
- New personal accounts must run a **closed test with ≥ 12 testers for 14 days** before production access. Plan for it: recruit testers early (friends, a Discord, GitHub issue).
- Identity verification (ID + phone) can take days.

**A2. Upload keystore** (once, keep forever, never commit)
```sh
mkdir -p ~/keys && keytool -genkey -v -keystore ~/keys/fucad-upload.jks \
  -keyalg RSA -keysize 2048 -validity 10000 -alias upload
cp android/key.properties.example android/key.properties   # then edit it
```
- Fill `storePassword`, `keyPassword`, `keyAlias=upload`, `storeFile=/Users/<you>/keys/fucad-upload.jks`.
- Back up the `.jks` + passwords in a password manager. With Play App Signing (default) a lost upload key can be reset by Google support, but it costs days.
- One upload key can sign all FUCAD games, or one per game — either works.

**A3. Build**
```sh
flutter build appbundle --release
# → build/app/outputs/bundle/release/app-release.aab
```
Check it is NOT debug-signed: `keytool -printcert -jarfile build/app/outputs/bundle/release/app-release.aab` should show your name, not "Android Debug".

**A4. Create the app in Play Console**
- Create app ▸ name (see STORE_LISTING §1), default language English (US), **Game**, **Free**, accept declarations.
- Main store listing: short + full description, `docs/store/play/icon_512.png`, `docs/store/play/feature_graphic.png`, phone screenshots `docs/store/play/en/*.png` (KO listing: `docs/store/play/ko/*.png`). Add translation ▸ Korean with the KO copy.
- App content: fill every section exactly as in STORE_LISTING §4 (privacy URL, ads = No, data safety = nothing collected, IARC questionnaire, target audience).
- Store settings: category Puzzle, contact email `dal001.dev@gmail.com`, website `https://fucad.github.io`.

**A5. Release**
- Testing ▸ Closed testing ▸ create track ▸ upload the AAB ▸ add testers (email list or Google Group) ▸ roll out. Keep ≥ 12 testers opted in for 14 days.
- Then Production ▸ create release ▸ promote the same build ▸ countries (all, or start with KR + US) ▸ review (usually 1–7 days).

**A6. (Optional) CI signing** — add the four `ANDROID_*` secrets listed at the top of `.github/workflows/release.yml`; then `git tag v1.0.0 && git push origin v1.0.0` produces a signed AAB artifact.

---

## B. iOS / App Store

**B1. Apple Developer Program** (USD 99/yr) — team `DCL6T6WR64` is already in the Xcode project; confirm it is a paid membership (not a free personal team), otherwise enroll at https://developer.apple.com/programs/enroll/.

**B2. Register the app**
- https://appstoreconnect.apple.com ▸ Apps ▸ ＋ New App ▸ iOS, name (STORE_LISTING §1 — must be unique), primary language English (U.S.), bundle ID `games.adfree.blockPuzzle` (if it isn't in the list, register it at developer.apple.com ▸ Identifiers first), SKU `fucad-block-puzzle`.

**B3. Archive + upload** (on this Mac)
```sh
flutter build ipa --release
open build/ios/archive/Runner.xcarchive   # Organizer ▸ Distribute App ▸ App Store Connect ▸ Upload
```
Automatic signing creates the distribution certificate + profile on first run (Xcode ▸ Settings ▸ Accounts must be signed in with your Apple ID).

**B4. Fill the listing** (App Store Connect ▸ the app)
- 1.0 Prepare for Submission: screenshots `docs/store/ios/en/*.png` (KO: `ios/ko/`) (6.9" slot; Apple scales them to smaller iPhones), promotional text, description, keywords, support URL `https://github.com/fucad/block_puzzle/issues`, marketing URL `https://fucad.github.io`, copyright, review notes. Add Korean localization with the KO copy.
- App Privacy: privacy policy URL + **Data Not Collected**.
- Age rating questionnaire → 4+. Pricing: Free, all territories.
- Pick the uploaded build, Submit for Review (typically 1–3 days). Use TestFlight first if you want a device check.

---

## C. Before pressing "release" on either store

- [ ] Push the site repo so the privacy URL resolves (stores reject a 404 policy).
- [ ] Push `dev` → `main` of block_puzzle (players fetch quest packs from `main`).
- [ ] Play the **release** build on a real phone for 10 minutes: classic run, one quest stage, kill + resume, sound/haptics toggles, Settings ▸ Privacy text. Ideally a low-end Android too.
- [ ] Tag: `git tag v1.0.0 && git push origin v1.0.0`.

## D. After launch

- [ ] Put the real store URLs into `fucad.github.io/index.html` (`GAMES[0].play` / `.app`) and flip `status` to `'OUT NOW'`.
- [ ] Add store badges/links to the block_puzzle README.
- [ ] Every later upload: bump `+N` in `pubspec.yaml` (build number must strictly increase).
