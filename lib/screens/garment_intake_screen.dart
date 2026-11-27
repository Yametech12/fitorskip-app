/// Garment intake: photograph the shirt, confirm its descriptors, pick the
/// occasion, and start the try-on. In v1 the wearer confirms the
/// descriptors the verdict engine scores; the vision model fills them
/// automatically in a later phase.
library;

import 'dart:io';

import 'package:image_picker/image_picker.dart';
import 'package:material_ui/material_ui.dart';

import '../app_state.dart';
import '../models.dart';
import '../render/photo_color_sampler.dart';
import '../verdict/verdict_engine.dart';
import 'processing_screen.dart';
import 'profile_setup_screen.dart';

class GarmentIntakeScreen extends StatefulWidget {
  const GarmentIntakeScreen({super.key});

  @override
  State<GarmentIntakeScreen> createState() => _GarmentIntakeScreenState();
}

class _GarmentIntakeScreenState extends State<GarmentIntakeScreen> {
  final ImagePicker _picker = ImagePicker();
  String? _garmentPhotoPath;
  GarmentColor _color = GarmentColor.navy;
  PrintScale _printScale = PrintScale.none;
  Neckline _neckline = Neckline.crew;
  GarmentFit _fit = GarmentFit.regular;
  Set<StyleTag> _styles = {StyleTag.casual};
  Set<Occasion> _garmentOccasions = {Occasion.everyday};
  Occasion _occasion = Occasion.everyday;
  bool _busy = false;

