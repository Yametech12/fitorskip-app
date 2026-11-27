/// Results: the visual gallery of completed try-ons, newest first.
/// Every completed try-on is saved on the phone with its render, its
/// verdict score and band, and its date; tapping a card opens the full
/// result. (GT-176 item 6: this gallery replaces the old history list.)
library;

import 'dart:io';

import 'package:material_ui/material_ui.dart';

import '../app_state.dart';
import '../models.dart';
import '../verdict/verdict_engine.dart';
import '../widgets/verdict_card.dart';
import 'result_screen.dart';

class ResultsGalleryScreen extends StatelessWidget {
  const ResultsGalleryScreen({super.key, this.onTryOn});

  /// Sends the wearer to the Try on tab from the empty state.
  final VoidCallback? onTryOn;

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);
    final theme = Theme.of(context);
    if (controller.history.isEmpty) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(24, 40, 24, 24),
        child: Column(
          children: [
            Icon(Icons.grid_view_outlined,
                size: 52,
                color:
                    theme.colorScheme.onSurface.withValues(alpha: 0.3)),
            const SizedBox(height: 14),
            Text('No results yet', style: theme.textTheme.titleMedium),
            const SizedBox(height: 6),
            Text(
              'Your finished try-ons collect here as a gallery: the '
              'render, the Bagay Verdict score, and the date, kept on '
              'this phone so you can compare before you buy.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color:
                    theme.colorScheme.onSurface.withValues(alpha: 0.66),
              ),
            ),
            if (onTryOn != null) ...[
              const SizedBox(height: 18),
              FilledButton.icon(
                onPressed: onTryOn,
                icon: const Icon(Icons.checkroom_outlined),
                label: const Text('Try on a garment'),
              ),
            ],
          ],
        ),
      );
    }
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.62,
      ),
      itemCount: controller.history.length,
      itemBuilder: (context, index) {
        return _ResultCard(record: controller.history[index]);
      },
    );
  }
}

class _ResultCard extends StatelessWidget {
  const _ResultCard({required this.record});

  final TryOnRecord record;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final controller = AppScope.of(context);
    final renderExists = File(record.renderPhotoPath).existsSync();
    final date = record.createdAt;
    final dateLabel =
        '${date.year}-${_two(date.month)}-${_two(date.day)}';
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => ResultScreen(record: record),
          ));
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  renderExists
                      ? Image.file(
                          File(record.renderPhotoPath),
                          fit: BoxFit.cover,
                          // Decode at tile size, not full photo size.
                          cacheWidth: 540,
                        )
                      : Container(
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.08),
                          child: const Icon(
                              Icons.image_not_supported_outlined),
                        ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: IconButton(
                      icon: const Icon(Icons.delete_outline),
                      tooltip: 'Delete this result',
                      style: IconButton.styleFrom(
                        backgroundColor: theme.colorScheme.surface
                            .withValues(alpha: 0.85),
                      ),
                      onPressed: () =>
                          _confirmDelete(context, controller),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 9, 10, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  BandChip(band: record.band, score: record.overallScore),
                  const SizedBox(height: 7),
                  Text(
                    '${record.garment.color.label} '
                    '${record.garment.neckline.label.toLowerCase()}, '
                    '${record.occasion.label.toLowerCase()}',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '$dateLabel'
                    '${record.cost.isDemo ? ' - demo render' : ''}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface
                          .withValues(alpha: 0.55),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(
      BuildContext context, AppController controller) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete this result?'),
        content: const Text(
            'Its photos and verdict are removed from this phone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Keep'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await controller.deleteRecord(record);
    }
  }

  static String _two(int value) => value.toString().padLeft(2, '0');
}
