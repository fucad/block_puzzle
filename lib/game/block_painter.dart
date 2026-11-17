import 'dart:math';
import 'dart:ui';

const _white = Color(0xFFFFFFFF);
const _black = Color(0xFF000000);

/// Draws one block cell in the glossy, puffy 3D style of the reference
/// skins: cells sit nearly flush (only a hair of dark shows where corners
/// meet), with a bright top-left, a shaded bottom-right, and a raised
/// inner face. Kept GPU-cheap — two gradient round-rects plus a gloss, no
/// per-cell path meshes — because the whole board repaints every frame.
/// Used by the board, tray pieces, and ghosts.
void paintBlock(Canvas canvas, Rect rect, Color color, {double opacity = 1}) {
  // Near-flush: a sliver of inset so adjacent rounded corners leave the
  // tidy little dark notches from the reference instead of a grid of gaps.
  final inset = rect.shortestSide * 0.015;
  final body = rect.deflate(inset);
  final side = body.shortestSide;
  final outerR = Radius.circular(side * 0.10);

  Color withA(Color c) => c.withValues(alpha: c.a * opacity);

  final light = Color.lerp(color, _white, 0.42)!;
  final dark = Color.lerp(color, _black, 0.34)!;

  // 1. Outer body: diagonal light→dark gives the directional 3D. The bevel
  //    border (revealed around the inner face below) reads as lit on the
  //    top-left and shadowed on the bottom-right.
  canvas.drawRRect(
    RRect.fromRectAndRadius(body, outerR),
    Paint()
      ..shader = Gradient.linear(
        body.topLeft,
        body.bottomRight,
        [withA(light), withA(color), withA(dark)],
        const [0.0, 0.55, 1.0],
      ),
  );

  // 2. Raised inner face: inset rounded rect, brighter at the top, that
  //    leaves the beveled border showing all around.
  final bevel = side * 0.13;
  final face = body.deflate(bevel);
  canvas.drawRRect(
    RRect.fromRectAndRadius(face, Radius.circular(face.shortestSide * 0.08)),
    Paint()
      ..shader = Gradient.linear(face.topCenter, face.bottomCenter, [
        withA(Color.lerp(color, _white, 0.20)!),
        withA(color),
      ]),
  );

  // 3. Gloss: a soft highlight blip in the top-left corner of the face.
  final gloss = Rect.fromLTWH(
    face.left + face.width * 0.10,
    face.top + face.height * 0.10,
    face.width * 0.42,
    face.height * 0.26,
  );
  canvas.drawRRect(
    RRect.fromRectAndRadius(gloss, Radius.circular(gloss.height)),
    Paint()..color = _white.withValues(alpha: 0.22 * opacity),
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
