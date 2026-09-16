import 'package:flutter/material.dart';

import '../utils/responsive_helper.dart';

class FinancialHealthCard extends StatelessWidget {
  final int score;
  final String label;

  const FinancialHealthCard({
    super.key,
    required this.score,
    required this.label,
  });

  Color get scoreColor {
    if (score >= 80) return Colors.green;
    if (score >= 60) return Colors.lightGreen;
    if (score >= 40) return Colors.orange;
    if (score >= 20) return Colors.deepOrange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final compact = ResponsiveHelper.useCompactLayout(context);
    final tablet = ResponsiveHelper.isTablet(context);
    final desktop = ResponsiveHelper.isDesktop(context);
    final landscape = ResponsiveHelper.isLandscape(context);

    final cardPadding = _cardPadding(
      context,
      compact: compact,
      tablet: tablet,
      desktop: desktop,
    );

    final contentSpacing = _contentSpacing(
      compact: compact,
      tablet: tablet,
      desktop: desktop,
    );

    final gaugeGap = _gaugeGap(
      compact: compact,
      landscape: landscape,
      desktop: desktop,
    );

    final gaugeSize = _gaugeSize(
      context,
      compact: compact,
      tablet: tablet,
      desktop: desktop,
      landscape: landscape,
    );

    final safeScore = score.clamp(0, 100);
    final progress = safeScore / 100;

    final scoreFontSize = _scoreFontSize(
      gaugeSize: gaugeSize,
      compact: compact,
      tablet: tablet,
      desktop: desktop,
    );

    final labelFontSize = _labelFontSize(
      compact: compact,
      tablet: tablet,
      desktop: desktop,
    );

    return Card(
      elevation: 1,
      shadowColor: scoreColor.withOpacity(.12),
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(compact ? 16 : 22),
      ),
      child: Padding(
        padding: EdgeInsets.all(cardPadding),
        child: Column(
          children: [
            // ─────────────────────────────────────────────
            // Header
            // ─────────────────────────────────────────────
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  padding: EdgeInsets.all(compact ? 8 : 11),
                  decoration: BoxDecoration(
                    color: scoreColor.withOpacity(.12),
                    borderRadius: BorderRadius.circular(compact ? 11 : 14),
                  ),
                  child: Icon(
                    Icons.favorite_rounded,
                    color: scoreColor,
                    size: compact ? 18 : 22,
                  ),
                ),

                SizedBox(width: contentSpacing),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Financial Health",
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: compact
                              ? 17
                              : tablet
                              ? 20
                              : 22,
                        ),
                      ),

                      const SizedBox(height: 2),

                      Text(
                        "Your current financial wellness score",
                        style: TextStyle(
                          color: colorScheme.onSurface.withOpacity(.65),
                          fontSize: compact ? 11 : 13,
                          height: 1.25,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            SizedBox(height: gaugeGap),

            // ─────────────────────────────────────────────
            // Score Gauge
            // ─────────────────────────────────────────────
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: safeScore.toDouble()),
              duration: const Duration(milliseconds: 1100),
              curve: Curves.easeOutCubic,
              builder: (context, value, child) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Circular gauge with ONLY the score inside.
                    SizedBox(
                      width: gaugeSize,
                      height: gaugeSize,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          CircularProgressIndicator(
                            value: value / 100,
                            strokeWidth: _strokeWidth(
                              compact: compact,
                              tablet: tablet,
                              desktop: desktop,
                            ),
                            strokeCap: StrokeCap.round,
                            backgroundColor:
                                colorScheme.surfaceContainerHighest,
                            color: scoreColor,
                          ),

                          Text(
                            value.toStringAsFixed(0),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: scoreFontSize,
                              fontWeight: FontWeight.w900,
                              height: 1,
                            ),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: compact ? 7 : 12),

                    // Label deliberately OUTSIDE the circular gauge.
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: compact ? 12 : 16,
                        vertical: compact ? 5 : 7,
                      ),
                      decoration: BoxDecoration(
                        color: scoreColor.withOpacity(.10),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: scoreColor,
                          fontSize: labelFontSize,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),

            SizedBox(height: compact ? 14 : 20),

            // ─────────────────────────────────────────────
            // Overall score
            // ─────────────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  "Overall Score",
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: compact ? 13 : 14,
                  ),
                ),

                Text(
                  "$safeScore / 100",
                  style: TextStyle(
                    color: scoreColor,
                    fontWeight: FontWeight.bold,
                    fontSize: compact ? 13 : 15,
                  ),
                ),
              ],
            ),

            SizedBox(height: compact ? 8 : 10),

            // ─────────────────────────────────────────────
            // Progress bar
            // ─────────────────────────────────────────────
            ClipRRect(
              borderRadius: BorderRadius.circular(30),
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: progress),
                duration: const Duration(milliseconds: 1200),
                curve: Curves.easeOutCubic,
                builder: (context, value, child) {
                  return LinearProgressIndicator(
                    value: value,
                    minHeight: compact ? 7 : 10,
                    backgroundColor: colorScheme.surfaceContainerHighest,
                    color: scoreColor,
                  );
                },
              ),
            ),

            SizedBox(height: compact ? 7 : 12),

            // ─────────────────────────────────────────────
            // Description
            // ─────────────────────────────────────────────
            Text(
              _scoreDescription(safeScore),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colorScheme.onSurface.withOpacity(.65),
                fontSize: compact ? 11 : 13,
                height: 1.3,
              ),
            ),
          ],
        ),
      ),
    );
  }

  double _cardPadding(
    BuildContext context, {
    required bool compact,
    required bool tablet,
    required bool desktop,
  }) {
    if (desktop) return 24;
    if (tablet) return 22;
    if (compact) return 15;

    return 18;
  }

  double _contentSpacing({
    required bool compact,
    required bool tablet,
    required bool desktop,
  }) {
    if (desktop) return 20;
    if (tablet) return 18;
    if (compact) return 12;

    return 14;
  }

  double _gaugeGap({
    required bool compact,
    required bool landscape,
    required bool desktop,
  }) {
    if (desktop) return 20;
    if (landscape) return 14;
    if (compact) return 10;

    return 16;
  }

  double _gaugeSize(
    BuildContext context, {
    required bool compact,
    required bool tablet,
    required bool desktop,
    required bool landscape,
  }) {
    final width = ResponsiveHelper.width(context);

    if (desktop) {
      return 190;
    }

    if (tablet) {
      return landscape ? 165 : 175;
    }

    if (landscape) {
      return 120;
    }

    if (compact) {
      return (width * .36).clamp(125.0, 140.0);
    }

    return (width * .42).clamp(140.0, 175.0);
  }

  double _strokeWidth({
    required bool compact,
    required bool tablet,
    required bool desktop,
  }) {
    if (desktop) return 15;
    if (tablet) return 13;
    if (compact) return 9;

    return 11;
  }

  double _scoreFontSize({
    required double gaugeSize,
    required bool compact,
    required bool tablet,
    required bool desktop,
  }) {
    if (compact) return 30;
    if (desktop) return 48;
    if (tablet) return 43;

    return gaugeSize * .28;
  }

  double _labelFontSize({
    required bool compact,
    required bool tablet,
    required bool desktop,
  }) {
    if (desktop) return 14;
    if (tablet) return 13;
    if (compact) return 11;

    return 12;
  }

  String _scoreDescription(int score) {
    if (score >= 80) {
      return "Excellent financial management. Keep up the good work.";
    }

    if (score >= 60) {
      return "Good financial health with some room for improvement.";
    }

    if (score >= 40) {
      return "Your finances are fairly balanced. Consider improving your spending habits.";
    }

    if (score >= 20) {
      return "Your financial health needs attention. Review your spending and budget.";
    }

    return "Your financial health needs significant attention. Start by reviewing your budget.";
  }
}
