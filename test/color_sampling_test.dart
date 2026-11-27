import 'package:fitorskip/models.dart';
import 'package:fitorskip/render/try_on_provider.dart';
import 'package:fitorskip/verdict/color_sampling.dart';
import 'package:fitorskip/verdict/heuristic_scorers.dart';
import 'package:fitorskip/verdict/verdict_engine.dart';
import 'package:flutter_test/flutter_test.dart';

/// Builds a solid RGBA fixture image.
List<int> solidImage(int width, int height, int r, int g, int b,
    {int alpha = 255}) {
  final bytes = List<int>.filled(width * height * 4, 0);
  for (var i = 0; i < width * height; i++) {
    bytes[i * 4] = r;
    bytes[i * 4 + 1] = g;
    bytes[i * 4 + 2] = b;
    bytes[i * 4 + 3] = alpha;
  }
  return bytes;
}

/// Builds an RGBA fixture: [garmentFraction] of the rows are the garment
/// color, the rest are near-white background.
List<int> garmentOnWhite(
    int width, int height, int r, int g, int b, double garmentFraction) {
  final bytes = solidImage(width, height, 250, 250, 250);
  final garmentRows = (height * garmentFraction).round();
  for (var y = 0; y < garmentRows; y++) {
    for (var x = 0; x < width; x++) {
      final i = (y * width + x) * 4;
      bytes[i] = r;
      bytes[i + 1] = g;
      bytes[i + 2] = b;
      bytes[i + 3] = 255;
    }
  }
  return bytes;
}

