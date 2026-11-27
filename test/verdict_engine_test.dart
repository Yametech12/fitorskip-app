import 'package:fitorskip/verdict/heuristic_scorers.dart';
import 'package:fitorskip/verdict/verdict_engine.dart';
import 'package:flutter_test/flutter_test.dart';

/// A scorer that always returns the same value, for engine-rule tests.
class FixedScorer implements DimensionScorer {
  FixedScorer(this.dimension, this.value, {this.fix});

  @override
  final VerdictDimension dimension;
  final int value;
  final String? fix;

  @override
  DimensionScore score(VerdictContext context) =>
      DimensionScore(dimension: dimension, score: value, note: 'fixed');

  @override
  String? suggestFix(VerdictContext context, int currentScore) => fix;
}

VerdictEngine fixedEngine(int value, {String? Function(VerdictDimension)? fixFor}) {
  return VerdictEngine([
    for (final d in VerdictDimension.values)
      FixedScorer(d, value, fix: fixFor?.call(d)),
  ]);
}

const wearer = WearerProfile(
  skinTone: SkinTone.medium,
  undertone: Undertone.warm,
  frame: BodyFrame.average,
  preferredStyles: {StyleTag.casual, StyleTag.street},
);

VerdictContext contextWith(GarmentProfile garment,
        {Occasion occasion = Occasion.everyday, WearerProfile w = wearer}) =>
    VerdictContext(wearer: w, garment: garment, occasion: occasion);

const baseGarment = GarmentProfile(
  color: GarmentColor.red,
  printScale: PrintScale.none,
  neckline: Neckline.collared,
  fit: GarmentFit.regular,
  styles: {StyleTag.casual},
  occasions: {Occasion.everyday},
);

