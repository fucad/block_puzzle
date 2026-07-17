import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../state/providers.dart';
import '../state/quest_providers.dart';

class PersonalScreen extends ConsumerWidget {
  const PersonalScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final save = ref.watch(saveDataProvider);
    final catalog = ref.watch(questCatalogProvider).value;

    final totalTreasures = catalog == null
        ? 0
        : catalog.playable
              .where(
                (pack) =>
                    (save.questCompleted[pack.id]?.length ?? 0) >=
                    pack.stages.length,
              )
              .length;

    final levelsBeaten = save.questCompleted.values.fold(
      0,
      (sum, s) => sum + s.length,
    );

    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1A2540), Color(0xFF0D1526)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back_ios_new_rounded),
                      color: Colors.white70,
                    ),
                    const Expanded(
                      child: Text(
                        'Your Journey',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _TreasureHero(count: totalTreasures),
                      const SizedBox(height: 20),
                      _sectionLabel('Personal Bests'),
                      const SizedBox(height: 10),
                      _StatRow(items: [
                        _StatData(
                          pixels: _Icons.highScore,
                          label: 'High Score',
                          value: _fmt(save.classicHighScore),
                        ),
                        _StatData(
                          pixels: _Icons.combo,
                          label: 'Best Combo',
                          value: '×${save.allTimeBestCombo}',
                        ),
                      ]),
                      const SizedBox(height: 10),
                      _StatRow(items: [
                        _StatData(
                          pixels: _Icons.allClear,
                          label: 'Best All-Clears',
                          value: '${save.bestAllClearsInRun}',
                        ),
                        _StatData(
                          pixels: _Icons.levels,
                          label: 'Levels Beaten',
                          value: '$levelsBeaten',
                        ),
                      ]),
                      const SizedBox(height: 20),
                      _sectionLabel('Lifetime Stats'),
                      const SizedBox(height: 10),
                      _StatRow(items: [
                        _StatData(
                          pixels: _Icons.blocks,
                          label: 'Blocks Placed',
                          value: _fmt(save.totalBlocksPlaced),
                        ),
                        _StatData(
                          pixels: _Icons.combosTotal,
                          label: 'Combos Done',
                          value: _fmt(save.totalCombos),
                        ),
                      ]),
                      const SizedBox(height: 10),
                      _StatRow(items: [
                        _StatData(
                          pixels: _Icons.questStages,
                          label: 'Quest Stages',
                          value: '$levelsBeaten',
                        ),
                        _StatData(
                          pixels: _Icons.packs,
                          label: 'Packs Played',
                          value: '${save.questCompleted.length}',
                        ),
                      ]),
                      const SizedBox(height: 28),
                      const _EthicsNote(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Widget _sectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        text.toUpperCase(),
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: Color(0xFF5A6E99),
          letterSpacing: 2,
        ),
      ),
    );
  }

  static String _fmt(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return '$n';
  }
}

// ── Pixel art icons (game-piece shapes in stat colors) ────────────────────────

abstract final class _Icons {
  static const Color? _ = null;

  // L-piece gold → high score
  static const List<List<Color?>> highScore = [
    [Color(0xFFF2C94C), _, _, _],
    [Color(0xFFF2C94C), _, _, _],
    [Color(0xFFF2C94C), Color(0xFFF2C94C), _, _],
    [_, _, _, _],
  ];

  // T-piece orange → combo
  static const List<List<Color?>> combo = [
    [Color(0xFFFF8A00), Color(0xFFFF8A00), Color(0xFFFF8A00), _],
    [_, Color(0xFFFF8A00), _, _],
    [_, _, _, _],
    [_, _, _, _],
  ];

  // S-piece cyan → all-clear
  static const List<List<Color?>> allClear = [
    [_, Color(0xFF56CCF2), Color(0xFF56CCF2), _],
    [Color(0xFF56CCF2), Color(0xFF56CCF2), _, _],
    [_, _, _, _],
    [_, _, _, _],
  ];

  // I-piece green (horizontal) → levels
  static const List<List<Color?>> levels = [
    [_, _, _, _],
    [Color(0xFF6FCF97), Color(0xFF6FCF97), Color(0xFF6FCF97), Color(0xFF6FCF97)],
    [_, _, _, _],
    [_, _, _, _],
  ];

  // O-piece purple → blocks placed
  static const List<List<Color?>> blocks = [
    [_, _, _, _],
    [_, Color(0xFFA43BFF), Color(0xFFA43BFF), _],
    [_, Color(0xFFA43BFF), Color(0xFFA43BFF), _],
    [_, _, _, _],
  ];

  // Z-piece red → combos total
  static const List<List<Color?>> combosTotal = [
    [Color(0xFFEB5757), Color(0xFFEB5757), _, _],
    [_, Color(0xFFEB5757), Color(0xFFEB5757), _],
    [_, _, _, _],
    [_, _, _, _],
  ];

  // J-piece yellow → quest stages
  static const List<List<Color?>> questStages = [
    [_, _, Color(0xFFFFCE00), _],
    [_, _, Color(0xFFFFCE00), _],
    [_, Color(0xFFFFCE00), Color(0xFFFFCE00), _],
    [_, _, _, _],
  ];

