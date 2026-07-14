import 'dart:ui';

import 'cell.dart';

/// Gem tints are semantic (shared by all themes' HUDs and boards).
const Map<GemColor, Color> gemColors = {
  GemColor.red: Color(0xFFE53935),
  GemColor.blue: Color(0xFF29B6F6),
  GemColor.purple: Color(0xFFCE5FFF),
  GemColor.yellow: Color(0xFFFFD835),
  GemColor.green: Color(0xFF66DD66),
};

/// Blocks that carry a gem render in gold regardless of theme palette.
const Color gemBlockGold = Color(0xFFE8B454);

/// Visual skin for the board and blocks. All rendering colors come from
/// here so new themes are pure data (a contribution target — never locked
/// or paywalled). Ship one polished default now.
class GameTheme {
  const GameTheme({
    required this.id,
    required this.name,
    required this.background,
    required this.backgroundAccent,
    required this.boardBackground,
    required this.emptyCell,
    required this.gridLine,
    required this.blockPalette,
    required this.ghostOverlay,
    required this.lineHighlight,
    required this.hudText,
    required this.accent,
  });

  final String id;
  final String name;

  /// Screen background gradient (top → bottom).
  final Color background;
  final Color backgroundAccent;

  final Color boardBackground;
  final Color emptyCell;
  final Color gridLine;

  /// Block colors indexed by Piece.colorId / Cell.colorId (8 entries).
  final List<Color> blockPalette;

  /// Translucent fill for the snapped ghost preview.
  final Color ghostOverlay;

  /// Glow tint for rows/columns that would complete at the hover position.
  final Color lineHighlight;

  final Color hudText;
  final Color accent;

  Color blockColor(int colorId) => blockPalette[colorId % blockPalette.length];
}

/// Classic bright-blocks-on-deep-blue look (reference: the default Block
/// Blast skin).
const GameTheme defaultTheme = GameTheme(
  id: 'default',
  name: 'Classic',
  background: Color(0xFF3B4E8C),
  backgroundAccent: Color(0xFF2C3A6B),
  boardBackground: Color(0xFF232F56),
  emptyCell: Color(0xFF2B3963),
  gridLine: Color(0xFF1C2645),
  // Brightened after playtest feedback (2026-07-14): the original set
  // read too dark on real phone panels next to genre peers.
  blockPalette: [
    Color(0xFFFF6161), // 0 red
    Color(0xFF59D96A), // 1 green
    Color(0xFFFFA033), // 2 orange
    Color(0xFFFFD84D), // 3 yellow
    Color(0xFF4D9BFF), // 4 blue
    Color(0xFFBB6BFF), // 5 purple
    Color(0xFF3FD9F5), // 6 cyan
    Color(0xFFFF7BC4), // 7 pink
  ],
  ghostOverlay: Color(0x66FFFFFF),
  lineHighlight: Color(0xAAFFF176),
  hudText: Color(0xFFFFFFFF),
  accent: Color(0xFFF2C94C),
);

const List<GameTheme> allThemes = [defaultTheme];

GameTheme themeById(String id) =>
    allThemes.firstWhere((t) => t.id == id, orElse: () => defaultTheme);
