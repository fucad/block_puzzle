import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../state/classic_game_controller.dart';
import '../state/providers.dart';
import '../state/quest_providers.dart';
import 'classic_screen.dart';
import 'personal_screen.dart';
import 'quest_map_screen.dart';
import 'settings_sheet.dart';

class MainMenuScreen extends ConsumerWidget {
  const MainMenuScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeProvider);
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
          child: Stack(
            children: [
              // Decorative block grid in the background.
              const Positioned.fill(child: _DecorativeBlocks()),

              // Top-left: treasure counter.
              Positioned(
                top: 4,
                left: 4,
                child: _TreasureButton(
                  count: totalTreasures,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const PersonalScreen()),
                  ),
                ),
              ),

              // Top-right: settings.
              Positioned(
                top: 4,
                right: 4,
                child: IconButton(
                  onPressed: () => showSettingsSheet(context),
                  icon: const Icon(Icons.settings_rounded),
                  color: Colors.white54,
                  iconSize: 28,
                ),
              ),

              // Center content.
              Center(
                child: Column(
                  children: [
                    const Spacer(flex: 2),
                    const _LogoBlock(),
                    const Spacer(),
                    const _Tagline(),
                    const Spacer(flex: 2),
                    _MenuButton(
                      label: 'Quest',
                      icon: Icons.explore_rounded,
                      color: const Color(0xFFF2994A),
                      onPressed:
                          ref
                                  .watch(questCatalogProvider)
                                  .value
                                  ?.playable
                                  .isNotEmpty ??
                              false
                          ? () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const QuestMapScreen(),
                              ),
                            )
                          : null,
                      badge: _questBadge(ref, totalTreasures),
                      goldBadge: _questAllDone(ref, totalTreasures),
                    ),
                    const SizedBox(height: 16),
                    _MenuButton(
                      label: 'Classic',
                      icon: Icons.all_inclusive_rounded,
                      color: const Color(0xFF27AE60),
                      onPressed: () {
                        if (ref.read(classicGameProvider) == null) {
                          ref.read(classicGameProvider.notifier).startNew();
                        }
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ClassicScreen(),
                          ),
                        );
                      },
                    ),
                    const Spacer(flex: 2),

                    // Feedback button at the bottom.
                    TextButton.icon(
                      onPressed: () => _showFeedbackSheet(context),
                      icon: const Icon(
                        Icons.feedback_rounded,
                        size: 18,
                        color: Colors.white38,
                      ),
                      label: const Text(
                        'Share Feedback',
                        style: TextStyle(color: Colors.white38, fontSize: 13),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String? _questCountdown(WidgetRef ref) {
  final next = ref.watch(questCatalogProvider).value?.nextUpcoming?.releaseDate;
  if (next == null) return null;
  final left = next.difference(DateTime.now().toUtc());
  if (left.isNegative) return null;
  return '${left.inDays}d ${left.inHours % 24}h';
}

bool _questAllDone(WidgetRef ref, int totalTreasures) {
  final catalog = ref.watch(questCatalogProvider).value;
  return catalog != null &&
      catalog.playable.isNotEmpty &&
      totalTreasures >= catalog.playable.length;
}

String? _questBadge(WidgetRef ref, int totalTreasures) {
  if (_questAllDone(ref, totalTreasures)) return '★ All Done';
  return _questCountdown(ref);
}

void _showFeedbackSheet(BuildContext context) {
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: const Color(0xFF1A2540),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 8),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Share Feedback',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          ListTile(
            leading: const Icon(
              Icons.bug_report_rounded,
              color: Color(0xFF56CCF2),
            ),
            title: const Text(
              'GitHub Issues',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
            subtitle: const Text(
              'Report bugs or feature requests',
              style: TextStyle(color: Colors.white54),
            ),
            onTap: () {
              Navigator.pop(ctx);
              launchUrl(
                Uri.parse(
                  'https://github.com/fucad/block_puzzle/issues/new',
                ),
                mode: LaunchMode.externalApplication,
              );
            },
          ),
          ListTile(
            leading: const Icon(
              Icons.email_rounded,
              color: Color(0xFFF2C94C),
            ),
            title: const Text(
              'Send Email',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
            subtitle: const Text(
              'dal001.dev@gmail.com',
              style: TextStyle(color: Colors.white54),
            ),
            onTap: () {
              Navigator.pop(ctx);
              launchUrl(
                Uri(
                  scheme: 'mailto',
                  path: 'dal001.dev@gmail.com',
                  queryParameters: {
                    'subject': '[Block Puzzle] Feedback',
                  },
                ),
                mode: LaunchMode.externalApplication,
              );
            },
          ),
          const SizedBox(height: 8),
        ],
      ),
    ),
  );
}

// ── Logo ─────────────────────────────────────────────────────────────────────

class _LogoBlock extends StatelessWidget {
  const _LogoBlock();

