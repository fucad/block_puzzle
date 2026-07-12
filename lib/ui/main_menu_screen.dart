import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../state/classic_game_controller.dart';
import '../state/providers.dart';
import '../state/quest_providers.dart';
import 'classic_screen.dart';
import 'quest_map_screen.dart';
import 'settings_sheet.dart';

/// Main menu: logo, tagline, Quest (arrives in M3) and Classic. No ads,
/// no "More Games", no upsells — ever (PURPOSE.md).
class MainMenuScreen extends ConsumerWidget {
  const MainMenuScreen({super.key});

  static const _logoColors = [
    Color(0xFFF2994A),
    Color(0xFF56CCF2),
    Color(0xFFEB5757),
    Color(0xFFF2C94C),
    Color(0xFF6FCF97),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeProvider);
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
              Align(
                alignment: Alignment.topRight,
                child: IconButton(
                  onPressed: () => showSettingsSheet(context),
                  icon: const Icon(Icons.settings),
                  color: Colors.white54,
                  iconSize: 28,
                ),
              ),
              Center(
                child: Column(
                  children: [
                    const Spacer(flex: 2),
                    Text.rich(
                      TextSpan(
                        children: [
                          for (final (i, letter) in 'BLOCK'.split('').indexed)
                            TextSpan(
                              text: letter,
                              style: TextStyle(
                                color: _logoColors[i % _logoColors.length],
                              ),
                            ),
                        ],
                      ),
                      style: const TextStyle(
                        fontSize: 64,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2,
                        shadows: [Shadow(color: Colors.black38, blurRadius: 6)],
                      ),
                    ),
                    const Text(
                      'PUZZLE',
                      style: TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF56CCF2),
                        letterSpacing: 10,
                      ),
                    ),
                    const Spacer(),
                    const Text(
                      'Free forever. No ads. Open source.',
                      style: TextStyle(color: Colors.white70, fontSize: 16),
                    ),
                    const Spacer(flex: 2),
                    _MenuButton(
                      label: 'Quest',
                      icon: Icons.flag_rounded,
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
                      badge: _questCountdown(ref),
                    ),
                    const SizedBox(height: 16),
                    _MenuButton(
                      label: 'Classic',
                      icon: Icons.all_inclusive_rounded,
                      color: const Color(0xFF27AE60),
                      onPressed: () {
                        // Ensure a run exists here, in a gesture context —
                        // providers must not be mutated during widget build.
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

/// "Nd Nh" until the next quest pack unlocks (reference: corner ribbon).
String? _questCountdown(WidgetRef ref) {
  final next = ref.watch(questCatalogProvider).value?.nextUpcoming?.releaseDate;
  if (next == null) return null;
  final left = next.difference(DateTime.now().toUtc());
  if (left.isNegative) return null;
  return '${left.inDays}d ${left.inHours % 24}h';
}

class _MenuButton extends StatelessWidget {
  const _MenuButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onPressed,
    this.badge,
  });

  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback? onPressed;
  final String? badge;

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
            // Scale down instead of overflowing with wide fonts/locales.
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
              color: const Color(0xFFE53935),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              badge!,
              style: const TextStyle(
                color: Colors.white,
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
