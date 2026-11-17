import 'package:flutter/material.dart';

/// Renders a 2-D grid of nullable colors as chunky, glossy game blocks —
/// the same visual language as the board pieces. Used for on-screen
/// decoration (trophies, chests, stat glyphs) so nothing looks like a
/// generic Material icon.
class BlockArt extends StatelessWidget {
  const BlockArt({
    super.key,
    required this.grid,
    this.cell = 10,
    this.gap = 1.5,
    this.glossy = true,
    this.radiusFactor = 0.24,
  });

  final List<List<Color?>> grid;
  final double cell;
  final double gap;
  final bool glossy;
  final double radiusFactor;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final row in grid)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final c in row)
                Container(
                  width: cell,
                  height: cell,
                  margin: EdgeInsets.all(gap),
                  decoration: c == null
                      ? null
                      : BoxDecoration(
                          borderRadius: BorderRadius.circular(
                            cell * radiusFactor,
                          ),
                          color: glossy ? null : c,
                          gradient: glossy
                              ? LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    Color.lerp(c, Colors.white, 0.38)!,
                                    c,
                                    Color.lerp(c, Colors.black, 0.22)!,
                                  ],
                                  stops: const [0, 0.5, 1],
                                )
                              : null,
                        ),
                ),
            ],
          ),
      ],
    );
  }
}

/// Pixel-grid glyphs drawn from blocks. `null` = empty cell.
abstract final class BlockGlyphs {
  static const Color? _ = null;

  static const _gold = Color(0xFFF2C94C);
  static const _goldLt = Color(0xFFFFE082);
  static const _brown = Color(0xFF8B5A2B);
  static const _brownDk = Color(0xFF5C3A1A);
  static const _amber = Color(0xFFFF8A00);
  static const _yellow = Color(0xFFFFCE00);
  static const _cyan = Color(0xFF56CCF2);

  /// Trophy cup — "Well Done".
  static const List<List<Color?>> trophy = [
    [_gold, _gold, _gold, _gold, _gold],
    [_gold, _gold, _gold, _gold, _gold],
    [_, _gold, _gold, _gold, _],
    [_, _, _gold, _, _],
    [_gold, _gold, _gold, _gold, _gold],
  ];

  /// Crown — new high score.
  static const List<List<Color?>> crown = [
    [_gold, _, _gold, _, _gold],
    [_gold, _goldLt, _gold, _goldLt, _gold],
    [_gold, _gold, _gold, _gold, _gold],
    [_, _gold, _gold, _gold, _],
  ];

  /// Lightning bolt — combo run.
  static const List<List<Color?>> bolt = [
    [_, _, _amber, _amber],
    [_, _amber, _amber, _],
    [_amber, _amber, _amber, _amber],
    [_, _amber, _amber, _],
    [_amber, _amber, _, _],
  ];

  /// Sparkle star — flawless / all-clear run.
  static const List<List<Color?>> star = [
    [_, _, _yellow, _, _],
    [_yellow, _yellow, _yellow, _yellow, _yellow],
    [_, _yellow, _yellow, _yellow, _],
    [_yellow, _yellow, _, _yellow, _yellow],
  ];

  /// Closed / locked treasure chest.
  static const List<List<Color?>> chestClosed = [
    [_brown, _brown, _brown, _brown, _brown, _brown],
    [_gold, _gold, _gold, _gold, _gold, _gold],
    [_brown, _brown, _gold, _gold, _brown, _brown],
    [_brown, _brown, _gold, _gold, _brown, _brown],
    [_brownDk, _brownDk, _brownDk, _brownDk, _brownDk, _brownDk],
  ];

  /// Open, overflowing treasure chest.
  static const List<List<Color?>> chestOpen = [
    [_, _goldLt, _, _goldLt, _, _goldLt],
    [_brown, _brown, _brown, _brown, _brown, _brown],
    [_gold, _goldLt, _gold, _gold, _goldLt, _gold],
    [_brown, _brown, _gold, _gold, _brown, _brown],
    [_brown, _brown, _gold, _gold, _brown, _brown],
    [_brownDk, _brownDk, _brownDk, _brownDk, _brownDk, _brownDk],
  ];

  /// Padlock — locked-treasure dialog.
  static const List<List<Color?>> lock = [
    [_, _cyan, _cyan, _cyan, _],
    [_cyan, _, _, _, _cyan],
    [_gold, _gold, _gold, _gold, _gold],
    [_gold, _gold, _brownDk, _gold, _gold],
    [_gold, _gold, _gold, _gold, _gold],
  ];
}
