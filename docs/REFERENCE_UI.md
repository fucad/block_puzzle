# Reference UI notes (from Block Blast screenshots, 2026-07-11)

Observations from the 13 reference screenshots. We match the *feel and
feature set*, never the art or branding, and we strip everything
extraction-related: ad banners, "More Games", "New Skin Locked!" badges,
share buttons, Beta/NEW gimmick badges.

## Main menu
- Logo with a crown on top, playful multicolored lettering; tagline below
  ("Play daily, boost your brain!" style). Blue gradient background.
- Vertical button stack: **Quest** (orange, corner ribbon with countdown
  "6d22h" to the next pack), **Classic** (green, ∞ icon). Nothing else.

## Classic in-game (wood skin reference)
- Top bar: crown + all-time high score left, settings gear right.
- Current score huge, centered above the board; a heart/glow pulses behind
  it during combos.
- Board centered, rounded cells, subtle grid lines, theme-tinted dark board
  on themed background (wood grain / blue).
- Tray of 3 below the board at ~60% cell scale; empty slots stay empty
  until all three are played.

## Drag & drop
- While dragging, the piece renders at FULL board cell size, lifted well
  above the finger; the tray shows the vacated slot.
- Ghost preview snaps to the grid at the drop cell.
- Would-complete lines glow across the whole row/column while hovering
  (bright fill in the piece color, neon edge; multiple lines glow at once).

## Effects
- Line clear: colored sweep along each cleared line with flying square
  particles and spark/coin bursts per cell; "Combo" caption rides the wave.
- High combo: rainbow/gold glow frame around the entire board that persists
  while the streak is hot; ambient floating particles.
- Praise popups scale with the moment: "Good!" → "Unbelievable!", rendered
  in chunky rainbow letters mid-board, alongside "Combo N" and "+N" score
  popups (all-clear shows "+300").

## Quest mode
- HUD: back arrow left, gear right, "Level N" title center.
- Score goal: pill progress bar — current score in a blue bubble sliding
  toward the goal number in a dark circle (e.g. 42 → 700).
- Gem goal: gem icons top-center with remaining counts; a green ✓ replaces
  the count when that color is done (e.g. red ✓, purple "2").
- Gem cells: gold-framed blocks holding a star-shaped gem (red / purple)
  pre-placed in the stage layout.
- Mid-stage encouragement: red ribbon banner across the board with mascot,
  "80% Done".
- Fail screen: "So Close!" title, Score progress bar showing how far you
  got vs the goal, big green **Retry**, back arrow.

## Quest map
- Header "Adventure" (ours: Quest), trophy emblem at top with a short
  call-to-action line.
- Winding path of numbered square nodes (dozens per pack view), bottom-up
  progression; completed row rendered in a bright color, current node
  highlighted gold, **hard levels have a red border/number**.
- Big green "Level N" button pinned at the bottom to start the current
  stage.

## Combo Master (post-run summary)
- Gold sunburst screen with crown: "Combo Master" title,
  "Round Best — Combo 19", "All Time Combo — Combo 33", single continue
  button.

## Skins seen (theme system targets)
- Wood (tan blocks, wood-grain background), classic bright colors
  (per-piece colors, purple bg), brick (all-red brick blocks, light blue
  bg). One polished default first; the theme seam makes the rest
  contributions.
