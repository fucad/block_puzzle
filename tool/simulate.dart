// ignore_for_file: avoid_print
// Dev CLI: replay a run deterministically for bug reproduction and quest
// authoring.
//
//   dart run tool/simulate.dart <seed> [slot,row,col ...]
//   dart run tool/simulate.dart <seed> --stage <pack.json>:<stageId> [moves]
//
// Prints the tray and board after each placement. Pair with the app's
// --dart-define=SEED=<seed> to reproduce on-device classic runs; quest
// stages with a pinned seed replay identically in the app.
import 'dart:convert';
import 'dart:io';

import 'package:block_puzzle/models/board.dart';
import 'package:block_puzzle/models/game_state.dart';
import 'package:block_puzzle/models/quest.dart';
import 'package:block_puzzle/systems/game_engine.dart';

void main(List<String> args) {
  if (args.isEmpty) {
    print(
      'usage: dart run tool/simulate.dart <seed> '
      '[--stage <pack.json>:<stageId>] [slot,row,col ...]',
    );
    return;
  }
  final seed = int.parse(args.first);
  var moves = args.skip(1).toList();

  Board? board;
  QuestStage? stage;
  if (moves.isNotEmpty && moves.first == '--stage') {
    final [file, stageId] = moves[1].split(':');
    final pack = QuestPack.fromJson(
      (jsonDecode(File(file).readAsStringSync()) as Map)
          .cast<String, Object?>(),
    );
    stage = pack.stages.firstWhere((s) => s.id == stageId);
    board = stage.board;
    print('stage $stageId  goal: ${stage.goal}  pinned seed: ${stage.seed}');
    moves = moves.sublist(2);
  }

  var state = GameEngine.newGame(seed, board: board);
  print('seed $seed  tray: ${state.tray}');
  _printBoard(state);
  for (final move in moves) {
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
      'combo=${e.combo} rows=${e.clearedRows} cols=${e.clearedCols} '
      'gems=${state.gemsCollected}'
      '${e.allClear ? ' ALL-CLEAR' : ''}'
      '${e.trayRefilled ? '  tray: ${state.tray}' : ''}',
    );
    _printBoard(state);
    if (GameEngine.isGameOver(state)) print('GAME OVER');
  }
}

void _printBoard(GameState state) {
  for (var r = 0; r < Board.size; r++) {
    print(
      '  ${[for (var c = 0; c < Board.size; c++) state.board.at(r, c) == null ? '.' : '#'].join()}',
    );
  }
}
