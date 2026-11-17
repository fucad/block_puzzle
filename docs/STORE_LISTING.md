# Store listing — Block Puzzle (Google Play + App Store)

Copy-paste source for both consoles. EN is the default listing; KO is the
first translation (owner market). Character limits are noted per field and
every string below fits them.

Facts every field must stay true to: no ads, no IAP, no accounts, no
analytics, no crash reporting; the only network call is an anonymous
download of level packs from `raw.githubusercontent.com`; 40 quest levels
across 3 packs at v1.0.0; MIT code, CC BY assets.

---

## 1. Identity

| Field | Value |
|---|---|
| Android applicationId | `games.adfree.block_puzzle` (permanent after first upload) |
| iOS bundle id | `games.adfree.blockPuzzle` (permanent after first upload) |
| Version | `1.0.0+1` (pubspec.yaml) |
| Category | Games ▸ Puzzle (both stores) |
| Price | Free, no in-app purchases |
| Contains ads | **No** |
| Support email | dal001.dev@gmail.com (same address as the in-app feedback sheet) |
| Website | https://fucad.github.io |
| Privacy policy URL | https://fucad.github.io/privacy/block-puzzle.html |
| Source code | https://github.com/fucad/block_puzzle |
| Copyright (App Store) | `2026 FUCAD contributors` |

### App name (both stores ≤ 30 chars)

Store names must be unique on the App Store, and plain "Block Puzzle" is
taken many times over. Recommended, in order (owner picks — QUESTIONS.md):

1. `Block Puzzle: No Ads · FUCAD` (28)
2. `FUCAD Block Puzzle` (18)
3. `Block Puzzle — Ad-Free` (22) — fine on Play, likely collides on iOS

KO name: `블록 퍼즐: 광고 없음 · FUCAD` (19)

The on-device label stays `Block Puzzle` (Android `android:label`, iOS
`CFBundleDisplayName`) — fits under the icon without truncation.

---

## 2. English (en-US)

**App Store subtitle (≤ 30):**
> No ads. No tracking. Free.

**Play short description (≤ 80):**
> Classic block puzzle. No ads, no purchases, no tracking. Free forever.

**App Store promotional text (≤ 170, editable without review):**
> 40 hand-crafted quest levels plus endless Classic. New level packs arrive
> without an app update. Still no ads — not even "optional" ones.

**Full / long description (≤ 4000):**

```
The block puzzle you know — with everything you hate removed.

Drag pieces onto the 8×8 board. Fill a row or a column to clear it. Chain
clears into combos, wipe the whole board for a huge bonus, and chase your
best score.

★ CLASSIC — endless high-score play. Your run is saved, so you can close
  the app mid-game and pick up exactly where you left off.
★ QUEST — 40 hand-crafted levels on a treasure-trail map: hit score
  targets or collect colored gems. New level packs arrive regularly, no
  update needed.
★ Juicy feedback — combo streaks, ALL CLEAR bursts, satisfying sound and
  haptics (both can be switched off).
★ Plays fully offline.

And what's NOT in the game:
• No ads. Not even "optional" ones, not even rewarded ones.
• No in-app purchases. Nothing is locked, nothing is "premium".
• No analytics, no tracking, no account, no sign-in.
• No energy, no timers, no "come back in 4 hours".

Why? Simple games like this one cost almost nothing to build and maintain
in the AI era. There's no longer any reason they should cost you your
attention. Block Puzzle is part of FUCAD — a small project making classic
casual games a free, open-source public good.

Free forever. Open source (MIT). Play it, inspect it, fork it, or
contribute a level pack:
https://github.com/fucad/block_puzzle
```