  static const _letters = [
    ('B', Color(0xFFF2994A)),
    ('L', Color(0xFF56CCF2)),
    ('O', Color(0xFFEB5757)),
    ('C', Color(0xFFF2C94C)),
    ('K', Color(0xFF6FCF97)),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Each letter sits in its own colored mini-block for uniqueness.
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final (letter, color) in _letters) ...[
              _LetterBlock(letter: letter, color: color),
              const SizedBox(width: 6),
            ],
          ],
        ),
        const SizedBox(height: 8),
        const Text(
          'PUZZLE',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w900,
            color: Color(0xFF56CCF2),
            letterSpacing: 12,
          ),
        ),
      ],
    );
  }
}

class _LetterBlock extends StatelessWidget {
  const _LetterBlock({required this.letter, required this.color});
  final String letter;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 52,
      height: 52,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.5),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Text(
        letter,
        style: const TextStyle(
          fontSize: 30,
          fontWeight: FontWeight.w900,
          color: Colors.white,
        ),
      ),
    );
  }
}

class _Tagline extends StatelessWidget {
  const _Tagline();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0x22FFFFFF),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Text(
        'Free forever · No ads · Open source',
        style: TextStyle(color: Colors.white60, fontSize: 13),
      ),
    );
  }
}

// ── Treasure button (top-left) ───────────────────────────────────────────────

class _TreasureButton extends StatefulWidget {
  const _TreasureButton({required this.count, required this.onTap});
  final int count;
  final VoidCallback onTap;

  @override
  State<_TreasureButton> createState() => _TreasureButtonState();
}

class _TreasureButtonState extends State<_TreasureButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _bob = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2200),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _bob.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        margin: const EdgeInsets.all(8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0x33F2C94C),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0x55F2C94C)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedBuilder(
              animation: _bob,
              builder: (_, child) => Transform.translate(
                offset: Offset(0, -_bob.value * 3),
                child: child,
              ),
              child: const Text('💎', style: TextStyle(fontSize: 20)),
            ),
            const SizedBox(width: 6),
            Text(
              '${widget.count}',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: Color(0xFFF2C94C),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Menu buttons ─────────────────────────────────────────────────────────────

class _MenuButton extends StatelessWidget {
  const _MenuButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onPressed,
    this.badge,
    this.goldBadge = false,
  });

  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback? onPressed;
  final String? badge;
  final bool goldBadge;

  @override
  Widget build(BuildContext context) {
    final button = SizedBox(
      width: 260,
      height: 64,
      child: FilledButton(
        style: FilledButton.styleFrom(
          backgroundColor: color,
          disabledBackgroundColor: color.withValues(alpha: 0.4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        onPressed: onPressed,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 28),
            const SizedBox(width: 12),
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
    if (badge == null) return button;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        button,
        Positioned(
          top: -10,
          left: -10,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: goldBadge
                  ? const Color(0xFFF2C94C)
                  : const Color(0xFFE53935),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              badge!,
              style: TextStyle(
                color: goldBadge ? const Color(0xFF7A2E12) : Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Decorative background blocks ─────────────────────────────────────────────

class _DecorativeBlocks extends StatefulWidget {
  const _DecorativeBlocks();

  @override
  State<_DecorativeBlocks> createState() => _DecorativeBlocksState();
}

class _DecorativeBlocksState extends State<_DecorativeBlocks>
    with SingleTickerProviderStateMixin {
  late final AnimationController _drift = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 12),
  )..repeat(reverse: true);

  static const _defs = [
    // (left%, top%, size, color, phase)
    (0.04, 0.12, 28.0, Color(0x18FF2E2E), 0.0),
    (0.80, 0.08, 22.0, Color(0x18FFCE00), 0.3),
    (0.88, 0.30, 18.0, Color(0x182B82FF), 0.6),
    (0.06, 0.45, 20.0, Color(0x182FD048), 0.2),
    (0.82, 0.55, 26.0, Color(0x18A43BFF), 0.8),
    (0.10, 0.72, 18.0, Color(0x18FF8A00), 0.5),
    (0.78, 0.78, 22.0, Color(0x1812CFEF), 0.1),
    (0.50, 0.05, 16.0, Color(0x18FF52AE), 0.7),
  ];

  @override
  void dispose() {
    _drift.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return AnimatedBuilder(
      animation: _drift,
      builder: (_, _) => Stack(
        children: [
          for (final (lf, tf, sz, color, phase) in _defs)
            Positioned(
              left: size.width * lf,
              top:
                  size.height * tf +
                  _drift.value * 8 * ((phase + 0.5) % 1.0 < 0.5 ? 1 : -1),
              child: Transform.rotate(
                angle: _drift.value * 0.3 * (phase < 0.5 ? 1 : -1),
                child: Container(
                  width: sz,
                  height: sz,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
