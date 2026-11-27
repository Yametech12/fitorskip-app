/// History: past try-ons with their verdicts, newest first.
library;

import 'dart:io';

import 'package:material_ui/material_ui.dart';

import '../app_state.dart';
import '../models.dart';
import '../verdict/verdict_engine.dart';
import '../widgets/verdict_card.dart';
import 'result_screen.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);
    final theme = Theme.of(context);
    if (controller.history.isEmpty) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(24, 40, 24, 24),
        child: Column(
          children: [
            Icon(Icons.history,
                size: 52,
                color:
                    theme.colorScheme.onSurface.withValues(alpha: 0.3)),
            const SizedBox(height: 14),
            Text('No try-ons yet', style: theme.textTheme.titleMedium),
            const SizedBox(height: 6),
            Text(
              'Your finished try-ons and their Bagay Verdicts will '
              'collect here.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color:
                    theme.colorScheme.onSurface.withValues(alpha: 0.66),
              ),
            ),
          ],
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
      itemCount: controller.history.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final record = controller.history[index];
        return _HistoryTile(record: record);
      },
    );
  }
}

class _HistoryTile extends StatelessWidget {
  const _HistoryTile({required this.record});

  final TryOnRecord record;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final controller = AppScope.of(context);
    final renderExists = File(record.renderPhotoPath).existsSync();
    final date = record.createdAt;
    final dateLabel =
        '${date.year}-${_two(date.month)}-${_two(date.day)} '
        '${_two(date.hour)}:${_two(date.minute)}';
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () {
          Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => ResultScreen(record: record),
          ));
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  width: 62,
                  height: 80,
                  child: renderExists
                      ? Image.file(
                          File(record.renderPhotoPath),
                          fit: BoxFit.cover,
                        )
                      : Container(
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.08),
                          child: const Icon(
                              Icons.image_not_supported_outlined),
                        ),
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    BandChip(band: record.band, score: record.overallScore),
                    const SizedBox(height: 7),
                    Text(
                      '${record.garment.color.label} '
                      '${record.garment.neckline.label.toLowerCase()}, '
                      '${record.occasion.label.toLowerCase()}',
                      style: theme.textTheme.bodyMedium
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
              IconButton(
                icon: const Icon(Icons.delete_outline),
                tooltip: 'Delete this try-on',
                onPressed: () async {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (dialogContext) => AlertDialog(
                      title: const Text('Delete this try-on?'),
                      content: const Text(
                          'Its photos and verdict are removed from '
                          'this phone.'),
                      actions: [
                        TextButton(
                          onPressed: () =>
                              Navigator.of(dialogContext).pop(false),
                          child: const Text('Keep'),
                        ),
                        FilledButton(
                          onPressed: () =>
                              Navigator.of(dialogContext).pop(true),
                          child: const Text('Delete'),
                        ),
                      ],
                    ),
                  );
                  if (confirmed == true) {
                    await controller.deleteRecord(record);
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _two(int value) => value.toString().padLeft(2, '0');
}
