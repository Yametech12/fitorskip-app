/// Shareable verdict card: renders the hang-tag verdict card to a PNG
/// and hands it to the system share sheet.
///
/// Privacy rule from the GT-153 plan: the shared image is the verdict
/// card only. The render, which contains the wearer's photo, is included
/// only when the wearer explicitly opts in on this sheet.
library;

import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:material_ui/material_ui.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../models.dart';
import '../verdict/verdict_engine.dart';
import 'verdict_card.dart';

/// Opens the share preview sheet for one try-on record.
Future<void> showShareVerdictSheet(
  BuildContext context,
  TryOnRecord record,
) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => ShareVerdictSheet(record: record),
  );
}

class ShareVerdictSheet extends StatefulWidget {
  const ShareVerdictSheet({super.key, required this.record});

  final TryOnRecord record;

  @override
  State<ShareVerdictSheet> createState() => _ShareVerdictSheetState();
}

class _ShareVerdictSheetState extends State<ShareVerdictSheet> {
  final GlobalKey _boundaryKey = GlobalKey();
  bool _includeRender = false;
  bool _sharing = false;

  bool get _renderExists =>
      File(widget.record.renderPhotoPath).existsSync();

  Future<void> _share() async {
    if (_sharing) return;
    setState(() => _sharing = true);
    try {
      final boundary = _boundaryKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary == null) throw StateError('share preview not ready');
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();
      if (byteData == null) throw StateError('could not render the card');
      final dir = await getTemporaryDirectory();
      final file = File(
          '${dir.path}/fitorskip_verdict_${widget.record.id}.png');
      await file.writeAsBytes(byteData.buffer.asUint8List(), flush: true);
      await SharePlus.instance.share(ShareParams(
        files: [XFile(file.path)],
        subject: 'My FitOrSkip Bagay Verdict',
        text: 'My Bagay Verdict on FitOrSkip: '
            '${widget.record.band.label} ${widget.record.overallScore}/100',
      ));
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Sharing did not open. The verdict image could not be '
                'prepared on this phone.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final record = widget.record;
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Share your verdict', style: theme.textTheme.titleLarge),
            const SizedBox(height: 6),
            Text(
              'This is exactly what gets shared: the verdict card as an '
              'image. Your photos stay out of it unless you opt in below.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color:
                    theme.colorScheme.onSurface.withValues(alpha: 0.72),
              ),
            ),
            const SizedBox(height: 14),
            RepaintBoundary(
              key: _boundaryKey,
              child: Container(
                color: theme.scaffoldBackgroundColor,
                padding: const EdgeInsets.all(14),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_includeRender && _renderExists) ...[
                      ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: AspectRatio(
                          aspectRatio: 3 / 4,
                          child: Image.file(
                            File(record.renderPhotoPath),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    VerdictCard(verdict: record.toVerdictResult()),
                    const SizedBox(height: 10),
                    Center(
                      child: Text(
                        'FitOrSkip - Made by Mohammad Sidique Ibrahim',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.55),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (_renderExists)
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Include the demo render'),
                subtitle: const Text(
                    'The render shows your photo. Off by default, so the '
                    'shared image never includes you unless you choose '
                    'it.'),
                value: _includeRender,
                onChanged: (value) =>
                    setState(() => _includeRender = value),
              ),
            const SizedBox(height: 8),
            FilledButton.icon(
              onPressed: _sharing ? null : _share,
              icon: const Icon(Icons.share_outlined),
              label: Text(_sharing ? 'Preparing image' : 'Share image'),
            ),
          ],
        ),
      ),
    );
  }
}
