/// Gem colors used by quest-mode win conditions. A gem sits inside an
/// occupied cell and is collected when a line containing it clears.
enum GemColor { red, blue, purple, yellow, green }

/// One occupied board cell. Empty cells are represented as `null` in
/// [Board.cells], so this class only models occupancy.
class Cell {
  const Cell(this.colorId, {this.gem});

  /// Index into the active theme's block palette.
  final int colorId;

  final GemColor? gem;

  Map<String, Object?> toJson() => {
    'c': colorId,
    if (gem != null) 'g': gem!.name,
  };

  factory Cell.fromJson(Map<String, Object?> json) {
    final gemName = json['g'] as String?;
    return Cell(
      json['c'] as int,
      gem: gemName == null ? null : GemColor.values.byName(gemName),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is Cell && other.colorId == colorId && other.gem == gem;

  @override
  int get hashCode => Object.hash(colorId, gem);
}
