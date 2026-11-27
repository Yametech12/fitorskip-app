/// Welcome and consent: the first thing a new user sees. Consent comes
/// before any photo is taken, per the plan's privacy design: what photos
/// are used for, the 30-day auto-delete promise, and one-tap delete all.
library;

import 'package:material_ui/material_ui.dart';

import '../app_state.dart';
import '../theme.dart';

class WelcomeConsentScreen extends StatefulWidget {
  const WelcomeConsentScreen({super.key});

  @override
  State<WelcomeConsentScreen> createState() => _WelcomeConsentScreenState();
}

class _WelcomeConsentScreenState extends State<WelcomeConsentScreen> {
  bool _agreed = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final controller = AppScope.of(context);
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
          children: [
            Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: FitColors.petrol,
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: const Icon(Icons.checkroom,
                      color: Colors.white, size: 27),
                ),
                const SizedBox(width: 12),
                Text(
                  'FitOrSkip',
                  style: theme.textTheme.headlineMedium,
                ),
              ],
            ),
            const SizedBox(height: 26),
            Text(
              'Snap a shirt. See it on you. Get the verdict.',
              style: theme.textTheme.headlineMedium?.copyWith(fontSize: 30),
            ),
            const SizedBox(height: 12),
            Text(
              'Photograph a shirt in the store, see it on your own photo, '
              'and get a Bagay Verdict: a 0 to 100 score across color, '
              'silhouette, print, neckline, style, and occasion, with one '
              'fix when the answer is no.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color:
                    theme.colorScheme.onSurface.withValues(alpha: 0.72),
              ),
            ),
            const SizedBox(height: 26),
            Text('Before your first photo',
                style: theme.textTheme.titleMedium),
            const SizedBox(height: 10),
            const _ConsentPoint(
              icon: Icons.photo_camera_outlined,
              title: 'Your photos, your call',
              body: 'FitOrSkip uses your photo and the garment photo only '
                  'to make your try-on and verdict. Nothing is rendered '
                  'until you agree here.',
            ),
            const _ConsentPoint(
              icon: Icons.lock_outline,
              title: 'Private by design',
              body: 'In this demo build your photos stay on this phone. '
                  'The full service uses render providers on no-training '
                  'terms only, and your photos never reach sellers.',
            ),
            const _ConsentPoint(
              icon: Icons.event_busy_outlined,
              title: '30-day auto-delete',
              body: 'The full service deletes your photos automatically '
                  'after 30 days. In this demo they stay only until you '
                  'delete them.',
            ),
            const _ConsentPoint(
              icon: Icons.delete_sweep_outlined,
              title: 'One-tap delete all',
              body: 'The About tab has a delete-all button that wipes '
                  'your photos, history, and settings from this phone in '
                  'one tap, any time.',
            ),
            const SizedBox(height: 14),
            InkWell(
              onTap: () => setState(() => _agreed = !_agreed),
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Checkbox(
                      value: _agreed,
                      onChanged: (value) =>
                          setState(() => _agreed = value ?? false),
                    ),
                    const Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(top: 12),
                        child: Text(
                          'I agree to FitOrSkip using my photos to make '
                          'try-ons and verdicts, under the promises above.',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            FilledButton(
              onPressed: _agreed
                  ? () async {
                      await controller.acceptConsent();
                    }
                  : null,
              child: const Text('Agree and start'),
            ),
            const SizedBox(height: 18),
            Center(
              child: Text(
                'Made by Mohammad Sidique Ibrahim',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface
                      .withValues(alpha: 0.5),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ConsentPoint extends StatelessWidget {
  const _ConsentPoint({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: FitColors.marigold.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 20, color: FitColors.petrol),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(
                  body,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface
                        .withValues(alpha: 0.7),
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
