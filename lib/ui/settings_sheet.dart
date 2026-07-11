import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../state/providers.dart';

/// Sound / haptics toggles, reset progress, and about+licenses. Theme
/// picker appears here once a second theme ships (M4 seam).
void showSettingsSheet(BuildContext context) {
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: const Color(0xFF2C3A6B),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => const _SettingsSheet(),
  );
}

class _SettingsSheet extends ConsumerWidget {
  const _SettingsSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(saveDataProvider).settings;
    final notifier = ref.read(saveDataProvider.notifier);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Settings',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
            ),
            SwitchListTile(
              title: const Text('Sound'),
              secondary: const Icon(Icons.volume_up_rounded),
              value: settings.soundOn,
              onChanged: (v) =>
                  notifier.updateSettings(settings.copyWith(soundOn: v)),
            ),
            SwitchListTile(
              title: const Text('Haptics'),
              secondary: const Icon(Icons.vibration_rounded),
              value: settings.hapticsOn,
              onChanged: (v) =>
                  notifier.updateSettings(settings.copyWith(hapticsOn: v)),
            ),
            ListTile(
              leading: const Icon(Icons.delete_forever_rounded),
              title: const Text('Reset progress'),
              onTap: () => _confirmReset(context, ref),
            ),
            ListTile(
              leading: const Icon(Icons.info_outline_rounded),
              title: const Text('About & licenses'),
              onTap: () => showAboutDialog(
                context: context,
                applicationName: 'Block Puzzle',
                applicationLegalese:
                    'Free forever. No ads, no tracking, no purchases.\n'
                    'MIT-licensed open source — part of the Free Ad-free '
                    'Games project.',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmReset(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset all progress?'),
        content: const Text(
          'High score, best combos, and quest progress will be erased. '
          'This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      ref.read(saveDataProvider.notifier).resetAllProgress();
      if (context.mounted) Navigator.pop(context); // close the sheet
    }
  }
}