  Future<void> _pick(AppController controller, ImageSource source) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final picked = await _picker.pickImage(
        source: source,
        maxWidth: 1200,
        imageQuality: 88,
      );
      if (picked == null) return;
      final stored = await controller.storePhoto(picked.path, 'garment');
      setState(() => _garmentPhotoPath = stored);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);
    final theme = Theme.of(context);
    if (!controller.hasProfilePhoto) {
      return ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
        children: [
          Text('One thing first', style: theme.textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(
            'FitOrSkip needs your try-on photo before it can place a '
            'garment on you.',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 8),
          FilledButton(
            onPressed: () {
              Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => const ProfileSetupScreen(),
              ));
            },
            child: const Text('Set up my photo'),
          ),
        ],
      );
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
      children: [
        Row(
          children: [
            Expanded(
              child: Text('Try on a garment',
                  style: theme.textTheme.titleLarge),
            ),
            _CreditsPill(remaining: controller.creditsRemaining),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          'Photograph the shirt flat and well lit, front side up, whole '
          'garment in frame. A hanger shot against a plain wall also '
          'works.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.72),
          ),
        ),
        const SizedBox(height: 16),
        _GarmentPhotoPanel(path: _garmentPhotoPath),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed:
                    _busy ? null : () => _pick(controller, ImageSource.camera),
                icon: const Icon(Icons.photo_camera_outlined),
                label: const Text('Camera'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _busy
                    ? null
                    : () => _pick(controller, ImageSource.gallery),
                icon: const Icon(Icons.photo_library_outlined),
                label: const Text('Gallery'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Text('Describe the garment', style: theme.textTheme.titleLarge),
        const SizedBox(height: 4),
        Text(
          'The verdict scores these six things. Answer honestly; the '
          'score is only useful if the description is.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.66),
          ),
        ),
        const SizedBox(height: 14),
        _PickerRow<GarmentColor>(
          label: 'Main color',
          value: _color,
          values: GarmentColor.values,
          labelOf: (v) => v.label,
          onChanged: (v) => setState(() => _color = v),
        ),
        _PickerRow<PrintScale>(
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
        _PickerRow<Neckline>(
          label: 'Neckline',
          value: _neckline,
          values: Neckline.values,
          labelOf: (v) => v.label,
          onChanged: (v) => setState(() => _neckline = v),
        ),
        _PickerRow<GarmentFit>(
          label: 'Fit on the rack',
          value: _fit,
          values: GarmentFit.values,
          labelOf: (v) => v.label,
          onChanged: (v) => setState(() => _fit = v),
        ),
        _MultiChips<StyleTag>(
          label: 'Garment style',
          values: StyleTag.values,
          labelOf: (v) => v.label,
          selected: _styles,
          onChanged: (next) => setState(() => _styles = next),
        ),
        _MultiChips<Occasion>(
          label: 'Made for',
          values: Occasion.values,
          labelOf: (v) => v.label,
          selected: _garmentOccasions,
          onChanged: (next) => setState(() => _garmentOccasions = next),
        ),
        const SizedBox(height: 4),
        _PickerRow<Occasion>(
          label: 'Wearing it for',
          value: _occasion,
          values: Occasion.values,
          labelOf: (v) => v.label,
          onChanged: (v) => setState(() => _occasion = v),
        ),
        const SizedBox(height: 18),
        if (!controller.hasCredits)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              'You are out of try-on credits. See the Credits tab for '
              'how the plan works.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.error,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        FilledButton.icon(
          onPressed: (_garmentPhotoPath == null || !controller.hasCredits)
              ? null
              : () => _start(controller),
          icon: const Icon(Icons.checkroom),
          label: const Text('See it on me'),
        ),
        const SizedBox(height: 8),
        Center(
          child: Text(
            'Uses 1 credit. A timed-out render never costs a credit.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
            ),
          ),
        ),
        const SizedBox(height: 16),
        OutlinedButton.icon(
          onPressed: (_garmentPhotoPath == null || _busy)
              ? null
              : () => _saveToWardrobe(controller),
          icon: const Icon(Icons.dry_cleaning_outlined),
          label: const Text('Save to wardrobe'),
        ),
        const SizedBox(height: 6),
        Center(
          child: Text(
            'For a garment you already own: save it once, then start '
            'future try-ons from the Wardrobe tab.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _saveToWardrobe(AppController controller) async {
    if (_busy || _garmentPhotoPath == null) return;
    setState(() => _busy = true);
    try {
      // A private copy: deleting a try-on record later must not remove
      // the wardrobe item's photo.
      final stored =
          await controller.storePhoto(_garmentPhotoPath!, 'wardrobe');
      final sampled = await sampleGarmentPhotoColor(stored);
      await controller.addWardrobeItem(WardrobeItem(
        id: 'w${DateTime.now().millisecondsSinceEpoch}',
        createdAt: DateTime.now(),
        photoPath: stored,
        garment: GarmentProfile(
          color: _color,
          printScale: _printScale,
          neckline: _neckline,
          fit: _fit,
          styles: _styles,
          occasions: _garmentOccasions,
        ),
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

  void _start(AppController controller) {
    final garment = GarmentProfile(
      color: _color,
      printScale: _printScale,
      neckline: _neckline,
      fit: _fit,
      styles: _styles,
      occasions: _garmentOccasions,
    );
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => ProcessingScreen(
        garmentPhotoPath: _garmentPhotoPath!,
        garment: garment,
        occasion: _occasion,
      ),
    ));
  }
}

class _CreditsPill extends StatelessWidget {
  const _CreditsPill({required this.remaining});

  final int remaining;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.secondary.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: theme.colorScheme.secondary.withValues(alpha: 0.6),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.confirmation_number_outlined, size: 16),
          const SizedBox(width: 5),
          Text(
            '$remaining left',
            style: theme.textTheme.bodySmall
                ?.copyWith(fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

class _GarmentPhotoPanel extends StatelessWidget {
  const _GarmentPhotoPanel({required this.path});

  final String? path;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AspectRatio(
      aspectRatio: 3 / 2.6,
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.14),
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: path != null && File(path!).existsSync()
            ? Image.file(File(path!), fit: BoxFit.cover)
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.checkroom_outlined,
                      size: 56,
                      color: theme.colorScheme.onSurface
                          .withValues(alpha: 0.35)),
                  const SizedBox(height: 8),
                  Text(
                    'No garment photo yet',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface
                          .withValues(alpha: 0.55),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _PickerRow<T> extends StatelessWidget {
  const _PickerRow({
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

class _MultiChips<T> extends StatelessWidget {
  const _MultiChips({
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
