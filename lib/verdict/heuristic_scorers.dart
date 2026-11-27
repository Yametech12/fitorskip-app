/// Local heuristic scorers for the Bagay Verdict engine.
///
/// These stand in for the vision model the plan budgets for later. They are
/// deliberately simple, table-driven, and deterministic, so every score can
/// be explained and unit tested. When the vision scorer lands, it replaces
/// this file's classes behind the same [DimensionScorer] interface.
library;

import 'verdict_engine.dart';

/// Builds the production engine wired with the local heuristic scorers.
VerdictEngine buildHeuristicVerdictEngine() => VerdictEngine([
      ColorHarmonyScorer(),
      SilhouetteScorer(),
      PrintScaleScorer(),
      NecklineScorer(),
      StyleMatchScorer(),
      OccasionFitScorer(),
    ]);

enum _ColorFamily { warm, cool, neutral }

_ColorFamily _familyOf(GarmentColor color) => switch (color) {
      GarmentColor.red ||
      GarmentColor.orange ||
      GarmentColor.yellow ||
      GarmentColor.brown ||
      GarmentColor.beige ||
      GarmentColor.green =>
        _ColorFamily.warm,
      GarmentColor.blue ||
      GarmentColor.navy ||
      GarmentColor.purple ||
      GarmentColor.pink ||
      GarmentColor.gray =>
        _ColorFamily.cool,
      GarmentColor.black || GarmentColor.white => _ColorFamily.neutral,
    };

/// Color harmony: garment color family against the wearer's undertone, with
/// a contrast adjustment for skin tone depth.
class ColorHarmonyScorer implements DimensionScorer {
  @override
  VerdictDimension get dimension => VerdictDimension.colorHarmony;

  int _scoreFor(VerdictContext context, GarmentColor color) {
    final family = _familyOf(color);
    final undertone = context.wearer.undertone;
    var score = switch ((undertone, family)) {
      (Undertone.warm, _ColorFamily.warm) => 88,
      (Undertone.cool, _ColorFamily.cool) => 88,
      (Undertone.neutral, _) => 80,
      (_, _ColorFamily.neutral) => 76,
      _ => 52,
    };
    // Contrast adjustments: pale colors wash out fair skin, and very dark
    // colors flatten against deep skin.
    final tone = context.wearer.skinTone;
    if (tone == SkinTone.fair &&
        (color == GarmentColor.beige || color == GarmentColor.white)) {
      score -= 10;
    }
    if (tone == SkinTone.deep &&
        (color == GarmentColor.black || color == GarmentColor.navy)) {
      score -= 8;
    }
    if (tone == SkinTone.deep &&
        (color == GarmentColor.red ||
            color == GarmentColor.yellow ||
            color == GarmentColor.white)) {
      score += 4;
    }
    return score.clamp(0, 100).toInt();
  }

  @override
  DimensionScore score(VerdictContext context) {
    final color = context.garment.color;
    final value = _scoreFor(context, color);
    final note = switch (value) {
      >= 84 => '${color.label} sits well with your skin tone.',
      >= 65 => '${color.label} works, but it is not your strongest color.',
      _ => '${color.label} fights your undertone a little.',
    };
    return DimensionScore(
        dimension: dimension, score: value, note: note);
  }

  @override
  String? suggestFix(VerdictContext context, int currentScore) {
    if (currentScore >= 75) return null;
    var best = context.garment.color;
    var bestScore = currentScore;
    for (final candidate in GarmentColor.values) {
      final value = _scoreFor(context, candidate);
      if (value > bestScore) {
        bestScore = value;
        best = candidate;
      }
    }
    if (best == context.garment.color) {
      return 'Try the same shirt in a shade closer to your undertone.';
    }
    return 'Try this shirt in ${best.label.toLowerCase()} instead. '
        'It harmonizes better with your skin tone.';
  }
}

/// Silhouette: garment fit against the wearer's frame.
class SilhouetteScorer implements DimensionScorer {
  @override
  VerdictDimension get dimension => VerdictDimension.silhouette;

