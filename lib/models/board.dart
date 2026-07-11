import 'cell.dart';

/// Immutable 8×8 grid. Cells are stored row-major; `null` means empty.
/// All rule logic (placement, clearing) lives in `lib/systems/` — this class
/// only holds data and cheap queries.
class Board {
  Board._(this.cells);

  static const int size = 8;

  factory Board.empty() =>
      Board._(List<Cell?>.unmodifiable(List<Cell?>.filled(size * size, null)));

  /// [cells] must have length [size]²; row-major order.
  factory Board.fromCells(List<Cell?> cells) {
    assert(cells.length == size * size);
    return Board._(List<Cell?>.unmodifiable(cells));
  }

  final List<Cell?> cells;

  Cell? at(int row, int col) => cells[row * size + col];

  bool isOccupied(int row, int col) => at(row, col) != null;

  bool get isEmpty => cells.every((c) => c == null);

  /// Returns a new board with the given row-major-index updates applied.
  Board withUpdates(Map<int, Cell?> updates) {
    final next = List<Cell?>.of(cells);
    updates.forEach((index, cell) => next[index] = cell);
    return Board.fromCells(next);
  }

  List<Object?> toJson() => [for (final c in cells) c?.toJson()];

  factory Board.fromJson(List<Object?> json) => Board.fromCells([
    for (final c in json)
      c == null ? null : Cell.fromJson((c as Map).cast<String, Object?>()),
  ]);
}
