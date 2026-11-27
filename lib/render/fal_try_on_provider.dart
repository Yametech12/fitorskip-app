/// fal.ai try-on provider: the planned real renderer, NOT activated.
///
/// Activation is the owner's spend decision (GT-153 plan: fal.ai try-on at
/// about USD 0.04, P2.32, per render). To activate:
///
/// 1. The owner approves spend and provides a fal.ai API key through the
///    Secure Vault, never in source code.
/// 2. Implement [render] with an HTTPS call to the fal.ai try-on endpoint:
///    upload or reference the profile and garment photos, poll for the
///    result, download the render bytes, and return them with a
///    [RenderCostRecord] carrying the measured cost.
/// 3. In app_state.dart, change the provider factory to return this class
///    instead of [DemoTryOnProvider]. That is the only other edit.
///
/// Until then this class throws, so it can never be wired in silently.
library;

import 'try_on_provider.dart';

class FalTryOnProvider implements TryOnProvider {
  const FalTryOnProvider();

  @override
  String get id => 'fal-ai-tryon';

  @override
  String get label => 'fal.ai virtual try-on (not activated)';

  @override
  Future<TryOnResult> render(
    TryOnRequest request, {
    Duration timeout = const Duration(seconds: 90),
  }) {
    throw StateError(
      'fal.ai provider is not activated. Real renders are an owner spend '
      'decision; see the activation steps in fal_try_on_provider.dart.',
    );
  }
}