**App Store keywords (≤ 100 bytes, comma-separated, no spaces, don't repeat the name):**
```
blocks,brain,logic,grid,tetris-like,offline,no ads,free,combo,classic,casual,relax,8x8,quest
```
(Trim if the console counts > 100; drop `tetris-like` first — trademark-adjacent.)

**What's new (v1.0.0):**
> First release. Classic mode, 40 quest levels, zero ads.

---

## 3. 한국어 (ko-KR)

**App Store 부제 (≤ 30):**
> 광고 없음. 추적 없음. 영원히 무료.

**Play 간단한 설명 (≤ 80):**
> 클래식 블록 퍼즐. 광고도, 결제도, 추적도 없습니다. 영원히 무료.

**App Store 프로모션 텍스트 (≤ 170):**
> 직접 만든 퀘스트 40단계와 끝없는 클래식 모드. 새 레벨 팩은 앱 업데이트 없이
> 추가됩니다. 그리고 여전히 광고는 없습니다 — "선택형 광고"조차도.

**자세한 설명 (≤ 4000):**

```
여러분이 아는 그 블록 퍼즐 — 싫었던 것만 전부 뺐습니다.

8×8 보드에 블록을 끌어다 놓으세요. 가로줄이나 세로줄을 가득 채우면
사라집니다. 연속으로 지워 콤보를 이어가고, 보드를 통째로 비워 큰 보너스를
받고, 최고 점수에 도전하세요.

★ 클래식 — 끝없이 즐기는 최고 점수 모드. 게임 도중 앱을 닫아도 진행 상황이
  저장되어 그대로 이어서 할 수 있습니다.
★ 퀘스트 — 보물 지도 위에 펼쳐진 40개의 직접 만든 레벨. 목표 점수를
  달성하거나 색깔 보석을 모으세요. 새 레벨 팩은 업데이트 없이 추가됩니다.
★ 손맛 — 콤보, 올 클리어 연출, 효과음과 진동 (모두 끌 수 있어요).
★ 완전한 오프라인 플레이.

그리고 이 게임에 없는 것:
• 광고 없음. "선택형"이나 "보상형" 광고조차 없습니다.
• 인앱 결제 없음. 잠긴 것도, "프리미엄"도 없습니다.
• 분석·추적·계정·로그인 없음.
• 에너지, 대기 시간, "4시간 뒤에 다시 오세요" 없음.

왜냐고요? AI 시대에 이런 단순한 게임은 만들고 유지하는 데 거의 비용이 들지
않습니다. 그러니 더 이상 여러분의 시간과 주의력을 대가로 받을 이유가
없습니다. 블록 퍼즐은 고전 캐주얼 게임을 무료·오픈소스 공공재로 만드는
작은 프로젝트, FUCAD의 일부입니다.

영원히 무료. 오픈소스(MIT). 플레이하고, 코드를 들여다보고, 포크하거나,
레벨 팩을 기여해 주세요:
https://github.com/fucad/block_puzzle
```

**App Store 키워드 (≤ 100 bytes — 한글은 글자당 3바이트이므로 짧게):**
```
블록,퍼즐,광고없음,무료,오프라인,두뇌,콤보,클래식
```

**새로운 기능 (v1.0.0):**
> 첫 출시. 클래식 모드, 퀘스트 40단계, 광고 0개.

> Note: the app UI itself is English-only at v1.0.0. Korean store copy is
> still fine (stores allow listings in languages the UI lacks), but the
> listing must not claim Korean UI. Localizing the in-app strings is a
> good-first-issue follow-up.

---

## 4. Store questionnaires (answers, copy-paste ready)

### Google Play ▸ App content

| Section | Answer |
|---|---|
| Privacy policy | https://fucad.github.io/privacy/block-puzzle.html |
| Ads | **No, my app does not contain ads** |
| App access | All functionality available without special access |
| Content rating (IARC) | Category: *Game* → all violence/sexuality/language/drugs/gambling questions **No**; "Does the app allow users to interact or exchange content?" **No**; "Share location?" **No**; "Allow purchases?" **No** → expected result: PEGI 3 / ESRB Everyone / GRAC ALL (전체이용가) |
| Target audience | 13+ recommended (selecting under-13 age groups triggers Families policy review; the app would pass, but it adds work — owner decision, see QUESTIONS.md) |
| News app | No |
| Data safety | "Does your app collect or share any of the required user data types?" → **No**. "Is all of the user data collected by your app encrypted in transit?" → n/a (nothing collected). "Do you provide a way for users to request that their data is deleted?" → n/a. Result label: **No data collected · No data shared** |
| Government app | No |
| Financial features | None |
| Health | No |

Permissions declared in the manifest: `INTERNET` (level-pack download),
`VIBRATE` (haptics). Neither is a sensitive permission; no declaration form.

### App Store Connect ▸ App Privacy

- "Do you or your third-party partners collect data from this app?" → **No, we do not collect data from this app**
- Resulting label: **Data Not Collected**

### App Store Connect ▸ Age rating

All content descriptors **None**; "Unrestricted web access" **No**;
"Gambling/contests" **No** → **4+**.

### Export compliance

`ITSAppUsesNonExemptEncryption = false` is set in `ios/Runner/Info.plist`
(the app only uses OS-provided HTTPS), so no per-build prompt.

### App Review notes (App Store)

```
Block Puzzle is a free, open-source (MIT) puzzle game with no ads, no in-app
purchases, no accounts and no data collection. No login is needed; all
features are available immediately. The app downloads optional level packs
from a public GitHub repository (raw.githubusercontent.com) and is fully
playable offline. Source: https://github.com/fucad/block_puzzle
```

---

## 5. Graphics

| Asset | Spec | Status / source |
|---|---|---|
| App icon (Play) | 512×512 PNG, 32-bit | `docs/store/play/icon_512.png` (generated from `assets/icon/icon.png`) |
| App icon (App Store) | 1024×1024, no alpha | Built into the iOS app catalog (`remove_alpha_ios: true`); `assets/icon/icon.png` |
| Feature graphic (Play) | 1024×500 JPG/PNG, no alpha | `docs/store/play/feature_graphic.png` |
| Phone screenshots (Play) | 2–8, 9:16 | `docs/store/play/en/*.png`, `docs/store/play/ko/*.png` (1080×1920, 5 each) |
| iPhone 6.9" screenshots (App Store) | 1320×2868 portrait, 1–10 | `docs/store/ios/en/*.png`, `docs/store/ios/ko/*.png` (5 each) |

How they are produced: see `docs/SCREENSHOTS.md`.
