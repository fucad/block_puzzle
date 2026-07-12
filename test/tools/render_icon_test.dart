@Tags(['icon-gen'])
library;

import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:block_puzzle/game/block_painter.dart';
import 'package:block_puzzle/models/game_theme.dart';
import 'package:flutter_test/flutter_test.dart';

/// One-shot generator for the app icon source images (all original art,
/// CC BY). Not part of the normal suite; run with:
///
///   flutter test test/tools/render_icon_test.dart --tags icon-gen
///   dart run flutter_launcher_icons
void main() {
  test('render app icon PNGs', () async {
    const side = 1024.0;

    Future<void> write(String path, bool background) async {
      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);

      if (background) {
        canvas.drawRRect(
          ui.RRect.fromRectAndRadius(
            const ui.Rect.fromLTWH(0, 0, side, side),
            const ui.Radius.circular(180),
          ),
          ui.Paint()
            ..shader = ui.Gradient.linear(
              const ui.Offset(side / 2, 0),
              const ui.Offset(side / 2, side),
              [defaultTheme.background, defaultTheme.boardBackground],
            ),
        );
      }

      // A 2×2 grid with three chunky blocks and one open cell: the game
      // in one glance. Foreground art stays inside the adaptive-icon
      // safe zone (66% circle) via larger margins.
      final margin = background ? 212.0 : 292.0;
      final gap = background ? 40.0 : 28.0;
      final cellSide = (side - margin * 2 - gap) / 2;
      final cells = [
        (0, 0, defaultTheme.blockPalette[0]), // red
        (0, 1, defaultTheme.blockPalette[4]), // blue
        (1, 0, defaultTheme.blockPalette[3]), // yellow
      ];
      for (final (row, col, color) in cells) {
        paintBlock(
          canvas,
          ui.Rect.fromLTWH(
            margin + col * (cellSide + gap),
            margin + row * (cellSide + gap),
            cellSide,
            cellSide,
          ),
          color,
        );
      }
      // The open cell, faint — reads as the next move.
      canvas.drawRRect(
        ui.RRect.fromRectAndRadius(
          ui.Rect.fromLTWH(
            margin + (cellSide + gap),
            margin + (cellSide + gap),
            cellSide,
            cellSide,
          ),
          ui.Radius.circular(cellSide * 0.16),
        ),
        ui.Paint()..color = const ui.Color(0x33FFFFFF),
      );

      final image = await recorder.endRecording().toImage(
        side.toInt(),
        side.toInt(),
      );
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      File(path)
        ..createSync(recursive: true)
        ..writeAsBytesSync(Uint8List.view(bytes!.buffer));
    }

    await write('assets/icon/icon.png', true);
    await write('assets/icon/icon_fg.png', false);
  });
}
