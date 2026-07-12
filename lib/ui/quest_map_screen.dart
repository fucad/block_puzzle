import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/quest.dart';
import '../state/providers.dart';
import '../state/quest_game_controller.dart';
import '../state/quest_providers.dart';
import 'quest_screen.dart';

/// The quest map as a treasure hunt: a dashed golden trail winds bottom-up
/// through every level node — across all released packs — and ends at a
/// treasure chest that opens when the last level is cleared (a pure
/// achievement; it grants nothing, per the zero-extraction rules).
class QuestMapScreen extends ConsumerStatefulWidget {
  const QuestMapScreen({super.key});

  @override
  ConsumerState<QuestMapScreen> createState() => _QuestMapScreenState();
}

class _QuestMapScreenState extends ConsumerState<QuestMapScreen> {
  final _scroll = ScrollController();
  bool _jumped = false;

  static const _perRow = 4;
  static const _rowHeight = 96.0;
  static const _chestArea = 170.0;
  static const _bottomPad = 28.0;
  static const _colFractions = [0.15, 0.38, 0.62, 0.85];

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  Offset _nodeCenter(int index, double width, double totalHeight) {
    final row = index ~/ _perRow;
    final idx = index % _perRow;
    final col = row.isEven ? idx : _perRow - 1 - idx; // serpentine
    return Offset(
      width * _colFractions[col],
      totalHeight - _bottomPad - row * _rowHeight - _rowHeight / 2,
    );
  }

  /// With reverse:true, offset 0 shows the bottom (level 1); jump so the
  /// current level sits comfortably in view.
  void _jumpToCurrent(double distFromBottom) {
    if (_jumped || !_scroll.hasClients) return;
    _jumped = true;
    final viewport = _scroll.position.viewportDimension;
    _scroll.jumpTo(
      (distFromBottom - viewport * 0.45).clamp(
        0.0,
        _scroll.position.maxScrollExtent,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(themeProvider);
    final catalog = ref.watch(questCatalogProvider);
    final completed = ref.watch(saveDataProvider).questCompleted;

    return Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(theme.background.toARGB32()),
              Color(theme.backgroundAccent.toARGB32()),
            ],
          ),
        ),
        child: SafeArea(
          child: catalog.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(
              child: Text(
                'Quest content unavailable\n$e',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70),
              ),
            ),
            data: (data) {
              final levels = <_LevelNode>[];
              var number = 1;
              for (final pack in data.playable) {
                for (final stage in pack.stages) {
                  levels.add(
                    _LevelNode(
                      number: number++,
                      pack: pack,
                      stage: stage,
                      done: completed[pack.id]?.contains(stage.id) ?? false,
                    ),
                  );
                }
              }
              final currentIndex = levels.indexWhere((n) => !n.done);
              final current = currentIndex == -1 ? null : levels[currentIndex];
              final allDone = levels.isNotEmpty && current == null;

              return Column(
                children: [
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back_ios_new_rounded),
                        color: Colors.white70,
                      ),
                      const Expanded(
                        child: Text(
                          'Treasure Hunt',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 48),
                    ],
                  ),
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final width = constraints.maxWidth;
                        final rows = (levels.length + _perRow - 1) ~/ _perRow;
                        final totalHeight =
                            _chestArea + rows * _rowHeight + _bottomPad;
                        final centers = [
                          for (var i = 0; i < levels.length; i++)
                            _nodeCenter(i, width, totalHeight),
                        ];
                        final chestCenter = Offset(width / 2, _chestArea * 0.5);

                        if (currentIndex >= 0) {
                          WidgetsBinding.instance.addPostFrameCallback(
                            (_) => _jumpToCurrent(
                              totalHeight - centers[currentIndex].dy,
                            ),
                          );
                        }

