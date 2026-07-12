@Tags(['icon-gen'])
library;

import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:block_puzzle/game/block_painter.dart';
import 'package:block_puzzle/models/game_theme.dart';
import 'package:flutter/painting.dart';
import 'package:flutter/services.dart' show FontLoader;
import 'package:flutter_test/flutter_test.dart';

/// One-shot generator for the fucad splash logo (original art, CC BY):
/// the 2×2 block motif from the app icon over a lowercase "fucad"
/// wordmark. Content stays inside the central ~62% circle so Android
/// 12's splash mask never clips it. Regenerate + apply with:
///
///   flutter test test/tools/render_splash_test.dart --tags icon-gen --run-skipped
///   dart run flutter_native_splash:create
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('render splash logo PNG', () async {
    // Real glyphs (the test-default Ahem font renders boxes).
    final fontFile = File(
      '${Platform.environment['FLUTTER_ROOT']}'
      '/bin/cache/artifacts/material_fonts/Roboto-Bold.ttf',
    );
    expect(fontFile.existsSync(), isTrue, reason: 'Roboto not in SDK cache');
    final loader = FontLoader('SplashRoboto')
      ..addFont(Future.value(ByteData.view(fontFile.readAsBytesSync().buffer)));
    await loader.load();

    const side = 1152.0;
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);

    // Block glyph: the icon's 2x2 motif, centered above the wordmark.
    const cell = 132.0;
    const gap = 18.0;
    const gridSide = cell * 2 + gap;
    const gridLeft = (side - gridSide) / 2;
    const gridTop = side / 2 - gridSide + 30;
    final cells = [
      (0, 0, defaultTheme.blockPalette[0]), // red
      (0, 1, defaultTheme.blockPalette[4]), // blue
      (1, 0, defaultTheme.blockPalette[3]), // yellow
    ];
    for (final (row, col, color) in cells) {
      paintBlock(
        canvas,
        ui.Rect.fromLTWH(
          gridLeft + col * (cell + gap),
          gridTop + row * (cell + gap),
          cell,
          cell,
        ),
        color,
      );
    }
    canvas.drawRRect(
      ui.RRect.fromRectAndRadius(
        ui.Rect.fromLTWH(
          gridLeft + cell + gap,
          gridTop + cell + gap,
          cell,
          cell,
        ),
        const ui.Radius.circular(cell * 0.16),
      ),
      ui.Paint()..color = const ui.Color(0x2EFFFFFF),
    );

    final wordmark = TextPainter(
      textDirection: TextDirection.ltr,
      text: const TextSpan(
        text: 'fucad',
        style: TextStyle(
          fontFamily: 'SplashRoboto',
          fontSize: 128,
          fontWeight: FontWeight.w700,
          letterSpacing: 6,
          color: ui.Color(0xFFFFFFFF),
        ),
      ),
    )..layout();
    wordmark.paint(
      canvas,
      ui.Offset((side - wordmark.width) / 2, gridTop + gridSide + 44),
    );

    final image = await recorder.endRecording().toImage(
      side.toInt(),
      side.toInt(),
    );
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    File('assets/branding/splash_logo.png')
      ..createSync(recursive: true)
      ..writeAsBytesSync(Uint8List.view(bytes!.buffer));
  });
}
