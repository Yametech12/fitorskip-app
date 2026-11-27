/// Wardrobe: garments the wearer owns, saved on the phone with their
/// photo, descriptors, and the dominant color sampled from the photo.
/// A try-on starts straight from a wardrobe item, no new photograph.
/// Photos never leave the device. (GT-176 item 7.)
library;

import 'dart:io';

import 'package:image_picker/image_picker.dart';
import 'package:material_ui/material_ui.dart';

import '../app_state.dart';
import '../models.dart';
import '../render/photo_color_sampler.dart';
import '../verdict/verdict_engine.dart';
import 'processing_screen.dart';

class WardrobeScreen extends StatefulWidget {
  const WardrobeScreen({super.key});

  @override
  State<WardrobeScreen> createState() => _WardrobeScreenState();
}

class _WardrobeScreenState extends State<WardrobeScreen> {
  final ImagePicker _picker = ImagePicker();
  bool _busy = false;

  Future<void> _add(AppController controller) async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Camera'),
              onTap: () =>
                  Navigator.of(sheetContext).pop(ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Gallery'),
              onTap: () =>
                  Navigator.of(sheetContext).pop(ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source == null || _busy) return;
    setState(() => _busy = true);
    try {
      final picked = await _picker.pickImage(
        source: source,
        maxWidth: 1200,
        imageQuality: 88,
      );
      if (picked == null) return;
      final stored = await controller.storePhoto(picked.path, 'wardrobe');
      if (!mounted) return;
      final garment = await Navigator.of(context).push<GarmentProfile>(
        MaterialPageRoute(
          builder: (_) => WardrobeFormScreen(photoPath: stored),
        ),
      );
      if (garment == null) {
        // Form abandoned: drop the copied photo so it does not linger.
        final file = File(stored);
        if (await file.exists()) await file.delete();
        return;
      }
      final sampled = await sampleGarmentPhotoColor(stored);
      await controller.addWardrobeItem(WardrobeItem(
        id: 'w${DateTime.now().millisecondsSinceEpoch}',
        createdAt: DateTime.now(),
        photoPath: stored,
        garment: garment,
        sampledColor: sampled,
      ));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Saved to your wardrobe.')),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);
    final theme = Theme.of(context);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Garments you own. Tap one to try it on again, no new '
                'photo needed.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface
                      .withValues(alpha: 0.66),
                ),
              ),
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton.icon(
                  onPressed: _busy ? null : () => _add(controller),
                  icon: const Icon(Icons.add),
                  label: const Text('Add a garment'),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: controller.wardrobe.isEmpty
              ? _emptyState(theme)
              : GridView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.72,
                  ),
                  itemCount: controller.wardrobe.length,
                  itemBuilder: (context, index) {
                    return _WardrobeCard(
                        item: controller.wardrobe[index]);
                  },
                ),
        ),
      ],
    );
  }

  Widget _emptyState(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
      child: Column(
        children: [
          Icon(Icons.dry_cleaning_outlined,
              size: 52,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.3)),
          const SizedBox(height: 14),
          Text('Your wardrobe is empty',
              style: theme.textTheme.titleMedium),
          const SizedBox(height: 6),
          Text(
            'Save the garments you own here, with their photo and '
            'details. Next time you want a verdict on one, start the '
            'try-on from here instead of photographing it again.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.66),
            ),
          ),
        ],
      ),
    );
  }
}

class _WardrobeCard extends StatelessWidget {
  const _WardrobeCard({required this.item});

  final WardrobeItem item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final photoExists = File(item.photoPath).existsSync();
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => WardrobeItemScreen(item: item),
          ));
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: photoExists
                  ? Image.file(
                      File(item.photoPath),
                      fit: BoxFit.cover,
                      width: double.infinity,
                      // Decode at tile size, not full photo size.
                      cacheWidth: 540,
                    )
                  : Container(
                      color: theme.colorScheme.onSurface
                          .withValues(alpha: 0.08),
                      child: const Center(
                        child:
                            Icon(Icons.image_not_supported_outlined),
                      ),
                    ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 9, 10, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${item.displayColor.label} '
                    '${item.garment.neckline.label.toLowerCase()}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    item.sampledColor != null
                        ? 'Color read from its photo'
                        : 'Color from your description',
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
}

/// One wardrobe item: details, the occasion pick, the try-on start,
/// and delete with confirmation.
class WardrobeItemScreen extends StatefulWidget {
  const WardrobeItemScreen({super.key, required this.item});