                        return SingleChildScrollView(
                          controller: _scroll,
                          reverse: true,
                          child: SizedBox(
                            width: width,
                            height: totalHeight,
                            child: Stack(
                              clipBehavior: Clip.none,
                              children: [
                                CustomPaint(
                                  size: Size(width, totalHeight),
                                  painter: _TrailPainter(
                                    points: [...centers, chestCenter],
                                    litUpTo: allDone
                                        ? centers.length
                                        : currentIndex,
                                  ),
                                ),
                                for (final (i, node) in levels.indexed)
                                  Positioned(
                                    left: centers[i].dx - 27,
                                    top: centers[i].dy - 27,
                                    child: _NodeTile(
                                      node: node,
                                      isCurrent: i == currentIndex,
                                      onTap: i == currentIndex
                                          ? () => _play(context, node)
                                          : null,
                                    ),
                                  ),
                                Positioned(
                                  left: chestCenter.dx - 44,
                                  top: chestCenter.dy - 44,
                                  child: _TreasureChest(
                                    open: allDone,
                                    onTap: () => _chestDialog(
                                      context,
                                      allDone,
                                      levels.length,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: SizedBox(
                      width: 260,
                      height: 60,
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF43A047),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        onPressed: current == null
                            ? null
                            : () => _play(context, current),
                        child: Text(
                          allDone
                              ? 'Treasure found!'
                              : 'Level ${current!.number}',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  void _play(BuildContext context, _LevelNode node) {
    ref
        .read(questGameProvider.notifier)
        .start(node.pack, node.stage, levelNumber: node.number);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const QuestScreen()),
    );
  }

  void _chestDialog(BuildContext context, bool open, int total) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(open ? 'Treasure Hunter!' : 'Locked treasure'),
        content: Text(
          open
              ? 'You cleared all $total levels — the whole trail is yours. '
                    'New packs arrive right here when they release.'
              : 'Clear all $total levels of the trail to open the chest.',
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: Text(open ? 'Glorious' : 'On it'),
          ),
        ],
      ),
    );
  }
}

class _LevelNode {
  const _LevelNode({
    required this.number,
    required this.pack,
    required this.stage,
    required this.done,
  });

  final int number;
  final QuestPack pack;
  final QuestStage stage;
  final bool done;
}

/// Dashed trail through the node centers up to the chest. The walked part
/// (behind the current level) is bright; the rest is faint.
class _TrailPainter extends CustomPainter {
  const _TrailPainter({required this.points, required this.litUpTo});

  final List<Offset> points;

  /// Number of leading points already reached (lit segment count).
  final int litUpTo;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) return;
    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (var i = 1; i < points.length - 1; i++) {
      final mid = (points[i] + points[i + 1]) / 2;
      path.quadraticBezierTo(points[i].dx, points[i].dy, mid.dx, mid.dy);
    }
    path.lineTo(points.last.dx, points.last.dy);

    // Where along the path the lit part ends, as a fraction of points.
    final litFraction = litUpTo <= 0
        ? 0.0
        : (litUpTo / (points.length - 1)).clamp(0.0, 1.0);

    for (final metric in path.computeMetrics()) {
      final litLength = metric.length * litFraction;
      const dash = 12.0;
      const gap = 9.0;
      var distance = 0.0;
      while (distance < metric.length) {
        final end = (distance + dash).clamp(0.0, metric.length);
        final lit = distance < litLength;
        canvas.drawPath(
          metric.extractPath(distance, end),
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = lit ? 5 : 4
            ..strokeCap = StrokeCap.round
            ..color = lit ? const Color(0xFFF2C94C) : const Color(0x3AFFFFFF),
        );
        distance = end + gap;
      }
    }
  }

  @override
  bool shouldRepaint(_TrailPainter old) =>
      old.litUpTo != litUpTo || old.points.length != points.length;
}

class _NodeTile extends StatelessWidget {
  const _NodeTile({required this.node, required this.isCurrent, this.onTap});

  final _LevelNode node;
  final bool isCurrent;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final Color background;
    final Color numberColor;
    if (isCurrent) {
      background = const Color(0xFFF2C94C);
      numberColor = const Color(0xFF7A2E12);
    } else if (node.done) {
      background = const Color(0xFF7FE3F0);
      numberColor = const Color(0xFF10586B);
    } else {
      background = const Color(0xFF22315E);
      numberColor = node.stage.hard
          ? const Color(0xFFE05B3A)
          : const Color(0xFF6C7BB0);
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 54,
        height: 54,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: background,
          shape: BoxShape.circle,
          border: node.stage.hard
              ? Border.all(color: const Color(0xFFE05B3A), width: 2.5)
              : Border.all(color: const Color(0x33FFFFFF), width: 1.5),
          boxShadow: isCurrent
              ? const [BoxShadow(color: Color(0x99F2C94C), blurRadius: 16)]
              : null,
        ),
        child: Text(
          '${node.number}',
          style: TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.w900,
            color: numberColor,
          ),
        ),
      ),
    );
  }
}

/// The prize at the end of the trail. Achievement only — it never grants
/// anything, so it never needs to sell anything.
class _TreasureChest extends StatelessWidget {
  const _TreasureChest({required this.open, required this.onTap});

  final bool open;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 88,
        height: 88,
        child: CustomPaint(painter: _ChestPainter(open: open)),
      ),
    );
  }
}

class _ChestPainter extends CustomPainter {
  const _ChestPainter({required this.open});

  final bool open;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final wood = Paint()..color = const Color(0xFF8B5A2B);
    final woodDark = Paint()..color = const Color(0xFF6E4520);
    final gold = Paint()..color = const Color(0xFFF2C94C);

    if (open) {
      // Glow + escaping sparkles.
      canvas.drawCircle(
        Offset(w / 2, h * 0.45),
        w * 0.5,
        Paint()
          ..color = const Color(0x66FFE082)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18),
      );
      for (final (dx, dy, r) in [
        (0.28, 0.18, 3.5),
        (0.5, 0.08, 5.0),
        (0.72, 0.2, 3.0),
      ]) {
        canvas.drawCircle(Offset(w * dx, h * dy), r, gold);
      }
      // Lid tipped back.
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(w * 0.16, h * 0.26, w * 0.68, h * 0.14),
          const Radius.circular(6),
        ),
        woodDark,
      );
    } else {
      // Closed lid (rounded top).
      canvas.drawRRect(
        RRect.fromRectAndCorners(
          Rect.fromLTWH(w * 0.14, h * 0.3, w * 0.72, h * 0.22),
          topLeft: const Radius.circular(14),
          topRight: const Radius.circular(14),
        ),
        woodDark,
      );
    }

    // Body.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.14, h * 0.48, w * 0.72, h * 0.34),
        const Radius.circular(7),
      ),
      wood,
    );
    // Gold band + clasp.
    canvas.drawRect(
      Rect.fromLTWH(w * 0.44, h * (open ? 0.48 : 0.3), w * 0.12, h * 0.52),
      gold,
    );
    canvas.drawCircle(
      Offset(w / 2, h * 0.58),
      w * 0.07,
      Paint()..color = open ? const Color(0xFFFFF3C0) : const Color(0xFF4A2F12),
    );
  }

  @override
  bool shouldRepaint(_ChestPainter old) => old.open != open;
}
