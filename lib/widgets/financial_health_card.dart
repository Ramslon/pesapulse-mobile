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

    final cardPadding = ResponsiveHelper.cardPadding(context);

    final spacing = ResponsiveHelper.spacing(context);

    final sectionSpacing = ResponsiveHelper.sectionSpacing(context);

    final gaugeSize = _gaugeSize(
      context,
      compact: compact,
      tablet: tablet,
      desktop: desktop,
      landscape: landscape,
    );

    final safeScore = score.clamp(0, 100);
    final progress = safeScore / 100;

    return Card(
      elevation: 1,
      shadowColor: scoreColor.withOpacity(.12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(compact ? 18 : 22),
      ),
      child: Padding(
        padding: EdgeInsets.all(cardPadding),
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(compact ? 9 : 11),
                    decoration: BoxDecoration(
                      color: scoreColor.withOpacity(.12),
                      borderRadius: BorderRadius.circular(compact ? 12 : 14),
                    ),
                    child: Icon(
                      Icons.favorite_rounded,
                      color: scoreColor,
                      size: compact ? 19 : 22,
                    ),
                  ),

                  SizedBox(width: spacing),

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
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(
              height: compact
                  ? 22
                  : landscape
                  ? 24
                  : sectionSpacing,
            ),

            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: safeScore.toDouble()),
              duration: const Duration(milliseconds: 1100),
              curve: Curves.easeOutCubic,
              builder: (context, value, child) {
                return SizedBox(
                  width: gaugeSize,
                  height: gaugeSize,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CircularProgressIndicator(
                        value: value / 100,
                        strokeWidth: compact
                            ? 11
                            : tablet
                            ? 14
                            : 16,
                        strokeCap: StrokeCap.round,
                        backgroundColor: colorScheme.surfaceContainerHighest,
                        color: scoreColor,
                      ),

                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            value.toStringAsFixed(0),
                            style: TextStyle(
                              fontSize: gaugeSize * .25,
                              fontWeight: FontWeight.w900,
                            ),
                          ),

                          SizedBox(height: compact ? 3 : 5),

                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: compact ? 9 : 11,
                              vertical: compact ? 4 : 5,
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
                                fontSize: gaugeSize * .09,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),

            SizedBox(
              height: compact
                  ? 20
                  : landscape
                  ? 22
                  : sectionSpacing,
            ),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
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

            SizedBox(height: spacing),

            ClipRRect(
              borderRadius: BorderRadius.circular(30),
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: progress),
                duration: const Duration(milliseconds: 1200),
                curve: Curves.easeOutCubic,
                builder: (context, value, child) {
                  return LinearProgressIndicator(
                    value: value,
                    minHeight: compact ? 8 : 10,
                    backgroundColor: colorScheme.surfaceContainerHighest,
                    color: scoreColor,
                  );
                },
              ),
            ),

            SizedBox(height: compact ? 8 : 12),

            Text(
              _scoreDescription(safeScore),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colorScheme.onSurface.withOpacity(.65),
                fontSize: compact ? 11 : 13,
                height: 1.35,
              ),
            ),
          ],
        ),
      ),
    );
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
      return 125;
    }

    if (compact) {
      return (width * .42).clamp(135.0, 165.0);
    }

    return (width * .45).clamp(145.0, 180.0);
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
