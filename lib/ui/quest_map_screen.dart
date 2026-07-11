import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/quest.dart';
import '../state/providers.dart';
import '../state/quest_game_controller.dart';
import '../state/quest_providers.dart';
import 'quest_screen.dart';

/// The quest map: serpentine path of numbered level nodes (bottom-up like
/// the reference), hard levels in red, current node highlighted, trophy at
/// the top, and a pinned "Level N" play button.
class QuestMapScreen extends ConsumerWidget {
  const QuestMapScreen({super.key});

  static const _nodesPerRow = 5;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
                          'Quest',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 48),
                    ],
                  ),
                  const Icon(
                    Icons.emoji_events,
                    size: 64,
                    color: Color(0xFF22315E),
                  ),
                  const Text(
                    'Clear every level and win the trophy.',
                    style: TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: SingleChildScrollView(
                      reverse: true,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: _SerpentineGrid(
                        levels: levels,
                        currentIndex: currentIndex,
                        nodesPerRow: _nodesPerRow,
                        onTapCurrent: () => _play(context, ref, current!),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
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
                            : () => _play(context, ref, current),
                        child: Text(
                          current == null
                              ? 'All levels complete!'
                              : 'Level ${current.number}',
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

  void _play(BuildContext context, WidgetRef ref, _LevelNode node) {
    ref
        .read(questGameProvider.notifier)
        .start(node.pack, node.stage, levelNumber: node.number);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const QuestScreen()),
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

class _SerpentineGrid extends StatelessWidget {
  const _SerpentineGrid({
    required this.levels,
    required this.currentIndex,
    required this.nodesPerRow,
    required this.onTapCurrent,
  });

  final List<_LevelNode> levels;
  final int currentIndex;
  final int nodesPerRow;
  final VoidCallback onTapCurrent;

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    for (var start = 0; start < levels.length; start += nodesPerRow) {
      final chunk = levels.sublist(
        start,
        start + nodesPerRow > levels.length
            ? levels.length
            : start + nodesPerRow,
      );
      final rowIndex = start ~/ nodesPerRow;
      final ordered = rowIndex.isOdd ? chunk.reversed.toList() : chunk;
      rows.add(
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            for (final node in ordered)
              _NodeTile(
                node: node,
                isCurrent: node.number - 1 == currentIndex,
                onTap: node.number - 1 == currentIndex ? onTapCurrent : null,
              ),
          ],
        ),
      );
    }
    // Bottom-up: level 1 sits at the bottom of the scroll.
    return Column(
      children: [
        for (final row in rows.reversed) ...[row, const SizedBox(height: 14)],
      ],
    );
  }
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
        width: 52,
        height: 52,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(8),
          border: node.stage.hard
              ? Border.all(color: const Color(0xFFE05B3A), width: 2)
              : null,
          boxShadow: isCurrent
              ? const [BoxShadow(color: Color(0x88F2C94C), blurRadius: 12)]
              : null,
        ),
        child: Text(
          '${node.number}',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            color: numberColor,
          ),
        ),
      ),
    );
  }
}
