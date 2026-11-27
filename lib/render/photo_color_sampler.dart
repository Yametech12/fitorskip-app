/// Flutter-side garment photo color sampling.
///
/// Decodes the garment photo, downscales it, and hands the raw pixels to
/// the pure sampler in verdict/color_sampling.dart. Every failure path
/// returns null: sampling is an aid, and the verdict engine falls back to
/// the descriptor color whenever this returns null.
library;

import 'dart:io';
import 'dart:ui' as ui;

import '../verdict/color_sampling.dart';
import '../verdict/verdict_engine.dart';

/// Measures the dominant color of the garment photo at [path], or null
/// when the photo cannot be decoded or holds no usable color.
Future<GarmentColor?> sampleGarmentPhotoColor(String path) async {
  ui.Codec? codec;
  try {
    final bytes = await File(path).readAsBytes();
    codec = await ui.instantiateImageCodec(bytes, targetWidth: 96);
    final frame = await codec.getNextFrame();
    final image = frame.image;
    try {
      final byteData =
          await image.toByteData(format: ui.ImageByteFormat.rawRgba);
      if (byteData == null) return null;
      final sample = sampleDominantColors(
        byteData.buffer.asUint8List(),
        image.width,
        image.height,
      );
      final dominant = sample?.dominant;
      if (sample == null || dominant == null) return null;
      // A photo that is almost entirely background carries no garment
      // color worth trusting.
      if (sample.keptPixelRatio < 0.05) return null;
      return garmentColorFromRgb(dominant.red, dominant.green, dominant.blue);
    } finally {
      image.dispose();
    }
  } catch (_) {
    return null;
  } finally {
    codec?.dispose();
  }
}
