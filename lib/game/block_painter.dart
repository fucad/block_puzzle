import 'dart:ui';

/// Draws one block cell in the shared beveled style: rounded fill with a
/// lighter top edge and darker bottom edge, matching the chunky look of
/// the reference skins. Used by the board, tray pieces, and ghosts.
void paintBlock(Canvas canvas, Rect rect, Color color, {double opacity = 1}) {
  final inset = rect.shortestSide * 0.045;
  final r = Radius.circular(rect.shortestSide * 0.16);
  final body = rect.deflate(inset);
  final rrect = RRect.fromRectAndRadius(body, r);

  Color withA(Color c) => c.withValues(alpha: c.a * opacity);

  canvas.drawRRect(rrect, Paint()..color = withA(color));

  final bevel = body.height * 0.22;
  final top = Path()
    ..addRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(body.left, body.top, body.width, bevel),
        r,
      ),
    );
  canvas.drawPath(
    top,
    Paint()..color = withA(Color.lerp(color, const Color(0xFFFFFFFF), .35)!),
  );
  final bottom = Path()
    ..addRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(body.left, body.bottom - bevel, body.width, bevel),
        r,
      ),
    );
  canvas.drawPath(
    bottom,
    Paint()..color = withA(Color.lerp(color, const Color(0xFF000000), .25)!),
  );
}
