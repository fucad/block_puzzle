import 'package:block_puzzle/models/board.dart';
import 'package:block_puzzle/models/board_strings.dart';

/// Test-side aliases for the shared board string format
/// (lib/models/board_strings.dart): `.` empty, digit = colorId, letter =
/// gem cell (r/b/p/y/g).
Board boardFrom(List<String> rows) => parseBoardRows(rows);

/// Renders a board back to string form for readable assertion failures.
List<String> render(Board board) => renderBoardRows(board);
