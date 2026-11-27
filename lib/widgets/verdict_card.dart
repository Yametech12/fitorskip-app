/// The Bagay Verdict card, styled as a clothing hang tag: punched hole,
/// stitched edge, and the verdict stamped large. This card is the product's
/// proof surface, so it renders identically on the result screen and in
/// history details.
library;

import 'package:material_ui/material_ui.dart';

import '../theme.dart';
import '../verdict/verdict_engine.dart';

class VerdictCard extends StatelessWidget {
  const VerdictCard({
    super.key,
    required this.verdict,
    this.compact = false,
  });

  final VerdictResult verdict;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    final bandColor = FitColors.bandColor(verdict.band, dark: dark);
    return Container(
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: dark ? FitColors.lineDark : FitColors.lineLight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _TagHeader(bandColor: bandColor),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 6, 18, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Flexible(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${verdict.overallScore}',
                              style: TextStyle(
                                fontSize: compact ? 44 : 58,
                                fontWeight: FontWeight.w900,
                                height: 0.95,
                                letterSpacing: -1.5,
                                color: bandColor,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Text(
                                '/ 100',
                                style:
                                    theme.textTheme.titleMedium?.copyWith(
                                  color: theme.colorScheme.onSurface
                                      .withValues(alpha: 0.55),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    _Stamp(band: verdict.band, color: bandColor),
                  ],
                ),
                const SizedBox(height: 14),
                _ScoreBar(score: verdict.overallScore, color: bandColor),
                const SizedBox(height: 18),
                for (final dimension in verdict.dimensions) ...[
                  _DimensionRow(score: dimension, bandColor: bandColor),
                  const SizedBox(height: 10),
                ],
                if (verdict.suggestedFix != null) ...[
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: bandColor.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: bandColor.withValues(alpha: 0.45),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.lightbulb_outline,
                            size: 19, color: bandColor),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'One fix: ${verdict.suggestedFix}',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 14),
                Text(
                  verdict.honestyNote,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface
                        .withValues(alpha: 0.62),
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The punched top strip of the hang tag.
class _TagHeader extends StatelessWidget {
  const _TagHeader({required this.bandColor});

  final Color bandColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 4),
      child: Row(
        children: [
          Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: bandColor, width: 3),
            ),
          ),
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              'BAGAY VERDICT',
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                letterSpacing: 2.2,
                color: bandColor,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'FitOrSkip',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }
}

class _Stamp extends StatelessWidget {
  const _Stamp({required this.band, required this.color});

  final VerdictBand band;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: -0.06,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          border: Border.all(color: color, width: 2.4),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          band.label,
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.4,
            color: color,
          ),
        ),
      ),
    );
  }
}

class _ScoreBar extends StatelessWidget {
  const _ScoreBar({required this.score, required this.color});

  final int score;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: score / 100,
            minHeight: 10,
            backgroundColor:
                Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.10),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
        const SizedBox(height: 5),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('DILI BAGAY',
                style: _scaleLabel(context, VerdictBand.diliBagay)),
            Text('PWEDE PA',
                style: _scaleLabel(context, VerdictBand.pwedePa)),
            Text('BAGAY', style: _scaleLabel(context, VerdictBand.bagay)),
          ],
        ),
      ],
    );
  }

  TextStyle _scaleLabel(BuildContext context, VerdictBand band) {
    return TextStyle(
      fontSize: 10,
      fontWeight: FontWeight.w700,
      letterSpacing: 1,
      color: FitColors.bandColor(
        band,
        dark: Theme.of(context).brightness == Brightness.dark,
      ).withValues(alpha: 0.85),
    );
  }
}

class _DimensionRow extends StatelessWidget {
  const _DimensionRow({required this.score, required this.bandColor});

  final DimensionScore score;
  final Color bandColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                score.dimension.label,
                style: theme.textTheme.bodyMedium
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
            Text(
              '${score.score}',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: bandColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 3),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: score.score / 100,
            minHeight: 5,
            backgroundColor:
                theme.colorScheme.onSurface.withValues(alpha: 0.10),
            valueColor: AlwaysStoppedAnimation<Color>(
                bandColor.withValues(alpha: 0.75)),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          score.note,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.66),
          ),
        ),
      ],
    );
  }
}

/// Small band chip used in history rows.
class BandChip extends StatelessWidget {
  const BandChip({super.key, required this.band, required this.score});

  final VerdictBand band;
  final int score;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final color = FitColors.bandColor(band, dark: dark);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        '${band.label} $score',
        style: TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.6,
          color: color,
        ),
      ),
    );
  }
}
