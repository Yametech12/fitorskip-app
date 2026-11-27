/// Processing: runs the render and the verdict together, with staged
/// progress honest about the plan's 15 to 45 second reality. The hard
/// timeout is 90 seconds; a timeout offers a free retry and never consumes
/// a credit.
library;

import 'dart:async';

import 'package:material_ui/material_ui.dart';

import '../app_state.dart';
import '../models.dart';
import '../render/photo_color_sampler.dart';
import '../render/try_on_provider.dart';
import '../verdict/verdict_engine.dart';
import 'result_screen.dart';

class ProcessingScreen extends StatefulWidget {
  const ProcessingScreen({
    super.key,
    required this.garmentPhotoPath,
    required this.garment,
    required this.occasion,
  });

  final String garmentPhotoPath;
  final GarmentProfile garment;
  final Occasion occasion;

  static const Duration hardTimeout = Duration(seconds: 90);

  @override
  State<ProcessingScreen> createState() => _ProcessingScreenState();
}

class _ProcessingScreenState extends State<ProcessingScreen> {
  static const List<String> _stages = [
    'Reading your photo',
    'Placing the garment',
    'Scoring color and silhouette',
    'Scoring print, neckline, and style',
    'Writing your verdict',
  ];

  int _stage = 0;
  int _elapsedSeconds = 0;
  Timer? _timer;
  bool _failed = false;
  bool _timedOut = false;
  bool _running = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _run());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _run() async {
    if (_running) return;
    final controller = AppScope.of(context);
    setState(() {
      _running = true;
      _failed = false;
      _timedOut = false;
      _stage = 0;
      _elapsedSeconds = 0;
    });
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        _elapsedSeconds += 1;
        final nextStage = (_elapsedSeconds ~/ 3)
            .clamp(0, _stages.length - 1)
            .toInt();
        if (nextStage > _stage) _stage = nextStage;
      });
    });

    final request = TryOnRequest(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      profilePhotoPath: controller.profilePhotoPath!,
      garmentPhotoPath: widget.garmentPhotoPath,
    );
    try {
      // Measure the garment color from the photo while the render runs.
      // Null on any failure: the engine then scores the descriptor color.
      final sampledColorFuture =
          sampleGarmentPhotoColor(widget.garmentPhotoPath);
      final result = await controller.renderProvider
          .render(request, timeout: ProcessingScreen.hardTimeout);
      final sampledColor = await sampledColorFuture;
      final verdict = controller.verdictEngine.evaluate(VerdictContext(
        wearer: controller.wearer,
        garment: widget.garment,
        occasion: widget.occasion,
        sampledColor: sampledColor,
      ));
      final renderFile =
          await controller.writeRenderBytes(request.id, result.renderPngBytes);
      final record = TryOnRecord.fromVerdict(
        id: request.id,
        createdAt: DateTime.now(),
        profilePhotoPath: controller.profilePhotoPath!,
        garmentPhotoPath: widget.garmentPhotoPath,
        renderPhotoPath: renderFile.path,
        garment: widget.garment,
        occasion: widget.occasion,
        verdict: verdict,
        cost: result.cost,
      );
      await controller.completeTryOn(record);
      _timer?.cancel();
      if (!mounted) return;
      Navigator.of(context).pushReplacement(MaterialPageRoute(
        builder: (_) => ResultScreen(record: record),
      ));
    } on TimeoutException {
      _timer?.cancel();
      if (!mounted) return;
      setState(() {
        _running = false;
        _failed = true;
        _timedOut = true;
      });
    } catch (_) {
      _timer?.cancel();
      if (!mounted) return;
      setState(() {
        _running = false;
        _failed = true;
        _timedOut = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Working on it')),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
        child: _failed ? _failureView(theme) : _progressView(theme),
      ),
    );
  }

  Widget _progressView(ThemeData theme) {
    final controller = AppScope.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Making your try-on', style: theme.textTheme.titleLarge),
        const SizedBox(height: 8),
        Text(
          controller.renderProvider.id == 'demo-composite'
              ? 'Demo mode: the composite is made on this phone, so this '
                  'is quick. The real render service usually takes 15 to '
                  '45 seconds on mobile data.'
              : 'Real renders usually take 15 to 45 seconds on mobile '
                  'data. Keep this screen open.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.72),
          ),
        ),
        const SizedBox(height: 30),
        for (var i = 0; i < _stages.length; i++)
          _StageRow(
            label: _stages[i],
            state: i < _stage
                ? _StageState.done
                : i == _stage
                    ? _StageState.active
                    : _StageState.waiting,
          ),
        const Spacer(),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${_elapsedSeconds}s elapsed',
              style: theme.textTheme.bodySmall?.copyWith(
                color:
                    theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            Text(
              'Stops at 90s; the retry is free',
              style: theme.textTheme.bodySmall?.copyWith(
                color:
                    theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: (_elapsedSeconds /
                    ProcessingScreen.hardTimeout.inSeconds)
                .clamp(0.0, 1.0),
            minHeight: 8,
          ),
        ),
      ],
    );
  }

  Widget _failureView(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.timer_off_outlined,
            size: 44, color: theme.colorScheme.error),
        const SizedBox(height: 14),
        Text(
          _timedOut ? 'That took too long' : 'The render did not finish',
          style: theme.textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        Text(
          _timedOut
              ? 'The render passed the 90 second limit, so it was '
                  'stopped before it could finish. No credit was used, '
                  'and retrying costs nothing. If it keeps timing out, '
                  'check your connection and try again on stronger '
                  'signal.'
              : 'Something interrupted the render before it finished. '
                  'No credit was used, and retrying costs nothing.',
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(height: 24),
        FilledButton.icon(
          onPressed: _run,
          icon: const Icon(Icons.refresh),
          label: const Text('Retry free'),
        ),
        const SizedBox(height: 10),
        OutlinedButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Back to the garment'),
        ),
      ],
    );
  }
}

enum _StageState { done, active, waiting }

class _StageRow extends StatelessWidget {
  const _StageRow({required this.label, required this.state});

  final String label;
  final _StageState state;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final (icon, color) = switch (state) {
      _StageState.done => (
          Icons.check_circle,
          theme.colorScheme.primary,
        ),
      _StageState.active => (
          Icons.radio_button_checked,
          theme.colorScheme.secondary,
        ),
      _StageState.waiting => (
          Icons.radio_button_unchecked,
          theme.colorScheme.onSurface.withValues(alpha: 0.3),
        ),
    };
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Icon(icon, size: 22, color: color),
          const SizedBox(width: 12),
          Text(
            label,
            style: theme.textTheme.bodyLarge?.copyWith(
              fontWeight: state == _StageState.waiting
                  ? FontWeight.w400
                  : FontWeight.w700,
              color: state == _StageState.waiting
                  ? theme.colorScheme.onSurface.withValues(alpha: 0.5)
                  : null,
            ),
          ),
          if (state == _StageState.active) ...[
            const SizedBox(width: 12),
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2.4),
            ),
          ],
        ],
      ),
    );
  }
}
