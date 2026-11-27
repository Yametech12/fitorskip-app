/// Demo try-on provider: zero spend, fully offline.
///
/// It composites the garment photo over the torso area of the profile photo
/// and stamps the result DEMO, twice, so nobody can mistake it for a real
/// virtual try-on render. Its job is to let the whole v1 flow (intake,
/// processing, verdict, history, credits) run end to end on a phone today.
/// The Bagay Verdict does not depend on this composite; it scores the
/// descriptors from the intake form.
library;

import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'try_on_provider.dart';

class DemoTryOnProvider implements TryOnProvider {
  const DemoTryOnProvider();

  @override
  String get id => 'demo-composite';

  @override
  String get label => 'Demo composite (no AI render)';

  static const int _canvasWidth = 900;
  static const int _canvasHeight = 1200;

  @override
  Future<TryOnResult> render(
    TryOnRequest request, {
    Duration timeout = const Duration(seconds: 90),
  }) async {
    final stopwatch = Stopwatch()..start();
    final work = _composite(request);
    final bytes = await work.timeout(timeout);
    stopwatch.stop();
    return TryOnResult(
      renderPngBytes: bytes,
      latency: stopwatch.elapsed,
      cost: const RenderCostRecord(
        providerId: 'demo-composite',
        estimatedCostUsd: 0,
        isDemo: true,
        note: 'Offline demo composite. No provider was called, '
            'nothing was uploaded, cost is zero.',
      ),
    );
  }

  Future<Uint8List> _composite(TryOnRequest request) async {
    final profile = await _decode(File(request.profilePhotoPath));
    final garment = await _decode(File(request.garmentPhotoPath));
    try {
      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);
      final size =
          const ui.Size(_canvasWidth * 1.0, _canvasHeight * 1.0);

      // Profile photo, cover-fitted to the canvas.
      _drawCover(canvas, profile, ui.Offset.zero & size);

      // Garment over the torso region: middle band of the frame.
      final torso = ui.Rect.fromLTWH(
        size.width * 0.16,
        size.height * 0.30,
        size.width * 0.68,
        size.height * 0.46,
      );
      canvas.save();
      final clip = ui.Path()
        ..addRRect(ui.RRect.fromRectAndRadius(
            torso, const ui.Radius.circular(36)));
      canvas.clipPath(clip);
      canvas.drawRect(
        torso,
        ui.Paint()..color = const ui.Color(0xFFF5EFE3),
      );
      _drawContain(
        canvas,
        garment,
        torso.inflate(-18),
        opacity: 0.94,
      );
      canvas.restore();
      canvas.drawRRect(
        ui.RRect.fromRectAndRadius(torso, const ui.Radius.circular(36)),
        ui.Paint()
          ..style = ui.PaintingStyle.stroke
          ..strokeWidth = 5
          ..color = const ui.Color(0xFF201A17),
      );

      _drawDemoStamp(canvas, size);

      final picture = recorder.endRecording();
      final image = await picture.toImage(_canvasWidth, _canvasHeight);
      final data =
          await image.toByteData(format: ui.ImageByteFormat.png);
      if (data == null) {
        throw StateError('Demo composite failed to encode.');
      }
      return data.buffer.asUint8List();
    } finally {
      profile.dispose();
      garment.dispose();
    }
  }

  Future<ui.Image> _decode(File file) async {
    final bytes = await file.readAsBytes();
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    return frame.image;
  }

  void _drawCover(ui.Canvas canvas, ui.Image image, ui.Rect target) {
    final src = _coverSource(image, target.size);
    canvas.drawImageRect(
        image, src, target, ui.Paint()..filterQuality = ui.FilterQuality.high);
  }

  void _drawContain(ui.Canvas canvas, ui.Image image, ui.Rect target,
      {double opacity = 1}) {
    final scale = _min(
      target.width / image.width,
      target.height / image.height,
    );
    final w = image.width * scale;
    final h = image.height * scale;
    final dst = ui.Rect.fromLTWH(
      target.left + (target.width - w) / 2,
      target.top + (target.height - h) / 2,
      w,
      h,
    );
    canvas.drawImageRect(
      image,
      ui.Offset.zero & ui.Size(image.width * 1.0, image.height * 1.0),
      dst,
      ui.Paint()
        ..filterQuality = ui.FilterQuality.high
        ..color = ui.Color.fromRGBO(255, 255, 255, opacity),
    );
  }

  ui.Rect _coverSource(ui.Image image, ui.Size target) {
    final imageAspect = image.width / image.height;
    final targetAspect = target.width / target.height;
    if (imageAspect > targetAspect) {
      final w = image.height * targetAspect;
      return ui.Rect.fromLTWH((image.width - w) / 2, 0, w, image.height * 1.0);
    }
    final h = image.width / targetAspect;
    return ui.Rect.fromLTWH(0, (image.height - h) / 2, image.width * 1.0, h);
  }

  double _min(double a, double b) => a < b ? a : b;

  /// Two honest labels: a diagonal watermark and a bottom chip.
  void _drawDemoStamp(ui.Canvas canvas, ui.Size size) {
    canvas.save();
    canvas.translate(size.width / 2, size.height * 0.52);
    canvas.rotate(-0.32);
    final watermark = _paragraph(
      'DEMO',
      fontSize: 150,
      color: const ui.Color(0x38FFFFFF),
      weight: ui.FontWeight.w900,
    );
    canvas.drawParagraph(
      watermark,
      ui.Offset(-watermark.longestLine / 2, -watermark.height / 2),
    );
    canvas.restore();

    final chipRect = ui.Rect.fromLTWH(
      size.width * 0.14,
      size.height * 0.845,
      size.width * 0.72,
      64,
    );
    canvas.drawRRect(
      ui.RRect.fromRectAndRadius(chipRect, const ui.Radius.circular(32)),
      ui.Paint()..color = const ui.Color(0xE6201A17),
    );
    final chipText = _paragraph(
      'DEMO RENDER, NOT A REAL TRY-ON',
      fontSize: 27,
      color: const ui.Color(0xFFF5EFE3),
      weight: ui.FontWeight.w700,
    );
    canvas.drawParagraph(
      chipText,
      ui.Offset(
        chipRect.left + (chipRect.width - chipText.longestLine) / 2,
        chipRect.top + (chipRect.height - chipText.height) / 2,
      ),
    );
  }

  ui.Paragraph _paragraph(
    String text, {
    required double fontSize,
    required ui.Color color,
    required ui.FontWeight weight,
  }) {
    final builder = ui.ParagraphBuilder(
      ui.ParagraphStyle(
        textAlign: ui.TextAlign.left,
        fontSize: fontSize,
        maxLines: 1,
      ),
    )
      ..pushStyle(ui.TextStyle(
        color: color,
        fontSize: fontSize,
        fontWeight: weight,
        letterSpacing: 2,
      ))
      ..addText(text);
    final paragraph = builder.build();
    paragraph.layout(const ui.ParagraphConstraints(width: 2400));
    return paragraph;
  }
}
