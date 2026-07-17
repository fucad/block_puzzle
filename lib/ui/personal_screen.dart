import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../state/providers.dart';

/// "Your Journey" — personal stats and trophy page.
///
/// Accessible from the main menu (treasure counter in the top-left).
/// Shows lifetime stats, personal bests, and how many quest stages have
/// been cleared (each stage cleared = one treasure found).
class PersonalScreen extends ConsumerWidget {
  const PersonalScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final save = ref.watch(saveDataProvider);
    final totalTreasures = save.questCompleted.values.fold(
      0,
      (sum, s) => sum + s.length,
    );
    // Total levels reached — cumulative across all packs.
    final highestLevelReached = save.questCompleted.values.fold(
      0,
      (sum, s) => sum + s.length,
    );

    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF3B4E8C), Color(0xFF2C3A6B)],
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
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // ── Treasures found ──────────────────────────────
                      _TreasureHero(count: totalTreasures),
                      const SizedBox(height: 24),

                      // ── Personal Bests ───────────────────────────────
                      _SectionHeader(label: 'Personal Bests'),
                      const SizedBox(height: 12),
                      _StatsGrid(
                        items: [
                          _StatItem(
                            icon: Icons.emoji_events_rounded,
                            iconColor: const Color(0xFFFFD700),
                            label: 'Classic\nHigh Score',
                            value: _fmt(save.classicHighScore),
                          ),
                          _StatItem(
                            icon: Icons.whatshot_rounded,
                            iconColor: const Color(0xFFFF6B35),
                            label: 'Highest\nCombo',
                            value: '×${save.allTimeBestCombo}',
                          ),
                          _StatItem(
                            icon: Icons.clear_all_rounded,
                            iconColor: const Color(0xFF56CCF2),
                            label: 'Best All-Clears\nin a Run',
                            value: '${save.bestAllClearsInRun}',
                          ),
                          _StatItem(
                            icon: Icons.map_rounded,
                            iconColor: const Color(0xFF6FCF97),
                            label: 'Levels\nBeaten',
                            value: '$highestLevelReached',
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // ── Lifetime Stats ───────────────────────────────
                      _SectionHeader(label: 'Lifetime Stats'),
                      const SizedBox(height: 12),
                      _StatsGrid(
                        items: [
                          _StatItem(
                            icon: Icons.grid_on_rounded,
                            iconColor: const Color(0xFFBB6BFF),
                            label: 'Blocks\nPlaced',
                            value: _fmt(save.totalBlocksPlaced),
                          ),
                          _StatItem(
                            icon: Icons.local_fire_department_rounded,
                            iconColor: const Color(0xFFFF8A00),
                            label: 'Combos\nDone',
                            value: _fmt(save.totalCombos),
                          ),
                          _StatItem(
                            icon: Icons.star_rounded,
                            iconColor: const Color(0xFFF2C94C),
                            label: 'Quest Stages\nCompleted',
                            value: '$totalTreasures',
                          ),
                          _StatItem(
                            icon: Icons.category_rounded,
                            iconColor: const Color(0xFF3FD9F5),
                            label: 'Packs\nUnlocked',
                            value: '${save.questCompleted.length}',
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),

                      // ── Zero-extraction reminder ─────────────────────
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

  String _fmt(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return '$n';
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
    duration: const Duration(milliseconds: 1800),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
      decoration: BoxDecoration(
        color: const Color(0x22F2C94C),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0x55F2C94C), width: 1.5),
      ),
      child: Column(
        children: [
          AnimatedBuilder(
            animation: _pulse,
            builder: (context, child) =>
                Transform.scale(scale: 1.0 + _pulse.value * 0.06, child: child),
            child: const Text('🏴‍☠️', style: TextStyle(fontSize: 64)),
          ),
          const SizedBox(height: 12),
          Text(
            '${widget.count}',
            style: const TextStyle(
              fontSize: 56,
              fontWeight: FontWeight.w900,
              color: Color(0xFFF2C94C),
              height: 1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            widget.count == 1 ? 'Treasure Found' : 'Treasures Found',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.white70,
              letterSpacing: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w800,
        color: Color(0xFF8899BB),
        letterSpacing: 2,
      ),
    );
  }
}

class _StatsGrid extends StatelessWidget {
  const _StatsGrid({required this.items});
  final List<_StatItem> items;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.6,
      children: items,
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0x22FFFFFF),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 28),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    height: 1.1,
                  ),
                ),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.white60,
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EthicsNote extends StatelessWidget {
  const _EthicsNote();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0x11FFFFFF),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Row(
        children: [
          Icon(Icons.favorite_rounded, color: Color(0xFFEB5757), size: 18),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Free forever. No ads. Open source.\nYour stats stay on your device only.',
              style: TextStyle(
                color: Colors.white54,
                fontSize: 12,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