  static const Map<BodyFrame, Map<GarmentFit, int>> _table = {
    BodyFrame.slim: {
      GarmentFit.slim: 90,
      GarmentFit.regular: 82,
      GarmentFit.relaxed: 64,
      GarmentFit.oversized: 48,
    },
    BodyFrame.average: {
      GarmentFit.slim: 74,
      GarmentFit.regular: 90,
      GarmentFit.relaxed: 80,
      GarmentFit.oversized: 62,
    },
    BodyFrame.broad: {
      GarmentFit.slim: 58,
      GarmentFit.regular: 84,
      GarmentFit.relaxed: 88,
      GarmentFit.oversized: 70,
    },
  };

  int _scoreFor(VerdictContext context, GarmentFit fit) =>
      _table[context.wearer.frame]![fit]!;

  @override
  DimensionScore score(VerdictContext context) {
    final value = _scoreFor(context, context.garment.fit);
    final note = switch (value) {
      >= 84 => 'The cut follows your frame cleanly.',
      >= 65 => 'The cut is fine, just not the sharpest for your frame.',
      _ => 'This cut works against your proportions.',
    };
    return DimensionScore(dimension: dimension, score: value, note: note);
  }

  @override
  String? suggestFix(VerdictContext context, int currentScore) {
    if (currentScore >= 75) return null;
    var best = context.garment.fit;
    var bestScore = currentScore;
    for (final fit in GarmentFit.values) {
      final value = _scoreFor(context, fit);
      if (value > bestScore) {
        bestScore = value;
        best = fit;
      }
    }
    return 'Look for the same shirt in a ${best.label.toLowerCase()}. '
        'It balances your frame better.';
  }
}

/// Print scale: print size against the wearer's frame.
class PrintScaleScorer implements DimensionScorer {
  @override
  VerdictDimension get dimension => VerdictDimension.printScale;

  static const Map<BodyFrame, Map<PrintScale, int>> _table = {
    BodyFrame.slim: {
      PrintScale.none: 80,
      PrintScale.small: 88,
      PrintScale.medium: 70,
      PrintScale.large: 46,
    },
    BodyFrame.average: {
      PrintScale.none: 80,
      PrintScale.small: 82,
      PrintScale.medium: 86,
      PrintScale.large: 64,
    },
    BodyFrame.broad: {
      PrintScale.none: 80,
      PrintScale.small: 68,
      PrintScale.medium: 84,
      PrintScale.large: 88,
    },
  };

  int _scoreFor(VerdictContext context, PrintScale scale) =>
      _table[context.wearer.frame]![scale]!;

  @override
  DimensionScore score(VerdictContext context) {
    final scale = context.garment.printScale;
    final value = _scoreFor(context, scale);
    final note = switch ((scale, value)) {
      (PrintScale.none, _) => 'No print, so nothing competes with you.',
      (_, >= 84) => 'The print size matches your frame.',
      (_, >= 65) => 'The print is wearable, slightly off your scale.',
      _ => 'The print overwhelms or underwhelms your frame.',
    };
    return DimensionScore(dimension: dimension, score: value, note: note);
  }

  @override
  String? suggestFix(VerdictContext context, int currentScore) {
    if (currentScore >= 75) return null;
    var best = context.garment.printScale;
    var bestScore = currentScore;
    for (final scale in PrintScale.values) {
      if (scale == PrintScale.none) continue;
      final value = _scoreFor(context, scale);
      if (value > bestScore) {
        bestScore = value;
        best = scale;
      }
    }
    final word = switch (best) {
      PrintScale.small => 'a smaller, tighter print',
      PrintScale.medium => 'a medium scale print',
      PrintScale.large => 'a bolder, larger print',
      PrintScale.none => 'a plain version with no print',
    };
    return 'Try $word. Print scale should match your frame.';
  }
}

/// Neckline: neckline style against the wearer's frame.
class NecklineScorer implements DimensionScorer {
  @override
  VerdictDimension get dimension => VerdictDimension.neckline;

