/// About and settings: how the verdict works, the privacy promises in one
/// place, profile editing, one-tap delete all, and the credit line.
library;

import 'package:material_ui/material_ui.dart';

import '../app_state.dart';
import '../verdict/verdict_engine.dart';
import 'profile_setup_screen.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
      children: [
        Text('About FitOrSkip', style: theme.textTheme.titleLarge),
        const SizedBox(height: 6),
        Text(
          'Version 0.2 demo build. The flow, verdict, history, and '
          'credits are real. The render in this build is an on-device '
          'demo composite, labelled DEMO everywhere it appears; the '
          'paid render service is an owner decision and is not switched '
          'on.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.72),
          ),
        ),
        const SizedBox(height: 20),
        Text('How the verdict works', style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        for (final dimension in VerdictDimension.values)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              children: [
                const Icon(Icons.check, size: 17),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(dimension.label,
                      style: theme.textTheme.bodyMedium),
                ),
              ],
            ),
          ),
        const SizedBox(height: 6),
        Text(
          'Each dimension scores 0 to 100 and they combine into one '
          'score: BAGAY at 75 and up, PWEDE PA from 50 to 74, DILI '
          'BAGAY below 50, with one suggested fix when the answer is '
          'not bagay. In this build the scoring is a local rule set '
          'over the answers you confirm; a vision model replaces the '
          'rules in a later phase.',
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(height: 8),
        Text(
          kVerdictHonestyNote,
          style: theme.textTheme.bodySmall?.copyWith(
            fontStyle: FontStyle.italic,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.62),
          ),
        ),
        const SizedBox(height: 20),
        Text('Your data', style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        Text(
          'Photos in this build never leave this phone. The full '
          'service promise: consent before upload, render providers on '
          'no-training terms only, photos auto-deleted after 30 days, '
          'and your photos never reach sellers.',
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(height: 16),
        OutlinedButton.icon(
          onPressed: () {
            Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => const ProfileSetupScreen(),
            ));
          },
          icon: const Icon(Icons.person_outline),
          label: const Text('Edit my photo and verdict profile'),
        ),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            foregroundColor: theme.colorScheme.error,
            side: BorderSide(
                color: theme.colorScheme.error.withValues(alpha: 0.6)),
          ),
          onPressed: () => _confirmDeleteAll(context, controller),
          icon: const Icon(Icons.delete_sweep_outlined),
          label: const Text('Delete all my data'),
        ),
        const SizedBox(height: 26),
        Center(
          child: Text(
            'Made by Mohammad Sidique Ibrahim',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _confirmDeleteAll(
      BuildContext context, AppController controller) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete all my data?'),
        content: const Text(
          'This wipes your profile photo, every try-on photo and '
          'verdict, your credits usage, and your consent from this '
          'phone. It cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Keep my data'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Delete all'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await controller.deleteAllData();
    }
  }
}
