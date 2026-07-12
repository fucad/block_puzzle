/// All gameplay tuning constants in one place. See ARCHITECTURE.md for how
/// each feeds into the rules; change values here, not at call sites.
library;

const int boardSize = 8;
const int traySize = 3;

/// Points per cell of a placed piece.
const int pointsPerCell = 1;

/// Base for line-clear scoring: clearing `n` lines in one placement scores
/// `lineClearBase * n * (n + 1) / 2` (10 / 30 / 60 / 100...), so one
/// multi-line clear beats the same lines cleared separately.
const int lineClearBase = 10;

/// Bonus per combo level past the first, added on each clearing placement.
const int comboBonusPerLevel = 10;

/// Awarded when a clear leaves the board completely empty.
const int allClearBonus = 300;

/// Weight multiplier for catalog pieces that do NOT currently fit on the
/// board — biases tray generation lightly toward playable pieces.
const double fitPenalty = 0.15;

/// Weight multiplier for pieces that could complete a line right now.
/// Breaking lines is the game's core satisfaction, so "breaker" pieces
/// show up noticeably more often.
const double breakerBoost = 3.0;

/// How many candidate tray sets to draw looking for one that is fully
/// playable in sequence (and ideally contains a breaker) before settling.
const int traySetDrawAttempts = 6;

/// Search budget for canPlaceAllInSomeOrder; past this, assume playable.
const int solvabilityNodeCap = 1500;