  final WardrobeItem item;

  @override
  State<WardrobeItemScreen> createState() => _WardrobeItemScreenState();
}

class _WardrobeItemScreenState extends State<WardrobeItemScreen> {
  Occasion _occasion = Occasion.everyday;

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);
    final theme = Theme.of(context);
    final item = widget.item;
    final garment = item.garment;
    return Scaffold(
      appBar: AppBar(title: const Text('Wardrobe item')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: AspectRatio(
              aspectRatio: 3 / 2.6,
              child: File(item.photoPath).existsSync()
                  ? Image.file(File(item.photoPath), fit: BoxFit.cover)
                  : Container(
                      color: theme.colorScheme.onSurface
                          .withValues(alpha: 0.08),
                      child: const Icon(
                          Icons.image_not_supported_outlined),
                    ),
            ),
          ),
          const SizedBox(height: 16),
          _DetailRow(
            label: 'Color',
            value: item.sampledColor != null
                ? '${item.displayColor.label} (read from its photo)'
                : '${item.displayColor.label} (your description)',
          ),
          _DetailRow(
            label: 'Print',
            value: switch (garment.printScale) {
              PrintScale.none => 'Plain, no print',
              PrintScale.small => 'Small print',
              PrintScale.medium => 'Medium print',
              PrintScale.large => 'Large print',
              PrintScale.micro => 'Micro print, all over',
              PrintScale.statement => 'Statement print, one big graphic',
            },
          ),
          _DetailRow(label: 'Neckline', value: garment.neckline.label),
          _DetailRow(label: 'Fit', value: garment.fit.label),
          _DetailRow(
            label: 'Style',
            value: garment.styles.map((s) => s.label).join(', '),
          ),
          _DetailRow(
            label: 'Made for',
            value: garment.occasions.map((o) => o.label).join(', '),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              SizedBox(
                width: 108,
                child: Text('Wearing it for',
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(fontWeight: FontWeight.w700)),
              ),
              Expanded(
                child: DropdownButtonFormField<Occasion>(
                  initialValue: _occasion,
                  isExpanded: true,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 4),
                  ),
                  items: [
                    for (final o in Occasion.values)
                      DropdownMenuItem(value: o, child: Text(o.label)),
                  ],
                  onChanged: (v) {
                    if (v != null) setState(() => _occasion = v);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          if (!controller.hasProfilePhoto)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                'Set up your try-on photo first, on the Try on tab.',
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: theme.colorScheme.error),
              ),
            ),
          if (!controller.hasCredits)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                'You are out of try-on credits. See the Credits tab '
                'for how the plan works.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.error,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          FilledButton.icon(
            onPressed: (!controller.hasProfilePhoto ||
                    !controller.hasCredits)
                ? null
                : () {
                    Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => ProcessingScreen(
                        garmentPhotoPath: item.photoPath,
                        garment: garment,
                        occasion: _occasion,
                      ),
                    ));
                  },
            icon: const Icon(Icons.checkroom),
            label: const Text('See it on me'),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              'Uses 1 credit. A timed-out render never costs a credit.',
              style: theme.textTheme.bodySmall?.copyWith(
                color:
                    theme.colorScheme.onSurface.withValues(alpha: 0.55),
              ),
            ),
          ),
          const SizedBox(height: 20),
          OutlinedButton.icon(
            onPressed: () => _confirmDelete(context, controller),
            icon: const Icon(Icons.delete_outline),
            label: const Text('Remove from wardrobe'),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(
      BuildContext context, AppController controller) async {
    final navigator = Navigator.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Remove this garment?'),
        content:
            const Text('Its photo is removed from this phone. Your '
                'past results keep their own copies.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Keep'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await controller.deleteWardrobeItem(widget.item);
      navigator.pop();
    }
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 108,
            child: Text(label,
                style: theme.textTheme.bodyMedium
                    ?.copyWith(fontWeight: FontWeight.w700)),
          ),
          Expanded(child: Text(value, style: theme.textTheme.bodyMedium)),
        ],
      ),
    );
  }
}

/// The descriptor form for a garment being added to the Wardrobe.
/// Pops with the GarmentProfile, or null when abandoned.
class WardrobeFormScreen extends StatefulWidget {
  const WardrobeFormScreen({super.key, required this.photoPath});

  final String photoPath;

