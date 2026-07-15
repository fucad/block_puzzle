/// Gem colors used by quest-mode win conditions. A gem sits inside an
/// occupied cell and is collected when a line containing it clears.
enum GemColor { red, blue, purple, yellow, green }

/// One occupied board cell. Empty cells are represented as `null` in
/// [Board.cells], so this class only models occupancy.
class Cell {
  const Cell(this.colorId, {this.gem, this.preplaced = false});

  /// Index into the active theme's block palette.
  final int colorId;

  final GemColor? gem;

  /// True for a quest stage's pre-placed puzzle blocks (and gem cells),
  /// as opposed to blocks the player dropped. Pre-placed cells render in
  /// one neutral light color so gems and the puzzle read as a unit and
  /// the player's own vivid pieces stand out against it.
  final bool preplaced;

  Map<String, Object?> toJson() => {
    'c': colorId,
    if (gem != null) 'g': gem!.name,
    if (preplaced) 'p': true,
  };

  factory Cell.fromJson(Map<String, Object?> json) {
    final gemName = json['g'] as String?;
    return Cell(
      json['c'] as int,
      gem: gemName == null ? null : GemColor.values.byName(gemName),
      preplaced: json['p'] as bool? ?? false,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is Cell &&
      other.colorId == colorId &&
      other.gem == gem &&
      other.preplaced == preplaced;

  @override
  int get hashCode => Object.hash(colorId, gem, preplaced);
}
