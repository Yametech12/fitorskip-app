/// Try-on render providers for FitOrSkip.
///
/// The whole app talks to this interface only. Swapping the demo provider
/// for a paid one (fal.ai, FASHN) is a one-file change: implement
/// [TryOnProvider] in a new file and return it from the provider factory in
/// app_state.dart. Nothing in the screens, the verdict engine, or history
/// needs to change.
library;

import 'dart:typed_data';

class TryOnRequest {
  const TryOnRequest({
    required this.id,
    required this.profilePhotoPath,
    required this.garmentPhotoPath,
  });

  final String id;
  final String profilePhotoPath;
  final String garmentPhotoPath;
}

/// What one render cost, kept with every result so history can show it and
/// the blended-cost kill criteria in the plan stay measurable.
class RenderCostRecord {
  const RenderCostRecord({
    required this.providerId,
    required this.estimatedCostUsd,
    required this.isDemo,
    required this.note,
  });

  final String providerId;

  /// Estimated cost in US dollars. Demo renders are honestly 0.
  final double estimatedCostUsd;
  final bool isDemo;
  final String note;

  Map<String, Object?> toJson() => {
        'providerId': providerId,
        'estimatedCostUsd': estimatedCostUsd,
        'isDemo': isDemo,
        'note': note,
      };

  factory RenderCostRecord.fromJson(Map<String, Object?> json) =>
      RenderCostRecord(
        providerId: json['providerId'] as String,
        // Records saved before the USD switch (GT-176 item 10) carry
        // the old key; every such record is a demo render at 0, so
        // reading it under the new name loses nothing.
        estimatedCostUsd:
            ((json['estimatedCostUsd'] ?? json['estimatedCostPhp'] ?? 0)
                    as num)
                .toDouble(),
        isDemo: json['isDemo'] as bool,
        note: json['note'] as String,
      );
}

class TryOnResult {
  const TryOnResult({
    required this.renderPngBytes,
    required this.latency,
    required this.cost,
  });

  /// The finished render as PNG bytes.
  final Uint8List renderPngBytes;
  final Duration latency;
  final RenderCostRecord cost;

  bool get isDemo => cost.isDemo;
}

abstract interface class TryOnProvider {
  String get id;
  String get label;

  /// Renders [request]. Implementations should honor [timeout] by throwing
  /// a TimeoutException, which the processing screen turns into a free
  /// retry, matching the plan's 90 second hard timeout.
  Future<TryOnResult> render(
    TryOnRequest request, {
    Duration timeout = const Duration(seconds: 90),
  });
}
