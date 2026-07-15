import 'dart:math';
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

/// Draws an 8-point gem star centered in [rect] with a highlight — shared
/// by the board and the tray so gems look identical everywhere.
void paintGemStar(Canvas canvas, Rect rect, Color color) {
  final center = rect.center;
  final outer = rect.shortestSide * 0.3;
  final inner = outer * 0.45;
  final path = Path();
  for (var i = 0; i < 16; i++) {
    final radius = i.isEven ? outer : inner;
    final angle = i * pi / 8 - pi / 2;
    final p = Offset(
      center.dx + radius * cos(angle),
      center.dy + radius * sin(angle),
    );
    i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
  }
  path.close();
  // Cheap solid offset shadow (no blur).
  canvas.save();
  canvas.translate(outer * 0.12, outer * 0.14);
  canvas.drawPath(path, Paint()..color = const Color(0x40000000));
  canvas.restore();
  canvas.drawPath(path, Paint()..color = color);
  canvas.drawCircle(
    center.translate(-outer * 0.25, -outer * 0.25),
    outer * 0.16,
    Paint()..color = const Color(0xAAFFFFFF),
  );
}
