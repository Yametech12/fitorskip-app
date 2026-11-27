/// Bagay Verdict engine for FitOrSkip.
///
/// Pure Dart on purpose: no Flutter imports, so the whole engine is unit
/// tested without a widget tree. Dimension scoring sits behind the
/// [DimensionScorer] interface. Today the scorers are local heuristics over
/// descriptors the user confirms in the intake form. A vision model can
/// replace the scorers later without touching aggregation, bands, fix
/// selection, or the verdict card.
library;

/// The honesty limits note printed on every verdict card. The verdict judges
/// look and harmony from photos. It never claims exact size or true fit.
const String kVerdictHonestyNote =
    'This verdict judges color, proportion, and style harmony from photos. '
    'It does not measure exact size, fabric feel, or true fit. '
    'When you can, try the garment on in person.';

enum VerdictBand { bagay, pwedePa, diliBagay }

extension VerdictBandLabel on VerdictBand {
  String get label => switch (this) {
        VerdictBand.bagay => 'BAGAY',
        VerdictBand.pwedePa => 'PWEDE PA',
        VerdictBand.diliBagay => 'DILI BAGAY',
      };

  static VerdictBand fromScore(int score) {
    if (score >= 75) return VerdictBand.bagay;
    if (score >= 50) return VerdictBand.pwedePa;
    return VerdictBand.diliBagay;
  }
}

enum VerdictDimension {
  colorHarmony,
  silhouette,
  printScale,
  neckline,
  styleMatch,
  occasionFit,
}

extension VerdictDimensionLabel on VerdictDimension {
  String get label => switch (this) {
        VerdictDimension.colorHarmony => 'Color harmony',
        VerdictDimension.silhouette => 'Silhouette and proportions',
        VerdictDimension.printScale => 'Print scale and placement',
        VerdictDimension.neckline => 'Neckline and collar',
        VerdictDimension.styleMatch => 'Style match',
        VerdictDimension.occasionFit => 'Occasion fit',
      };

  /// Aggregation weights from the GT-153 plan rubric. They sum to 1.0.
  double get weight => switch (this) {
        VerdictDimension.colorHarmony => 0.24,
        VerdictDimension.silhouette => 0.20,
        VerdictDimension.printScale => 0.14,
        VerdictDimension.neckline => 0.12,
        VerdictDimension.styleMatch => 0.16,
        VerdictDimension.occasionFit => 0.14,
      };
}

enum SkinTone { fair, lightMedium, medium, deep }

enum Undertone { warm, cool, neutral }

enum GarmentColor {
  black,
  white,
  gray,
  navy,
  blue,
  green,
  red,
  orange,
  yellow,
  pink,
  purple,
  brown,
  beige,
}

extension GarmentColorLabel on GarmentColor {
  String get label => switch (this) {
        GarmentColor.black => 'Black',
        GarmentColor.white => 'White',
        GarmentColor.gray => 'Gray',
        GarmentColor.navy => 'Navy',
        GarmentColor.blue => 'Blue',
        GarmentColor.green => 'Green',
        GarmentColor.red => 'Red',
        GarmentColor.orange => 'Orange',
        GarmentColor.yellow => 'Yellow',
        GarmentColor.pink => 'Pink',
        GarmentColor.purple => 'Purple',
        GarmentColor.brown => 'Brown',
        GarmentColor.beige => 'Beige or cream',
      };
}

enum PrintScale { none, small, medium, large }

enum Neckline { crew, vNeck, scoop, collared, henley, turtleneck }

extension NecklineLabel on Neckline {
  String get label => switch (this) {
        Neckline.crew => 'Crew neck',
        Neckline.vNeck => 'V-neck',
        Neckline.scoop => 'Scoop neck',
        Neckline.collared => 'Collared or polo',
        Neckline.henley => 'Henley',
        Neckline.turtleneck => 'Turtleneck',
      };
}

enum GarmentFit { slim, regular, relaxed, oversized }

extension GarmentFitLabel on GarmentFit {
  String get label => switch (this) {
        GarmentFit.slim => 'Slim fit',
        GarmentFit.regular => 'Regular fit',
        GarmentFit.relaxed => 'Relaxed fit',
        GarmentFit.oversized => 'Oversized',
      };
}

enum BodyFrame { slim, average, broad }

enum StyleTag { casual, street, smartCasual, formal, sporty, vintage }

extension StyleTagLabel on StyleTag {
  String get label => switch (this) {
        StyleTag.casual => 'Casual',
        StyleTag.street => 'Street',
        StyleTag.smartCasual => 'Smart casual',
        StyleTag.formal => 'Formal',
        StyleTag.sporty => 'Sporty',
        StyleTag.vintage => 'Vintage',
      };
}

enum Occasion { everyday, school, office, event, date, church }

extension OccasionLabel on Occasion {
  String get label => switch (this) {
        Occasion.everyday => 'Everyday',
        Occasion.school => 'School',
        Occasion.office => 'Office',
        Occasion.event => 'Event or party',
        Occasion.date => 'Date',
        Occasion.church => 'Church',
      };
}

/// What the wearer tells us once, in profile setup.
class WearerProfile {
  const WearerProfile({
    required this.skinTone,
    required this.undertone,
    required this.frame,
    required this.preferredStyles,
  });

  final SkinTone skinTone;
  final Undertone undertone;
  final BodyFrame frame;
  final Set<StyleTag> preferredStyles;

  Map<String, Object?> toJson() => {
        'skinTone': skinTone.name,
        'undertone': undertone.name,
        'frame': frame.name,
        'preferredStyles': preferredStyles.map((s) => s.name).toList(),
      };

