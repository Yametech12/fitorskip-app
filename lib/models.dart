/// Persisted records for FitOrSkip.
library;

import 'render/try_on_provider.dart';
import 'verdict/verdict_engine.dart';

/// One completed try-on: photos on disk, the verdict summary, and what the
/// render cost. Full dimension scores are stored so the result screen can be
/// reopened from history without re-scoring.
class TryOnRecord {
  const TryOnRecord({
    required this.id,
    required this.createdAt,
    required this.profilePhotoPath,
    required this.garmentPhotoPath,
    required this.renderPhotoPath,
    required this.garment,
    required this.occasion,
    required this.overallScore,
    required this.band,
    required this.dimensionScores,
    required this.dimensionNotes,
    required this.suggestedFix,
    required this.cost,
    this.sampledColor,
  });

  final String id;
  final DateTime createdAt;
  final String profilePhotoPath;
  final String garmentPhotoPath;
  final String renderPhotoPath;
  final GarmentProfile garment;
  final Occasion occasion;
  final int overallScore;
  final VerdictBand band;
  final Map<VerdictDimension, int> dimensionScores;
  final Map<VerdictDimension, String> dimensionNotes;
  final String? suggestedFix;
  final RenderCostRecord cost;

  /// The garment color measured from the garment photo, when sampling
  /// succeeded for this try-on. Null for descriptor-scored records,
  /// including every record written before photo sampling existed.
  final GarmentColor? sampledColor;

  factory TryOnRecord.fromVerdict({
    required String id,
    required DateTime createdAt,
    required String profilePhotoPath,
    required String garmentPhotoPath,
    required String renderPhotoPath,
    required GarmentProfile garment,
    required Occasion occasion,
    required VerdictResult verdict,
    required RenderCostRecord cost,
  }) {
    return TryOnRecord(
      id: id,
      createdAt: createdAt,
      profilePhotoPath: profilePhotoPath,
      garmentPhotoPath: garmentPhotoPath,
      renderPhotoPath: renderPhotoPath,
      garment: garment,
      occasion: occasion,
      overallScore: verdict.overallScore,
      band: verdict.band,
      dimensionScores: {
        for (final d in verdict.dimensions) d.dimension: d.score,
      },
      dimensionNotes: {
        for (final d in verdict.dimensions) d.dimension: d.note,
      },
      suggestedFix: verdict.suggestedFix,
      cost: cost,
      sampledColor: verdict.sampledColor,
    );
  }

  VerdictResult toVerdictResult() => VerdictResult(
        overallScore: overallScore,
        band: band,
        dimensions: [
          for (final dimension in VerdictDimension.values)
            DimensionScore(
              dimension: dimension,
              score: dimensionScores[dimension] ?? 0,
              note: dimensionNotes[dimension] ?? '',
            ),
        ],
        suggestedFix: suggestedFix,
        fixDimension: null,
        honestyNote: kVerdictHonestyNote,
        colorFromPhoto: sampledColor != null,
        sampledColor: sampledColor,
      );

  Map<String, Object?> toJson() => {
        'id': id,
        'createdAt': createdAt.toIso8601String(),
        'profilePhotoPath': profilePhotoPath,
        'garmentPhotoPath': garmentPhotoPath,
        'renderPhotoPath': renderPhotoPath,
        'garment': garment.toJson(),
        'occasion': occasion.name,
        'overallScore': overallScore,
        'band': band.name,
        'dimensionScores': {
          for (final e in dimensionScores.entries) e.key.name: e.value,
        },
        'dimensionNotes': {
          for (final e in dimensionNotes.entries) e.key.name: e.value,
        },
        'suggestedFix': suggestedFix,
        'cost': cost.toJson(),
        'sampledColor': sampledColor?.name,
      };

  factory TryOnRecord.fromJson(Map<String, Object?> json) => TryOnRecord(
        id: json['id'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
        profilePhotoPath: json['profilePhotoPath'] as String,
        garmentPhotoPath: json['garmentPhotoPath'] as String,
        renderPhotoPath: json['renderPhotoPath'] as String,
        garment: GarmentProfile.fromJson(
            (json['garment'] as Map).cast<String, Object?>()),
        occasion: Occasion.values.byName(json['occasion'] as String),
        overallScore: json['overallScore'] as int,
        band: VerdictBand.values.byName(json['band'] as String),
        dimensionScores: {
          for (final e
              in (json['dimensionScores'] as Map).cast<String, Object?>().entries)
            VerdictDimension.values.byName(e.key): e.value as int,
        },
        dimensionNotes: {
          for (final e
              in (json['dimensionNotes'] as Map).cast<String, Object?>().entries)
            VerdictDimension.values.byName(e.key): e.value as String,
        },
        suggestedFix: json['suggestedFix'] as String?,
        cost: RenderCostRecord.fromJson(
            (json['cost'] as Map).cast<String, Object?>()),
        sampledColor: json['sampledColor'] == null
            ? null
            : GarmentColor.values.byName(json['sampledColor'] as String),
      );
}
