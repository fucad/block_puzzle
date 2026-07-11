import 'dart:ui';

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
  blockPalette: [
    Color(0xFFE94F4F), // 0 red
    Color(0xFF4FC356), // 1 green
    Color(0xFFF08A24), // 2 orange
    Color(0xFFF2C94C), // 3 yellow
    Color(0xFF3D7BF5), // 4 blue
    Color(0xFF9B51E0), // 5 purple
    Color(0xFF2FBFDE), // 6 cyan
    Color(0xFFEE5FA7), // 7 pink
  ],
  ghostOverlay: Color(0x66FFFFFF),
  lineHighlight: Color(0xAAFFF176),
  hudText: Color(0xFFFFFFFF),
  accent: Color(0xFFF2C94C),
);

const List<GameTheme> allThemes = [defaultTheme];

GameTheme themeById(String id) =>
    allThemes.firstWhere((t) => t.id == id, orElse: () => defaultTheme);
