/// On-device garment color sampling for the Bagay Verdict engine.
///
/// Pure Dart on purpose: the sampler works on raw RGBA pixel bytes, so it
/// is unit tested with generated fixtures and never touches the image
/// codec. The Flutter side decodes and downscales the garment photo, then
/// hands the bytes here. Sampling is a measurement aid only: when it
/// fails, the engine falls back to the wearer-confirmed descriptor color.
library;

import 'dart:math' as math;

import 'verdict_engine.dart';

/// One measured color cluster from a photo.
class SampledColor {
  const SampledColor({
    required this.red,
    required this.green,
    required this.blue,
    required this.share,
  });

  /// Channel means of the cluster, 0 to 255.
  final int red;
  final int green;
  final int blue;

  /// Fraction of the kept (non-background) pixels in this cluster.
  final double share;
}

/// The outcome of sampling one photo.
class ColorSample {
  const ColorSample({
    required this.colors,
    required this.keptPixelRatio,
  });

  /// Dominant clusters, largest share first. Empty when nothing usable
  /// was found (blank, fully transparent, or all background).
  final List<SampledColor> colors;

  /// Fraction of all sampled pixels that survived the background filter.
  final double keptPixelRatio;

  SampledColor? get dominant => colors.isEmpty ? null : colors.first;

  bool get isUsable => colors.isNotEmpty;
}

/// Samples dominant colors from raw RGBA bytes ([rgba] length must be at
/// least width * height * 4).
///
/// Background handling: fully or mostly transparent pixels are skipped,
/// and near-white pixels (every channel at or above
/// [nearWhiteThreshold]) are skipped as the usual plain-wall or hanger
/// shot background. Remaining pixels are quantized to 5 bits per channel
/// and counted; the top [maxColors] clusters are returned with their
/// centroid colors.
///
/// Returns null when the buffer is too small to be the image it claims
/// to be. An all-background photo returns a sample with no colors.
ColorSample? sampleDominantColors(
  List<int> rgba,
  int width,
  int height, {
  int maxColors = 3,
  int nearWhiteThreshold = 245,
}) {
  if (width <= 0 || height <= 0) return null;
  if (rgba.length < width * height * 4) return null;

  // Bucket key: 5 bits per channel packed into one int.
  final counts = <int, int>{};
  final sums = <int, List<int>>{};
  var kept = 0;
  final total = width * height;
  for (var i = 0; i < total; i++) {
    final offset = i * 4;
    final alpha = rgba[offset + 3];
    if (alpha < 128) continue;
    final r = rgba[offset];
    final g = rgba[offset + 1];
    final b = rgba[offset + 2];
    if (r >= nearWhiteThreshold &&
        g >= nearWhiteThreshold &&
        b >= nearWhiteThreshold) {
      continue;
    }
    final key = ((r >> 3) << 10) | ((g >> 3) << 5) | (b >> 3);
    counts[key] = (counts[key] ?? 0) + 1;
    final sum = sums.putIfAbsent(key, () => [0, 0, 0]);
    sum[0] += r;
    sum[1] += g;
    sum[2] += b;
    kept++;
  }
  if (kept == 0) {
    return ColorSample(colors: const [], keptPixelRatio: 0);
  }
  final ranked = counts.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));
  final colors = <SampledColor>[];
  for (final entry in ranked.take(maxColors)) {
    final sum = sums[entry.key]!;
    final n = entry.value;
    colors.add(SampledColor(
      red: (sum[0] / n).round(),
      green: (sum[1] / n).round(),
      blue: (sum[2] / n).round(),
      share: n / kept,
    ));
  }
  return ColorSample(colors: colors, keptPixelRatio: kept / total);
}

/// Reference swatches for the named garment colors, in sRGB.
const Map<GarmentColor, List<int>> _swatches = {
  GarmentColor.black: [18, 18, 18],
  GarmentColor.white: [248, 248, 248],
  GarmentColor.gray: [128, 128, 128],
  GarmentColor.navy: [24, 36, 84],
  GarmentColor.blue: [42, 92, 196],
  GarmentColor.green: [42, 128, 62],
  GarmentColor.red: [196, 36, 36],
  GarmentColor.orange: [232, 116, 28],
  GarmentColor.yellow: [240, 204, 40],
  GarmentColor.pink: [238, 150, 180],
  GarmentColor.purple: [112, 62, 168],
  GarmentColor.brown: [110, 72, 44],
  GarmentColor.beige: [216, 196, 160],
  GarmentColor.maroon: [110, 24, 36],
  GarmentColor.olive: [110, 116, 52],
  GarmentColor.teal: [24, 128, 128],
  GarmentColor.lavender: [178, 164, 216],
  GarmentColor.mustard: [206, 160, 32],
};

/// Names a measured RGB color: the [GarmentColor] whose reference swatch
/// is nearest in RGB space, with two hue-aware corrections. A dark,
/// muted orange-brown measures nearer to maroon or gray than to brown in
/// raw RGB, so low-value warm colors are pulled to brown; a pale warm
/// color is pulled to beige.
GarmentColor garmentColorFromRgb(int red, int green, int blue) {
  var best = GarmentColor.black;
  var bestDistance = double.infinity;
  for (final entry in _swatches.entries) {
    final s = entry.value;
    final dr = red - s[0];
    final dg = green - s[1];
    final db = blue - s[2];
    final distance = (dr * dr + dg * dg + db * db).toDouble();
    if (distance < bestDistance) {
      bestDistance = distance;
      best = entry.key;
    }
  }
  final maxChannel = math.max(red, math.max(green, blue));
  final minChannel = math.min(red, math.min(green, blue));
  final saturation =
      maxChannel == 0 ? 0.0 : (maxChannel - minChannel) / maxChannel;
  // Warm, dark, and not clearly red: brown, unless it is already a dark
  // named color.
  if (maxChannel < 130 &&
      saturation > 0.25 &&
      red > green &&
      green >= blue &&
      best != GarmentColor.maroon &&
      best != GarmentColor.black &&
      best != GarmentColor.navy) {
    return GarmentColor.brown;
  }
  // Pale and warm with low saturation: beige.
  if (maxChannel >= 180 &&
      saturation <= 0.35 &&
      red >= green &&
      green >= blue &&
      best != GarmentColor.white &&
      best != GarmentColor.beige) {
    return GarmentColor.beige;
  }
  return best;
}
