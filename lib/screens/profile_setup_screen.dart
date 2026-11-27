/// Profile photo setup plus the wearer descriptors the verdict engine
/// scores against. Guidance follows the plan: front-facing, half-body,
/// plain background, even light.
library;

import 'dart:io';

import 'package:image_picker/image_picker.dart';
import 'package:material_ui/material_ui.dart';

import '../app_state.dart';
import '../verdict/verdict_engine.dart';

class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key, this.embedded = false});

  /// When true the screen renders inside the Try tab instead of its own
  /// scaffold.
  final bool embedded;

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final ImagePicker _picker = ImagePicker();
  bool _busy = false;

  Future<void> _pick(AppController controller, ImageSource source) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final picked = await _picker.pickImage(
        source: source,
        maxWidth: 1600,
        imageQuality: 92,
      );
      if (picked == null) return;
      final stored = await controller.storePhoto(picked.path, 'profile');
      await controller.setProfilePhoto(stored);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);
    final theme = Theme.of(context);
    final content = ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
      children: [
        Text('Your try-on photo', style: theme.textTheme.titleLarge),
        const SizedBox(height: 6),
        Text(
          'One front-facing, half-body photo. Stand facing the camera, '
          'arms relaxed, plain background, even light. The clearer the '
          'photo, the more convincing the render.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.72),
          ),
        ),
        const SizedBox(height: 16),
        _PhotoPanel(controller: controller),
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
        const SizedBox(height: 26),
        Text('About you, for the verdict', style: theme.textTheme.titleLarge),
        const SizedBox(height: 6),
        Text(
          'The Bagay Verdict scores color against your skin tone and '
          'silhouette against your frame. These answers stay on this '
          'phone and you can change them any time.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.72),
          ),
        ),
        const SizedBox(height: 16),
        _ChoiceGroup<SkinTone>(
          label: 'Skin tone',
          values: SkinTone.values,
          labels: const {
            SkinTone.fair: 'Fair',
            SkinTone.lightMedium: 'Light medium',
            SkinTone.medium: 'Medium',
            SkinTone.deep: 'Deep',
          },
          selected: controller.wearer.skinTone,
          onChanged: (value) => _update(controller, skinTone: value),
        ),
        _ChoiceGroup<Undertone>(
          label: 'Undertone',
          values: Undertone.values,
          labels: const {
            Undertone.warm: 'Warm',
            Undertone.cool: 'Cool',
            Undertone.neutral: 'Neutral',
          },
          selected: controller.wearer.undertone,
          onChanged: (value) => _update(controller, undertone: value),
        ),
        _ChoiceGroup<BodyFrame>(
          label: 'Frame',
          values: BodyFrame.values,
          labels: const {
            BodyFrame.slim: 'Slim',
            BodyFrame.average: 'Average',
            BodyFrame.broad: 'Broad',
          },
          selected: controller.wearer.frame,
          onChanged: (value) => _update(controller, frame: value),
        ),
        const SizedBox(height: 6),
        Text('Styles you usually wear',
            style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final style in StyleTag.values)
              FilterChip(
                label: Text(style.label),
                selected:
                    controller.wearer.preferredStyles.contains(style),
                onSelected: (selected) {
                  final next = {...controller.wearer.preferredStyles};
                  if (selected) {
                    next.add(style);
                  } else {
                    next.remove(style);
                  }
                  _update(controller, preferredStyles: next);
                },
              ),
          ],
        ),
      ],
    );
    if (widget.embedded) return content;
    return Scaffold(
      appBar: AppBar(title: const Text('Your profile')),
      body: content,
    );
  }

  void _update(
    AppController controller, {
    SkinTone? skinTone,
    Undertone? undertone,
    BodyFrame? frame,
    Set<StyleTag>? preferredStyles,
  }) {
    final current = controller.wearer;
    controller.saveWearer(WearerProfile(
      skinTone: skinTone ?? current.skinTone,
      undertone: undertone ?? current.undertone,
      frame: frame ?? current.frame,
      preferredStyles: preferredStyles ?? current.preferredStyles,
    ));
  }
}

class _PhotoPanel extends StatelessWidget {
  const _PhotoPanel({required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final path = controller.profilePhotoPath;
    return AspectRatio(
      aspectRatio: 3 / 3.4,
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.14),
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: path != null && File(path).existsSync()
            ? Image.file(File(path), fit: BoxFit.cover)
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.person_outline,
                      size: 64,
                      color: theme.colorScheme.onSurface
                          .withValues(alpha: 0.35)),
                  const SizedBox(height: 8),
                  Text(
                    'No profile photo yet',
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

class _ChoiceGroup<T> extends StatelessWidget {
  const _ChoiceGroup({
    required this.label,
    required this.values,
    required this.labels,
    required this.selected,
    required this.onChanged,
  });

  final String label;
  final List<T> values;
  final Map<T, String> labels;
  final T selected;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final value in values)
                ChoiceChip(
                  label: Text(labels[value] ?? '$value'),
                  selected: selected == value,
                  onSelected: (_) => onChanged(value),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