  // I-piece blue (vertical) → packs
  static const List<List<Color?>> packs = [
    [_, _, Color(0xFF2B82FF), _],
    [_, _, Color(0xFF2B82FF), _],
    [_, _, Color(0xFF2B82FF), _],
    [_, _, Color(0xFF2B82FF), _],
  ];
}

// Renders a 2-D grid of colored block-pixels.
class _PixelArt extends StatelessWidget {
  const _PixelArt({required this.pixels, this.px = 8.0});
  final List<List<Color?>> pixels;
  final double px;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final row in pixels)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final color in row)
                SizedBox(
                  width: px,
                  height: px,
                  child: color == null
                      ? null
                      : Container(
                          margin: EdgeInsets.all(px * 0.1),
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius: BorderRadius.circular(px * 0.22),
                          ),
                        ),
            ),
            ],
          ),
      ],
    );
  }
}

// ── Treasure hero ─────────────────────────────────────────────────────────────

// Block-drawn treasure chest (6×5 pixel grid).
class _BlockChest extends StatelessWidget {
  const _BlockChest({this.size = 60.0});
  final double size;

  static const List<List<Color>> _pixels = [
    [Color(0xFFF2C94C), Color(0xFFF2C94C), Color(0xFFF2C94C), Color(0xFFF2C94C), Color(0xFFF2C94C), Color(0xFFF2C94C)],
    [Color(0xFFFFE082), Color(0xFFFFE082), Color(0xFFFFE082), Color(0xFFFFE082), Color(0xFFFFE082), Color(0xFFFFE082)],
    [Color(0xFF8B5A2B), Color(0xFF8B5A2B), Color(0xFFF2C94C), Color(0xFFF2C94C), Color(0xFF8B5A2B), Color(0xFF8B5A2B)],
    [Color(0xFF8B5A2B), Color(0xFF8B5A2B), Color(0xFFF2C94C), Color(0xFFF2C94C), Color(0xFF8B5A2B), Color(0xFF8B5A2B)],
    [Color(0xFF5C3A1A), Color(0xFF5C3A1A), Color(0xFF5C3A1A), Color(0xFF5C3A1A), Color(0xFF5C3A1A), Color(0xFF5C3A1A)],
  ];

  @override
  Widget build(BuildContext context) {
    final px = size / 6;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final row in _pixels)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final color in row)
                Container(
                  width: px,
                  height: px,
                  margin: EdgeInsets.all(px * 0.06),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(px * 0.2),
                  ),
                ),
            ],
          ),
      ],
    );
  }
}

class _TreasureHero extends StatefulWidget {
  const _TreasureHero({required this.count});
  final int count;

  @override
  State<_TreasureHero> createState() => _TreasureHeroState();
}

class _TreasureHeroState extends State<_TreasureHero>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2000),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
      decoration: BoxDecoration(
        color: const Color(0x18F2C94C),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0x44F2C94C), width: 1.5),
      ),
      child: Row(
        children: [
          AnimatedBuilder(
            animation: _pulse,
            builder: (_, child) => Transform.scale(
              scale: 1.0 + _pulse.value * 0.07,
              child: child,
            ),
            child: const _BlockChest(size: 64),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${widget.count}',
                  style: const TextStyle(
                    fontSize: 52,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFFF2C94C),
                    height: 1,
                  ),
                ),
                Text(
                  widget.count == 1 ? 'Treasure Found' : 'Treasures Found',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white54,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Complete a full pack to earn one',
                  style: TextStyle(fontSize: 11, color: Color(0x88F2C94C)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Stat row / card ───────────────────────────────────────────────────────────

class _StatData {
  const _StatData({
    required this.pixels,
    required this.label,
    required this.value,
  });
  final List<List<Color?>> pixels;
  final String label;
  final String value;
}

class _StatRow extends StatelessWidget {
  const _StatRow({required this.items});
  final List<_StatData> items;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < items.length; i++) ...[
          Expanded(child: _StatCard(data: items[i])),
          if (i < items.length - 1) const SizedBox(width: 10),
        ],
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.data});
  final _StatData data;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF1C2C4A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0x1AFFFFFF), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Block-pixel icon in a tinted square container.
          Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0x14FFFFFF),
              borderRadius: BorderRadius.circular(10),
            ),
            child: _PixelArt(pixels: data.pixels, px: 8),
          ),
          const SizedBox(height: 10),
          Text(
            data.value,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              height: 1,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            data.label,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.white38,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Ethics note ───────────────────────────────────────────────────────────────

class _EthicsNote extends StatelessWidget {
  const _EthicsNote();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0x0DFFFFFF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0x0FFFFFFF), width: 1),
      ),
      child: const Row(
        children: [
          Icon(Icons.favorite_rounded, color: Color(0xFFEB5757), size: 16),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Free forever. No ads. Open source.\nYour stats stay on your device only.',
              style: TextStyle(color: Colors.white38, fontSize: 12, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}