void main() {
  group('engine rules', () {
    test('band boundaries: 75 bagay, 74 and 50 pwede pa, 49 dili', () {
      expect(fixedEngine(75).evaluate(contextWith(baseGarment)).band,
          VerdictBand.bagay);
      expect(fixedEngine(74).evaluate(contextWith(baseGarment)).band,
          VerdictBand.pwedePa);
      expect(fixedEngine(50).evaluate(contextWith(baseGarment)).band,
          VerdictBand.pwedePa);
      expect(fixedEngine(49).evaluate(contextWith(baseGarment)).band,
          VerdictBand.diliBagay);
    });

    test('weighted aggregation uses the plan weights', () {
      final engine = VerdictEngine([
        FixedScorer(VerdictDimension.colorHarmony, 100),
        FixedScorer(VerdictDimension.silhouette, 0),
        FixedScorer(VerdictDimension.printScale, 0),
        FixedScorer(VerdictDimension.neckline, 0),
        FixedScorer(VerdictDimension.styleMatch, 0),
        FixedScorer(VerdictDimension.occasionFit, 0),
      ]);
      final result = engine.evaluate(contextWith(baseGarment));
      // 100 * 0.24 = 24.
      expect(result.overallScore, 24);
    });

    test('scores are clamped into 0..100', () {
      final high = fixedEngine(140).evaluate(contextWith(baseGarment));
      expect(high.overallScore, 100);
      expect(
          high.dimensions.every((d) => d.score == 100), isTrue);
      final low = fixedEngine(-5).evaluate(contextWith(baseGarment));
      expect(low.overallScore, 0);
    });

    test('bagay verdicts carry no fix', () {
      final engine = fixedEngine(90, fixFor: (_) => 'some fix');
      final result = engine.evaluate(contextWith(baseGarment));
      expect(result.band, VerdictBand.bagay);
      expect(result.suggestedFix, isNull);
    });

    test('fix comes from the weakest dimension that offers one', () {
      final engine = VerdictEngine([
        FixedScorer(VerdictDimension.colorHarmony, 60, fix: 'color fix'),
        FixedScorer(VerdictDimension.silhouette, 40, fix: 'fit fix'),
        FixedScorer(VerdictDimension.printScale, 90),
        FixedScorer(VerdictDimension.neckline, 90),
        FixedScorer(VerdictDimension.styleMatch, 90),
        FixedScorer(VerdictDimension.occasionFit, 90),
      ]);
      final result = engine.evaluate(contextWith(baseGarment));
      expect(result.suggestedFix, 'fit fix');
      expect(result.fixDimension, VerdictDimension.silhouette);
    });

    test('duplicate or missing scorers are rejected', () {
      expect(
        () => VerdictEngine([
          FixedScorer(VerdictDimension.colorHarmony, 50),
          FixedScorer(VerdictDimension.colorHarmony, 60),
        ]),
        throwsArgumentError,
      );
      expect(
        () => VerdictEngine(
            [FixedScorer(VerdictDimension.colorHarmony, 50)]),
        throwsArgumentError,
      );
    });

    test('every result carries the honesty note', () {
      final result =
          buildHeuristicVerdictEngine().evaluate(contextWith(baseGarment));
      expect(result.honestyNote, kVerdictHonestyNote);
      expect(result.honestyNote, contains('does not measure exact size'));
    });

    test('evaluation is deterministic', () {
      final engine = buildHeuristicVerdictEngine();
      final a = engine.evaluate(contextWith(baseGarment));
      final b = engine.evaluate(contextWith(baseGarment));
      expect(a.overallScore, b.overallScore);
      expect(
        a.dimensions.map((d) => d.score).toList(),
        b.dimensions.map((d) => d.score).toList(),
      );
    });
  });

  group('heuristic scorers', () {
    final engine = buildHeuristicVerdictEngine();

    int dimensionScore(VerdictResult r, VerdictDimension d) =>
        r.dimensions.firstWhere((s) => s.dimension == d).score;

    test('warm undertone: warm colors beat cool colors', () {
      final warm = engine.evaluate(contextWith(baseGarment));
      final cool = engine.evaluate(contextWith(const GarmentProfile(
        color: GarmentColor.navy,
        printScale: PrintScale.none,
        neckline: Neckline.collared,
        fit: GarmentFit.regular,
        styles: {StyleTag.casual},
        occasions: {Occasion.everyday},
      )));
      expect(dimensionScore(warm, VerdictDimension.colorHarmony), 88);
      expect(dimensionScore(cool, VerdictDimension.colorHarmony), 52);
    });

    test('contrast adjustments apply by skin tone', () {
      const deepWearer = WearerProfile(
        skinTone: SkinTone.deep,
        undertone: Undertone.warm,
        frame: BodyFrame.average,
        preferredStyles: {StyleTag.casual},
      );
      final red = engine.evaluate(
          contextWith(baseGarment, w: deepWearer));
      // Warm match 88 plus deep-skin bright bonus 4.
      expect(dimensionScore(red, VerdictDimension.colorHarmony), 92);

      const fairWearer = WearerProfile(
        skinTone: SkinTone.fair,
        undertone: Undertone.warm,
        frame: BodyFrame.average,
        preferredStyles: {StyleTag.casual},
      );
      final beige = engine.evaluate(contextWith(
        const GarmentProfile(
          color: GarmentColor.beige,
          printScale: PrintScale.none,
          neckline: Neckline.collared,
          fit: GarmentFit.regular,
          styles: {StyleTag.casual},
          occasions: {Occasion.everyday},
        ),
        w: fairWearer,
      ));
      // Warm match 88 minus fair-skin washout 10.
      expect(dimensionScore(beige, VerdictDimension.colorHarmony), 78);
    });

    test('silhouette follows the frame table', () {
      final regular = engine.evaluate(contextWith(baseGarment));
      expect(dimensionScore(regular, VerdictDimension.silhouette), 90);
      const slimWearer = WearerProfile(
        skinTone: SkinTone.medium,
        undertone: Undertone.warm,
        frame: BodyFrame.slim,
        preferredStyles: {StyleTag.casual},
      );
      final oversized = engine.evaluate(contextWith(
        const GarmentProfile(
          color: GarmentColor.red,
          printScale: PrintScale.none,
          neckline: Neckline.collared,
          fit: GarmentFit.oversized,
          styles: {StyleTag.casual},
          occasions: {Occasion.everyday},
        ),
        w: slimWearer,
      ));
      expect(dimensionScore(oversized, VerdictDimension.silhouette), 48);
    });

    test('style match scales with overlap', () {
      final full = engine.evaluate(contextWith(const GarmentProfile(
        color: GarmentColor.red,
        printScale: PrintScale.none,
        neckline: Neckline.collared,
        fit: GarmentFit.regular,
        styles: {StyleTag.casual, StyleTag.street},
        occasions: {Occasion.everyday},
      )));
      expect(dimensionScore(full, VerdictDimension.styleMatch), 100);
      final none = engine.evaluate(contextWith(const GarmentProfile(
        color: GarmentColor.red,
        printScale: PrintScale.none,
        neckline: Neckline.collared,
        fit: GarmentFit.regular,
        styles: {StyleTag.formal},
        occasions: {Occasion.everyday},
      )));
      expect(dimensionScore(none, VerdictDimension.styleMatch), 45);
    });

    test('occasion fit: made-for wins, wrong occasion scores low', () {
      final made = engine.evaluate(contextWith(baseGarment));
      expect(dimensionScore(made, VerdictDimension.occasionFit), 90);
      final wrong = engine.evaluate(contextWith(
        const GarmentProfile(
          color: GarmentColor.red,
          printScale: PrintScale.none,
          neckline: Neckline.collared,
          fit: GarmentFit.regular,
          styles: {StyleTag.casual},
          occasions: {Occasion.office},
        ),
      ));
      expect(dimensionScore(wrong, VerdictDimension.occasionFit), 44);
    });

    test('a weak color drags the verdict and earns a color fix', () {
      final result = engine.evaluate(contextWith(const GarmentProfile(
        color: GarmentColor.navy,
        printScale: PrintScale.large,
        neckline: Neckline.turtleneck,
        fit: GarmentFit.slim,
        styles: {StyleTag.casual},
        occasions: {Occasion.everyday},
      )));
      expect(result.band, VerdictBand.pwedePa);
      expect(result.fixDimension, VerdictDimension.colorHarmony);
      expect(result.suggestedFix, contains('green'));
    });

    test('a strong garment earns bagay with no fix', () {
      final result = engine.evaluate(contextWith(const GarmentProfile(
        color: GarmentColor.red,
        printScale: PrintScale.medium,
        neckline: Neckline.collared,
        fit: GarmentFit.regular,
        styles: {StyleTag.casual, StyleTag.street},
        occasions: {Occasion.everyday},
      )));
      expect(result.band, VerdictBand.bagay);
      expect(result.suggestedFix, isNull);
    });
  });
}
