// ignore_for_file: avoid_print
// Dev CLI: replay a classic run deterministically for bug reproduction.
//
//   dart run tool/simulate.dart <seed> [slot,row,col ...]
//
// Prints the tray and board after each placement. Pair with the app's
// --dart-define=SEED=<seed> to reproduce on-device runs move for move.
import 'package:block_puzzle/models/board.dart';
import 'package:block_puzzle/systems/game_engine.dart';

void main(List<String> args) {
  if (args.isEmpty) {
    print('usage: dart run tool/simulate.dart <seed> [slot,row,col ...]');
    return;
  }
  var state = GameEngine.newGame(int.parse(args.first));
  print('seed ${args.first}  tray: ${state.tray}');
  for (final move in args.skip(1)) {
    final [slot, row, col] = move.split(',').map(int.parse).toList();
    final outcome = GameEngine.place(state, slot, row, col);
    if (outcome == null) {
      print('ILLEGAL: $move');
      return;
    }
    state = outcome.state;
    final e = outcome.events;
    print(
      'move $move  +${e.scoreDelta} score=${state.score} '
      'combo=${e.combo} rows=${e.clearedRows} cols=${e.clearedCols}'
      '${e.allClear ? ' ALL-CLEAR' : ''}'
      '${e.trayRefilled ? '  tray: ${state.tray}' : ''}',
    );
    for (var r = 0; r < Board.size; r++) {
      print(
        '  ${[for (var c = 0; c < Board.size; c++) state.board.at(r, c) == null ? '.' : '#'].join()}',
      );
    }
    if (GameEngine.isGameOver(state)) print('GAME OVER');
  }
}
