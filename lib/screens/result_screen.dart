/// Result: the render beside the original garment, and the Bagay Verdict
/// card. Also used read-only when a history entry is reopened.
library;

import 'dart:io';

import 'package:material_ui/material_ui.dart';

import '../app_state.dart';
import '../models.dart';
import '../widgets/share_verdict_sheet.dart';
import '../widgets/verdict_card.dart';

class ResultScreen extends StatelessWidget {
  const ResultScreen({super.key, required this.record});

  final TryOnRecord record;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Your verdict')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _PhotoTile(
                  label: record.cost.isDemo ? 'Demo render' : 'Render',
                  path: record.renderPhotoPath,
                  demoBadge: record.cost.isDemo,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _PhotoTile(
                  label: 'The garment',
                  path: record.garmentPhotoPath,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            record.cost.isDemo
                ? 'The left image is a demo composite made on your phone: '
                    'the garment photo placed over your photo, stamped '
                    'DEMO. A real render needs the paid render service, '
                    'which is not switched on in this build.'
                : 'Rendered by ${record.cost.providerId} in the try-on '
                    'service.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.66),
            ),
          ),
          const SizedBox(height: 16),
          VerdictCard(verdict: record.toVerdictResult()),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => showShareVerdictSheet(context, record),
            icon: const Icon(Icons.share_outlined),
            label: const Text('Share verdict'),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: () => _saveRecordToWardrobe(context, record),
            icon: const Icon(Icons.dry_cleaning_outlined),
            label: const Text('Save garment to wardrobe'),
          ),
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: () =>
                Navigator.of(context).popUntil((route) => route.isFirst),
            icon: const Icon(Icons.checkroom_outlined),
            label: const Text('Try another garment'),
          ),
          const SizedBox(height: 10),
          Center(
            child: Text(
              'Saved to your Results gallery. Render cost recorded: '
              '\$${record.cost.estimatedCostUsd.toStringAsFixed(2)}'
              '${record.cost.isDemo ? ' (demo)' : ''}.',
              style: theme.textTheme.bodySmall?.copyWith(
                color:
                    theme.colorScheme.onSurface.withValues(alpha: 0.55),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Saves a result's garment into the Wardrobe, with its own copy of
/// the photo, so deleting the result later cannot break it.
Future<void> _saveRecordToWardrobe(
    BuildContext context, TryOnRecord record) async {
  final controller = AppScope.of(context);
  final messenger = ScaffoldMessenger.of(context);
  final stored =
      await controller.storePhoto(record.garmentPhotoPath, 'wardrobe');
  await controller.addWardrobeItem(WardrobeItem(
    id: 'w${DateTime.now().millisecondsSinceEpoch}',
    createdAt: DateTime.now(),
    photoPath: stored,
    garment: record.garment,
    sampledColor: record.sampledColor,
  ));
  messenger.showSnackBar(
    const SnackBar(content: Text('Saved to your wardrobe.')),
  );
}

class _PhotoTile extends StatelessWidget {
  const _PhotoTile({
    required this.label,
    required this.path,
    this.demoBadge = false,
  });

  final String label;
  final String path;
  final bool demoBadge;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final exists = File(path).existsSync();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AspectRatio(
          aspectRatio: 3 / 4,
          child: Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color:
                    theme.colorScheme.onSurface.withValues(alpha: 0.14),
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (exists)
                  Image.file(File(path), fit: BoxFit.cover)
                else
                  Center(
                    child: Icon(Icons.image_not_supported_outlined,
                        color: theme.colorScheme.onSurface
                            .withValues(alpha: 0.35)),
                  ),
                if (demoBadge)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.72),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'DEMO',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.4,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(label,
            style: theme.textTheme.bodySmall
                ?.copyWith(fontWeight: FontWeight.w700)),
      ],
    );
  }
}