  @override
  State<WardrobeFormScreen> createState() => _WardrobeFormScreenState();
}

class _WardrobeFormScreenState extends State<WardrobeFormScreen> {
  GarmentColor _color = GarmentColor.navy;
  PrintScale _printScale = PrintScale.none;
  Neckline _neckline = Neckline.crew;
  GarmentFit _fit = GarmentFit.regular;
  Set<StyleTag> _styles = {StyleTag.casual};
  Set<Occasion> _occasions = {Occasion.everyday};

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Describe the garment')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: AspectRatio(
              aspectRatio: 3 / 2.6,
              child: Image.file(File(widget.photoPath),
                  fit: BoxFit.cover),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Its main color is also read from the photo when saved; '
            'these answers cover the rest.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.66),
            ),
          ),
          const SizedBox(height: 16),
          _FormPickerRow<GarmentColor>(
            label: 'Main color',
            value: _color,
            values: GarmentColor.values,
            labelOf: (v) => v.label,
            onChanged: (v) => setState(() => _color = v),
          ),
          _FormPickerRow<PrintScale>(
            label: 'Print',
            value: _printScale,
            values: PrintScale.values,
            labelOf: (v) => switch (v) {
              PrintScale.none => 'Plain, no print',
              PrintScale.small => 'Small print',
              PrintScale.medium => 'Medium print',
              PrintScale.large => 'Large print',
              PrintScale.micro => 'Micro print, all over',
              PrintScale.statement => 'Statement print, one big graphic',
            },
            onChanged: (v) => setState(() => _printScale = v),
          ),
          _FormPickerRow<Neckline>(
            label: 'Neckline',
            value: _neckline,
            values: Neckline.values,
            labelOf: (v) => v.label,
            onChanged: (v) => setState(() => _neckline = v),
          ),
          _FormPickerRow<GarmentFit>(
            label: 'Fit on the rack',
            value: _fit,
            values: GarmentFit.values,
            labelOf: (v) => v.label,
            onChanged: (v) => setState(() => _fit = v),
          ),
          _FormMultiChips<StyleTag>(
            label: 'Garment style',
            values: StyleTag.values,
            labelOf: (v) => v.label,
            selected: _styles,
            onChanged: (next) => setState(() => _styles = next),
          ),
          _FormMultiChips<Occasion>(
            label: 'Made for',
            values: Occasion.values,
            labelOf: (v) => v.label,
            selected: _occasions,
            onChanged: (next) => setState(() => _occasions = next),
          ),
          const SizedBox(height: 10),
          FilledButton.icon(
            onPressed: () {
              Navigator.of(context).pop(GarmentProfile(
                color: _color,
                printScale: _printScale,
                neckline: _neckline,
                fit: _fit,
                styles: _styles,
                occasions: _occasions,
              ));
            },
            icon: const Icon(Icons.check),
            label: const Text('Save to wardrobe'),
          ),
        ],
      ),
    );
  }
}

class _FormPickerRow<T> extends StatelessWidget {
  const _FormPickerRow({
    required this.label,
    required this.value,
    required this.values,
    required this.labelOf,
    required this.onChanged,
  });

  final String label;
  final T value;
  final List<T> values;
  final String Function(T) labelOf;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          SizedBox(
            width: 108,
            child: Text(label,
                style: theme.textTheme.bodyMedium
                    ?.copyWith(fontWeight: FontWeight.w700)),
          ),
          Expanded(
            child: DropdownButtonFormField<T>(
              initialValue: value,
              isExpanded: true,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              ),
              items: [
                for (final v in values)
                  DropdownMenuItem(value: v, child: Text(labelOf(v))),
              ],
              onChanged: (v) {
                if (v != null) onChanged(v);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _FormMultiChips<T> extends StatelessWidget {
  const _FormMultiChips({
    required this.label,
    required this.values,
    required this.labelOf,
    required this.selected,
    required this.onChanged,
  });

  final String label;
  final List<T> values;
  final String Function(T) labelOf;
  final Set<T> selected;
  final ValueChanged<Set<T>> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 7),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final v in values)
                FilterChip(
                  label: Text(labelOf(v)),
                  selected: selected.contains(v),
                  onSelected: (isSelected) {
                    final next = {...selected};
                    if (isSelected) {
                      next.add(v);
                    } else {
                      next.remove(v);
                    }
                    onChanged(next);
                  },
                ),
            ],
          ),
        ],
      ),
    );
  }
}