  factory WearerProfile.fromJson(Map<String, Object?> json) => WearerProfile(
        skinTone: SkinTone.values.byName(json['skinTone'] as String),
        undertone: Undertone.values.byName(json['undertone'] as String),
        frame: BodyFrame.values.byName(json['frame'] as String),
        preferredStyles: (json['preferredStyles'] as List<Object?>)
            .map((s) => StyleTag.values.byName(s as String))
            .toSet(),
      );

  static const WearerProfile defaults = WearerProfile(
    skinTone: SkinTone.medium,
    undertone: Undertone.warm,
    frame: BodyFrame.average,
    preferredStyles: {StyleTag.casual, StyleTag.street},
  );
}

/// What the intake form records about one garment.
class GarmentProfile {
  const GarmentProfile({
    required this.color,
    required this.printScale,
    required this.neckline,
    required this.fit,
    required this.styles,
    required this.occasions,
  });

  final GarmentColor color;
  final PrintScale printScale;
  final Neckline neckline;
  final GarmentFit fit;
  final Set<StyleTag> styles;
  final Set<Occasion> occasions;

  Map<String, Object?> toJson() => {
        'color': color.name,
        'printScale': printScale.name,
        'neckline': neckline.name,
        'fit': fit.name,
        'styles': styles.map((s) => s.name).toList(),
        'occasions': occasions.map((o) => o.name).toList(),
      };

  factory GarmentProfile.fromJson(Map<String, Object?> json) => GarmentProfile(
        color: GarmentColor.values.byName(json['color'] as String),
        printScale: PrintScale.values.byName(json['printScale'] as String),
        neckline: Neckline.values.byName(json['neckline'] as String),
        fit: GarmentFit.values.byName(json['fit'] as String),
        styles: (json['styles'] as List<Object?>)
            .map((s) => StyleTag.values.byName(s as String))
            .toSet(),
        occasions: (json['occasions'] as List<Object?>)
            .map((o) => Occasion.values.byName(o as String))
            .toSet(),
      );
}

/// Everything one scorer is allowed to look at.
class VerdictContext {
  const VerdictContext({
    required this.wearer,
    required this.garment,
    required this.occasion,
  });

  final WearerProfile wearer;
  final GarmentProfile garment;

  /// The occasion the wearer picked for this try-on.
  final Occasion occasion;
}

class DimensionScore {
  const DimensionScore({
    required this.dimension,
    required this.score,
    required this.note,
  });

  final VerdictDimension dimension;

  /// 0 to 100. The engine clamps whatever a scorer returns into this range.
  final int score;
  final String note;
}

/// One dimension of the verdict. Implementations must be deterministic:
/// the same context always returns the same score.
abstract interface class DimensionScorer {
  VerdictDimension get dimension;
  DimensionScore score(VerdictContext context);

  /// A concrete, single change that would raise this dimension, or null when
  /// the dimension is already strong. Used for fix selection.
  String? suggestFix(VerdictContext context, int currentScore);
}

class VerdictResult {
  const VerdictResult({
    required this.overallScore,
    required this.band,
    required this.dimensions,
    required this.suggestedFix,
    required this.fixDimension,
    required this.honestyNote,
  });

  final int overallScore;
  final VerdictBand band;
  final List<DimensionScore> dimensions;

  /// One suggested fix, present whenever the verdict is not BAGAY.
  final String? suggestedFix;
  final VerdictDimension? fixDimension;
  final String honestyNote;

  DimensionScore get weakest => dimensions.reduce(
      (a, b) => a.score <= b.score ? a : b);
}

/// Aggregates six dimension scores into the verdict. Aggregation, bands, and
/// fix selection live here and nowhere else, so a future vision-backed
/// scorer set cannot change the rules by accident.
class VerdictEngine {
  VerdictEngine(List<DimensionScorer> scorers)
      : _scorers = List.unmodifiable(scorers) {
    final seen = <VerdictDimension>{};
    for (final scorer in _scorers) {
      if (!seen.add(scorer.dimension)) {
        throw ArgumentError('Duplicate scorer for ${scorer.dimension}');
      }
    }
    if (seen.length != VerdictDimension.values.length) {
      throw ArgumentError(
          'VerdictEngine needs exactly one scorer per dimension');
    }
  }

  final List<DimensionScorer> _scorers;

  VerdictResult evaluate(VerdictContext context) {
    final scores = <DimensionScore>[];
    final byDimension = <VerdictDimension, DimensionScore>{};
    var weighted = 0.0;
    for (final dimension in VerdictDimension.values) {
      final scorer =
          _scorers.firstWhere((s) => s.dimension == dimension);
      final raw = scorer.score(context);
      final clamped = raw.score.clamp(0, 100).toInt();
      final score = DimensionScore(
        dimension: dimension,
        score: clamped,
        note: raw.note,
      );
      scores.add(score);
      byDimension[dimension] = score;
      weighted += clamped * dimension.weight;
    }
    final overall = weighted.round().clamp(0, 100).toInt();
    final band = VerdictBandLabel.fromScore(overall);

    String? fix;
    VerdictDimension? fixDimension;
    if (band != VerdictBand.bagay) {
      // Fix selection: walk dimensions from weakest to strongest and take
      // the first concrete fix a scorer can offer.
      final ordered = [...scores]
        ..sort((a, b) => a.score.compareTo(b.score));
      for (final candidate in ordered) {
        final scorer = _scorers
            .firstWhere((s) => s.dimension == candidate.dimension);
        final suggestion = scorer.suggestFix(context, candidate.score);
        if (suggestion != null) {
          fix = suggestion;
          fixDimension = candidate.dimension;
          break;
        }
      }
    }

    return VerdictResult(
      overallScore: overall,
      band: band,
      dimensions: List.unmodifiable(scores),
      suggestedFix: fix,
      fixDimension: fixDimension,
      honestyNote: kVerdictHonestyNote,
    );
  }
}