void main() {
  group('sampleDominantColors', () {
    test('a solid garment color dominates and maps to its name', () {
      final sample =
          sampleDominantColors(solidImage(8, 8, 24, 36, 84), 8, 8)!;
      expect(sample.isUsable, isTrue);
      expect(sample.keptPixelRatio, 1.0);
      expect(sample.dominant!.share, 1.0);
      expect(
        garmentColorFromRgb(
            sample.dominant!.red, sample.dominant!.green, sample.dominant!.blue),
        GarmentColor.navy,
      );
    });

    test('near-white background is ignored, garment color wins', () {
      final sample = sampleDominantColors(
          garmentOnWhite(10, 10, 196, 36, 36, 0.4), 10, 10)!;
      expect(sample.keptPixelRatio, closeTo(0.4, 0.001));
      expect(sample.dominant!.share, 1.0);
      expect(
        garmentColorFromRgb(
            sample.dominant!.red, sample.dominant!.green, sample.dominant!.blue),
        GarmentColor.red,
      );
    });

    test('an all-background photo yields no usable color', () {
      final sample =
          sampleDominantColors(solidImage(6, 6, 250, 250, 250), 6, 6)!;
      expect(sample.isUsable, isFalse);
      expect(sample.dominant, isNull);
      expect(sample.keptPixelRatio, 0.0);
    });

    test('transparent pixels are skipped', () {
      final bytes = solidImage(8, 8, 196, 36, 36);
      // Make the top half fully transparent blue.
      for (var i = 0; i < 8 * 4; i++) {
        bytes[i * 4] = 42;
        bytes[i * 4 + 1] = 92;
        bytes[i * 4 + 2] = 196;
        bytes[i * 4 + 3] = 0;
      }
      final sample = sampleDominantColors(bytes, 8, 8)!;
      expect(sample.keptPixelRatio, closeTo(0.5, 0.001));
      expect(
        garmentColorFromRgb(
            sample.dominant!.red, sample.dominant!.green, sample.dominant!.blue),
        GarmentColor.red,
      );
    });

    test('two garment colors rank by share', () {
      final bytes = garmentOnWhite(10, 10, 42, 128, 62, 0.6);
      // Repaint the top 2 garment rows blue: blue 20%, green 40%.
      for (var y = 0; y < 2; y++) {
        for (var x = 0; x < 10; x++) {
          final i = (y * 10 + x) * 4;
          bytes[i] = 42;
          bytes[i + 1] = 92;
          bytes[i + 2] = 196;
        }
      }
      final sample = sampleDominantColors(bytes, 10, 10)!;
      expect(sample.colors.length, 2);
      expect(sample.colors.first.share, closeTo(2 / 3, 0.01));
      expect(
        garmentColorFromRgb(sample.colors.first.red,
            sample.colors.first.green, sample.colors.first.blue),
        GarmentColor.green,
      );
      expect(sample.colors.last.share, closeTo(1 / 3, 0.01));
    });

    test('an undersized buffer is rejected', () {
      expect(sampleDominantColors([0, 0, 0, 255], 8, 8), isNull);
      expect(sampleDominantColors(const [], 0, 0), isNull);
    });
  });

  group('garmentColorFromRgb', () {
    final cases = <List<int>, GarmentColor>{
      [196, 36, 36]: GarmentColor.red,
      [24, 36, 84]: GarmentColor.navy,
      [42, 92, 196]: GarmentColor.blue,
      [42, 128, 62]: GarmentColor.green,
      [232, 116, 28]: GarmentColor.orange,
      [240, 204, 40]: GarmentColor.yellow,
      [238, 150, 180]: GarmentColor.pink,
      [112, 62, 168]: GarmentColor.purple,
      [110, 72, 44]: GarmentColor.brown,
      [216, 196, 160]: GarmentColor.beige,
      [110, 24, 36]: GarmentColor.maroon,
      [110, 116, 52]: GarmentColor.olive,
      [24, 128, 128]: GarmentColor.teal,
      [178, 164, 216]: GarmentColor.lavender,
      [206, 160, 32]: GarmentColor.mustard,
      [128, 128, 128]: GarmentColor.gray,
      [18, 18, 18]: GarmentColor.black,
      [248, 248, 248]: GarmentColor.white,
    };
    for (final entry in cases.entries) {
      test('rgb ${entry.key} names ${entry.value.name}', () {
        expect(
          garmentColorFromRgb(entry.key[0], entry.key[1], entry.key[2]),
          entry.value,
        );
      });
    }
  });

  group('engine integration', () {
    final engine = buildHeuristicVerdictEngine();
    const wearer = WearerProfile(
      skinTone: SkinTone.medium,
      undertone: Undertone.warm,
      frame: BodyFrame.average,
      preferredStyles: {StyleTag.casual},
    );
    const garment = GarmentProfile(
      color: GarmentColor.red,
      printScale: PrintScale.none,
      neckline: Neckline.collared,
      fit: GarmentFit.regular,
      styles: {StyleTag.casual},
      occasions: {Occasion.everyday},
    );

    int colorScore(VerdictResult r) => r.dimensions
        .firstWhere((d) => d.dimension == VerdictDimension.colorHarmony)
        .score;

    String colorNote(VerdictResult r) => r.dimensions
        .firstWhere((d) => d.dimension == VerdictDimension.colorHarmony)
        .note;

    test('a sampled color overrides the descriptor color', () {
      final result = engine.evaluate(VerdictContext(
        wearer: wearer,
        garment: garment,
        occasion: Occasion.everyday,
        sampledColor: GarmentColor.navy,
      ));
      // Navy is a cool color against a warm undertone: 52, not red's 88.
      expect(colorScore(result), 52);
      expect(result.colorFromPhoto, isTrue);
      expect(result.sampledColor, GarmentColor.navy);
      expect(colorNote(result), contains('read from your photo'));
      expect(colorNote(result), contains('Navy'));
    });

    test('no sample falls back to the descriptor color', () {
      final result = engine.evaluate(VerdictContext(
        wearer: wearer,
        garment: garment,
        occasion: Occasion.everyday,
      ));
      expect(colorScore(result), 88);
      expect(result.colorFromPhoto, isFalse);
      expect(colorNote(result), isNot(contains('read from your photo')));
    });

    test('a sampled color matching the descriptor still flags the photo',
        () {
      final result = engine.evaluate(VerdictContext(
        wearer: wearer,
        garment: garment,
        occasion: Occasion.everyday,
        sampledColor: GarmentColor.red,
      ));
      expect(colorScore(result), 88);
      expect(result.colorFromPhoto, isTrue);
    });
  });

  group('record persistence', () {
    test('sampled color survives a JSON round trip', () {
      final verdict = buildHeuristicVerdictEngine().evaluate(VerdictContext(
        wearer: WearerProfile.defaults,
        garment: const GarmentProfile(
          color: GarmentColor.red,
          printScale: PrintScale.none,
          neckline: Neckline.crew,
          fit: GarmentFit.regular,
          styles: {StyleTag.casual},
          occasions: {Occasion.everyday},
        ),
        occasion: Occasion.everyday,
        sampledColor: GarmentColor.teal,
      ));
      final record = TryOnRecord.fromVerdict(
        id: 'rt1',
        createdAt: DateTime(2026, 11, 27),
        profilePhotoPath: 'p.png',
        garmentPhotoPath: 'g.png',
        renderPhotoPath: 'r.png',
        garment: const GarmentProfile(
          color: GarmentColor.red,
          printScale: PrintScale.none,
          neckline: Neckline.crew,
          fit: GarmentFit.regular,
          styles: {StyleTag.casual},
          occasions: {Occasion.everyday},
        ),
        occasion: Occasion.everyday,
        verdict: verdict,
        cost: const RenderCostRecord(
          providerId: 'demo-composite',
          estimatedCostPhp: 0,
          isDemo: true,
          note: 'demo',
        ),
      );
      final restored = TryOnRecord.fromJson(record.toJson());
      expect(restored.sampledColor, GarmentColor.teal);
      expect(restored.toVerdictResult().colorFromPhoto, isTrue);
    });

    test('records written before sampling existed load with no sample',
        () {
      final verdict = buildHeuristicVerdictEngine().evaluate(VerdictContext(
        wearer: WearerProfile.defaults,
        garment: const GarmentProfile(
          color: GarmentColor.red,
          printScale: PrintScale.none,
          neckline: Neckline.crew,
          fit: GarmentFit.regular,
          styles: {StyleTag.casual},
          occasions: {Occasion.everyday},
        ),
        occasion: Occasion.everyday,
      ));
      final record = TryOnRecord.fromVerdict(
        id: 'rt2',
        createdAt: DateTime(2026, 11, 27),
        profilePhotoPath: 'p.png',
        garmentPhotoPath: 'g.png',
        renderPhotoPath: 'r.png',
        garment: const GarmentProfile(
          color: GarmentColor.red,
          printScale: PrintScale.none,
          neckline: Neckline.crew,
          fit: GarmentFit.regular,
          styles: {StyleTag.casual},
          occasions: {Occasion.everyday},
        ),
        occasion: Occasion.everyday,
        verdict: verdict,
        cost: const RenderCostRecord(
          providerId: 'demo-composite',
          estimatedCostPhp: 0,
          isDemo: true,
          note: 'demo',
        ),
      );
      final legacyJson = record.toJson()..remove('sampledColor');
      final restored = TryOnRecord.fromJson(legacyJson);
      expect(restored.sampledColor, isNull);
      expect(restored.toVerdictResult().colorFromPhoto, isFalse);
    });
  });
}
