/// Credits: the plan's pricing model as display logic only. No payment
/// integration in v1; buying is visibly disabled and labelled as a later
/// phase, never faked.
library;

import 'package:material_ui/material_ui.dart';

import '../app_state.dart';

class CreditsScreen extends StatelessWidget {
  const CreditsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
      children: [
        Text('Your credits', style: theme.textTheme.titleLarge),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Try-ons left',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.white.withValues(alpha: 0.85),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${controller.creditsRemaining}',
                style: const TextStyle(
                  fontSize: 52,
                  fontWeight: FontWeight.w900,
                  height: 1,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '${controller.creditsUsed} used of '
                '${controller.creditsTotal} free try-ons',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.white.withValues(alpha: 0.85),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),
        Text('How credits work', style: theme.textTheme.titleMedium),
        const SizedBox(height: 10),
        const _PlanRow(
          title: 'Free tier',
          price: 'Free',
          detail: '3 try-ons with the full Bagay Verdict, so you can '
              'judge the app before paying anything.',
          active: true,
        ),
        const _PlanRow(
          title: 'Consumer pack',
          price: 'P${CreditModel.packPricePhp} / month',
          detail: '${CreditModel.packCredits} try-on credits, verdict '
              'included. Capped on purpose: unlimited would not survive '
              'real render costs.',
        ),
        const _PlanRow(
          title: 'Seller starter',
          price: 'P${CreditModel.sellerStarterPricePhp} / month',
          detail: '${CreditModel.sellerStarterTryOns} buyer try-ons for '
              'ukay and RTW sellers. Arrives with seller mode.',
        ),
        const _PlanRow(
          title: 'Seller pro',
          price: 'P${CreditModel.sellerProPricePhp} / month',
          detail: '${CreditModel.sellerProTryOns} buyer try-ons, for '
              'busy shops. Arrives with seller mode.',
        ),
        const SizedBox(height: 14),
        FilledButton(
          onPressed: null,
          child: Text(
              'Buy P${CreditModel.packPricePhp} pack (payments arrive '
              'in a later phase)'),
        ),
        const SizedBox(height: 8),
        Text(
          'Payments (GCash and Maya) are not connected in this build, so '
          'buying is disabled rather than faked.',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
          ),
        ),
      ],
    );
  }
}

class _PlanRow extends StatelessWidget {
  const _PlanRow({
    required this.title,
    required this.price,
    required this.detail,
    this.active = false,
  });

  final String title;
  final String price;
  final String detail;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(title,
                            style: theme.textTheme.bodyMedium
                                ?.copyWith(fontWeight: FontWeight.w800)),
                      ),
                      if (active) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary
                                .withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'YOUR PLAN',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.8,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    detail,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface
                          .withValues(alpha: 0.68),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                price,
                textAlign: TextAlign.right,
                style: theme.textTheme.bodyMedium
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
