import 'package:flutter/material.dart';

import '../../utils/responsive_helper.dart';
import '../financial_health_card.dart';
import 'budget_section_header.dart';

class FinancialHealthSection extends StatelessWidget {
  final int financialScore;
  final String financialLabel;

  final double percentageUsed;
  final double budget;
  final double spent;

  final Widget budgetAlert;
  final String categoryAdvice;

  const FinancialHealthSection({
    super.key,
    required this.financialScore,
    required this.financialLabel,
    required this.percentageUsed,
    required this.budget,
    required this.spent,
    required this.budgetAlert,
    required this.categoryAdvice,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final compact = ResponsiveHelper.useCompactLayout(context);

    final tablet = ResponsiveHelper.isTablet(context);

    final desktop = ResponsiveHelper.isDesktop(context);

    final sectionSpacing = ResponsiveHelper.sectionSpacing(context);

    final spacing = ResponsiveHelper.spacing(context);

    final cardPadding = ResponsiveHelper.cardPadding(context);

    final descriptionSize = _descriptionSize(
      compact: compact,
      tablet: tablet,
      desktop: desktop,
    );

    final percentageSize = _percentageSize(
      compact: compact,
      tablet: tablet,
      desktop: desktop,
    );

    final progressHeight = _progressHeight(
      compact: compact,
      tablet: tablet,
      desktop: desktop,
    );

    final progressValue = budget > 0 ? (spent / budget).clamp(0.0, 1.0) : 0.0;

    final progressColor = _progressColor(context, percentageUsed);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        BudgetSectionHeader(
          title: "Financial Health",
          subtitle: "Your overall money management score",
        ),

        SizedBox(height: sectionSpacing),

        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.9, end: 1),
          duration: const Duration(milliseconds: 700),
          curve: Curves.easeOutBack,
          builder: (context, scale, child) {
            return Transform.scale(scale: scale, child: child);
          },
          child: FinancialHealthCard(
            score: financialScore,
            label: financialLabel,
          ),
        ),

        SizedBox(height: spacing),

        Container(
          width: double.infinity,
          padding: EdgeInsets.all(cardPadding),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest.withOpacity(.45),
            borderRadius: BorderRadius.circular(compact ? 14 : 18),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.info_outline_rounded,
                size: compact ? 19 : 21,
                color: colorScheme.primary,
              ),

              SizedBox(width: spacing),

              Expanded(
                child: Text(
                  "This score is calculated using your budget usage, "
                  "spending consistency, and savings potential.",
                  style: TextStyle(
                    color: colorScheme.onSurface.withOpacity(.7),
                    fontSize: descriptionSize,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),

        SizedBox(height: sectionSpacing),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              "Budget Usage",
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: percentageSize,
              ),
            ),

            Text(
              "${percentageUsed.toStringAsFixed(1)}% Used",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: percentageSize,
                color: progressColor,
              ),
            ),
          ],
        ),

        SizedBox(height: spacing),

        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: progressValue),
            duration: const Duration(milliseconds: 1000),
            curve: Curves.easeOutCubic,
            builder: (context, value, child) {
              return LinearProgressIndicator(
                value: value,
                minHeight: progressHeight,
                backgroundColor: colorScheme.surfaceContainerHighest,
                color: progressColor,
              );
            },
          ),
        ),

        SizedBox(height: sectionSpacing),

        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: const Duration(milliseconds: 1200),
          curve: Curves.easeOut,
          builder: (context, opacity, child) {
            return Opacity(opacity: opacity, child: child);
          },
          child: budgetAlert,
        ),

        if (categoryAdvice.isNotEmpty) ...[
          SizedBox(height: sectionSpacing),

          Container(
            width: double.infinity,
            padding: EdgeInsets.all(cardPadding),
            decoration: BoxDecoration(
              color: Colors.amber.withOpacity(.08),
              borderRadius: BorderRadius.circular(compact ? 14 : 18),
              border: Border.all(color: Colors.amber.withOpacity(.18)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.lightbulb_outline_rounded,
                  color: Colors.amber.shade800,
                  size: compact ? 20 : 23,
                ),

                SizedBox(width: spacing),

                Expanded(
                  child: Text(
                    categoryAdvice,
                    style: TextStyle(fontSize: descriptionSize, height: 1.4),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Color _progressColor(BuildContext context, double percentage) {
    final colorScheme = Theme.of(context).colorScheme;

    if (percentage >= 100) {
      return colorScheme.error;
    }

    if (percentage >= 80) {
      return Colors.orange;
    }

    return Colors.green;
  }

  double _descriptionSize({
    required bool compact,
    required bool tablet,
    required bool desktop,
  }) {
    if (desktop) return 14;
    if (tablet) return 14;
    if (compact) return 12;
    return 14;
  }

  double _percentageSize({
    required bool compact,
    required bool tablet,
    required bool desktop,
  }) {
    if (desktop) return 15;
    if (tablet) return 15;
    if (compact) return 13;
    return 14;
  }

  double _progressHeight({
    required bool compact,
    required bool tablet,
    required bool desktop,
  }) {
    if (desktop) return 10;
    if (tablet) return 10;
    if (compact) return 7;
    return 9;
  }
}
