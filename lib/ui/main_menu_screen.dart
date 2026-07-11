import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../state/classic_game_controller.dart';
import '../state/providers.dart';
import 'classic_screen.dart';

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
          child: Center(
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
                  // Enabled in M3 with the quest map + countdown badge.
                  onPressed: null,
                  trailing: 'soon',
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
                      MaterialPageRoute(builder: (_) => const ClassicScreen()),
                    );
                  },
                ),
                const Spacer(flex: 2),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MenuButton extends StatelessWidget {
  const _MenuButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onPressed,
    this.trailing,
  });

  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback? onPressed;
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
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
            Text(
              label,
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
            if (trailing != null) ...[
              const SizedBox(width: 10),
              Text(
                trailing!,
                style: const TextStyle(color: Colors.white70, fontSize: 14),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