  static const Map<BodyFrame, Map<Neckline, int>> _table = {
    BodyFrame.slim: {
      Neckline.crew: 78,
      Neckline.vNeck: 84,
      Neckline.scoop: 80,
      Neckline.collared: 82,
      Neckline.henley: 86,
      Neckline.turtleneck: 64,
    },
    BodyFrame.average: {
      Neckline.crew: 84,
      Neckline.vNeck: 86,
      Neckline.scoop: 76,
      Neckline.collared: 88,
      Neckline.henley: 84,
      Neckline.turtleneck: 72,
    },
    BodyFrame.broad: {
      Neckline.crew: 72,
      Neckline.vNeck: 88,
      Neckline.scoop: 70,
      Neckline.collared: 90,
      Neckline.henley: 80,
      Neckline.turtleneck: 78,
    },
  };

  int _scoreFor(VerdictContext context, Neckline neckline) =>
      _table[context.wearer.frame]![neckline]!;

  @override
  DimensionScore score(VerdictContext context) {
    final value = _scoreFor(context, context.garment.neckline);
    final note = switch (value) {
      >= 84 => 'This neckline frames your shoulders well.',
      >= 65 => 'This neckline is acceptable, not ideal.',
      _ => 'This neckline shortens or crowds your upper body.',
    };
    return DimensionScore(dimension: dimension, score: value, note: note);
  }

  @override
  String? suggestFix(VerdictContext context, int currentScore) {
    if (currentScore >= 75) return null;
    var best = context.garment.neckline;
    var bestScore = currentScore;
    for (final neckline in Neckline.values) {
      final value = _scoreFor(context, neckline);
      if (value > bestScore) {
        bestScore = value;
        best = neckline;
      }
    }
    return 'Try a ${best.label.toLowerCase()} version. '
        'It opens up your frame better.';
  }
}

/// Style match: overlap between the garment's styles and the wearer's
/// preferred styles.
class StyleMatchScorer implements DimensionScorer {
  @override
  VerdictDimension get dimension => VerdictDimension.styleMatch;

  @override
  DimensionScore score(VerdictContext context) {
    final preferred = context.wearer.preferredStyles;
    final garmentStyles = context.garment.styles;
    if (preferred.isEmpty || garmentStyles.isEmpty) {
      return DimensionScore(
        dimension: dimension,
        score: 55,
        note: 'Not enough style information to judge this one.',
      );
    }
    final overlap = garmentStyles.intersection(preferred).length;
    final coverage = overlap / preferred.length;
    final value = (45 + 55 * coverage).round().clamp(0, 100).toInt();
    final note = switch (value) {
      >= 84 => 'This is squarely your style.',
      >= 65 => 'Close to your style, with a small stretch.',
      _ => 'This pulls away from the style you usually wear.',
    };
    return DimensionScore(dimension: dimension, score: value, note: note);
  }

  @override
  String? suggestFix(VerdictContext context, int currentScore) {
    if (currentScore >= 75) return null;
    final preferred = context.wearer.preferredStyles;
    if (preferred.isEmpty) return null;
    final names =
        preferred.map((s) => s.label.toLowerCase()).join(' or ');
    return 'Style it toward your usual $names look, or pick a piece '
        'that already lives there.';
  }
}

/// Occasion fit: whether the garment suits the occasion picked for this
/// try-on.
class OccasionFitScorer implements DimensionScorer {
  @override
  VerdictDimension get dimension => VerdictDimension.occasionFit;

  @override
  DimensionScore score(VerdictContext context) {
    final target = context.occasion;
    final garmentOccasions = context.garment.occasions;
    final int value;
    final String note;
    if (garmentOccasions.contains(target)) {
      value = 90;
      note = 'Right at home for ${target.label.toLowerCase()}.';
    } else if (garmentOccasions.contains(Occasion.everyday) &&
        (target == Occasion.school || target == Occasion.date)) {
      value = 62;
      note = 'An everyday piece can stretch here, with effort.';
    } else {
      value = 44;
      note = 'This piece is dressed for a different occasion.';
    }
    return DimensionScore(dimension: dimension, score: value, note: note);
  }

  @override
  String? suggestFix(VerdictContext context, int currentScore) {
    if (currentScore >= 75) return null;
    return 'Save this one for ${context.garment.occasions.isEmpty ? 'everyday wear' : context.garment.occasions.first.label.toLowerCase()}, '
        'and pick a piece made for ${context.occasion.label.toLowerCase()}.';
  }
}
