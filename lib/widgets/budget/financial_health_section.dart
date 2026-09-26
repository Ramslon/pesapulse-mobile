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
    final compact = ResponsiveHelper.useCompactLayout(context);

    final desktop = ResponsiveHelper.isDesktop(context);

    final sectionSpacing = ResponsiveHelper.sectionSpacing(context);

    final spacing = ResponsiveHelper.spacing(context);

    final cardPadding = ResponsiveHelper.cardPadding(context);

    final normalizedScore = financialScore.clamp(0, 100);

    final normalizedUsage = percentageUsed.clamp(0.0, 100.0);

    final progressValue = budget > 0 ? (spent / budget).clamp(0.0, 1.0) : 0.0;

    final progressColor = _progressColor(context, normalizedUsage);

    final healthColor = _healthColor(context, normalizedScore);

    final healthIcon = _healthIcon(normalizedScore);

    final healthRecommendation = _healthRecommendation(
      score: normalizedScore,
      percentageUsed: normalizedUsage,
      categoryAdvice: categoryAdvice,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const BudgetSectionHeader(
          title: 'Financial Health',
          subtitle: 'Your overall money management score',
        ),

        SizedBox(height: sectionSpacing),

        _buildHealthCard(
          context,
          score: normalizedScore,
          healthColor: healthColor,
          healthIcon: healthIcon,
          recommendation: healthRecommendation,
          compact: compact,
          desktop: desktop,
        ),

        SizedBox(height: sectionSpacing),

        _buildBudgetUsage(
          context,
          percentageUsed: normalizedUsage,
          progressValue: progressValue,
          progressColor: progressColor,
          compact: compact,
          desktop: desktop,
        ),

        SizedBox(height: sectionSpacing),

        _buildScoreExplanation(
          context,
          compact: compact,
          desktop: desktop,
          cardPadding: cardPadding,
          spacing: spacing,
        ),

        SizedBox(height: sectionSpacing),

        _buildBudgetAlert(context, compact: compact, desktop: desktop),

        if (categoryAdvice.trim().isNotEmpty) ...[
          SizedBox(height: sectionSpacing),

          _buildCategoryAdvice(
            context,
            advice: categoryAdvice.trim(),
            compact: compact,
            desktop: desktop,
            cardPadding: cardPadding,
            spacing: spacing,
          ),
        ],
      ],
    );
  }

  Widget _buildHealthCard(
    BuildContext context, {
    required int score,
    required Color healthColor,
    required IconData healthIcon,
    required String recommendation,
    required bool compact,
    required bool desktop,
  }) {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 700),
      curve: Curves.easeOutCubic,
      tween: Tween(begin: 0.97, end: 1.0),
      builder: (_, scale, child) {
        return Transform.scale(scale: scale, child: child);
      },
      child: FinancialHealthCard(score: financialScore, label: financialLabel),
    );
  }

  Widget _buildBudgetUsage(
    BuildContext context, {
    required double percentageUsed,
    required double progressValue,
    required Color progressColor,
    required bool compact,
    required bool desktop,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final labelSize = desktop
        ? 13.5
        : compact
        ? 10.5
        : 12.0;

    final valueSize = desktop
        ? 13.5
        : compact
        ? 10.5
        : 12.0;

    final progressHeight = desktop
        ? 10.0
        : compact
        ? 7.0
        : 9.0;

    final radius = compact
        ? 14.0
        : desktop
        ? 18.0
        : 16.0;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(
        desktop
            ? 16
            : compact
            ? 11
            : 14,
      ),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: colorScheme.outline.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      width: compact ? 29 : 34,
                      height: compact ? 29 : 34,
                      decoration: BoxDecoration(
                        color: progressColor.withOpacity(0.09),
                        borderRadius: BorderRadius.circular(compact ? 9 : 11),
                      ),
                      child: Icon(
                        Icons.pie_chart_rounded,
                        color: progressColor,
                        size: compact ? 15 : 18,
                      ),
                    ),

                    SizedBox(width: compact ? 8 : 10),

                    Text(
                      'Budget Usage',
                      style: TextStyle(
                        color: colorScheme.onSurface,
                        fontSize: labelSize,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 10),

              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: compact ? 7 : 9,
                  vertical: compact ? 4 : 5,
                ),
                decoration: BoxDecoration(
                  color: progressColor.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${percentageUsed.toStringAsFixed(1)}%',
                  style: TextStyle(
                    color: progressColor,
                    fontSize: valueSize,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),

          SizedBox(height: compact ? 10 : 12),

          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: TweenAnimationBuilder<double>(
              duration: const Duration(milliseconds: 1000),
              curve: Curves.easeOutCubic,
              tween: Tween(begin: 0, end: progressValue),
              builder: (_, value, __) {
                return LinearProgressIndicator(
                  value: value,
                  minHeight: progressHeight,
                  backgroundColor: colorScheme.surfaceContainerHighest
                      .withOpacity(0.65),
                  valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                );
              },
            ),
          ),

          SizedBox(height: compact ? 7 : 8),

          Row(
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: progressColor,
                  shape: BoxShape.circle,
                ),
              ),

              const SizedBox(width: 7),

              Expanded(
                child: Text(
                  _usageDescription(percentageUsed),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: colorScheme.onSurfaceVariant.withOpacity(0.62),
                    fontSize: compact ? 9.5 : 10.5,
                    height: 1.3,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildScoreExplanation(
    BuildContext context, {
    required bool compact,
    required bool desktop,
    required double cardPadding,
    required double spacing,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(
        desktop
            ? 15
            : compact
            ? 11
            : 13,
      ),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withOpacity(0.40),
        borderRadius: BorderRadius.circular(compact ? 14 : 16),
        border: Border.all(color: colorScheme.outline.withOpacity(0.06)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: compact ? 30 : 34,
            height: compact ? 30 : 34,
            decoration: BoxDecoration(
              color: colorScheme.primary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(compact ? 9 : 11),
            ),
            child: Icon(
              Icons.info_outline_rounded,
              size: compact ? 16 : 18,
              color: colorScheme.primary,
            ),
          ),

          SizedBox(width: spacing),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'How your score is calculated',
                  style: TextStyle(
                    color: colorScheme.onSurface,
                    fontSize: desktop
                        ? 12.5
                        : compact
                        ? 10.5
                        : 11.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  'Your financial health score considers budget usage, spending consistency, and savings potential.',
                  style: TextStyle(
                    color: colorScheme.onSurfaceVariant.withOpacity(0.68),
                    fontSize: desktop
                        ? 12.5
                        : compact
                        ? 10.0
                        : 11.0,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBudgetAlert(
    BuildContext context, {
    required bool compact,
    required bool desktop,
  }) {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeOut,
      tween: Tween(begin: 0, end: 1),
      builder: (_, opacity, child) {
        return Opacity(opacity: opacity, child: child);
      },
      child: budgetAlert,
    );
  }

  Widget _buildCategoryAdvice(
    BuildContext context, {
    required String advice,
    required bool compact,
    required bool desktop,
    required double cardPadding,
    required double spacing,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    const adviceColor = Color(0xFFF59E0B);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(
        desktop
            ? 15
            : compact
            ? 11
            : 14,
      ),
      decoration: BoxDecoration(
        color: adviceColor.withOpacity(
          theme.brightness == Brightness.dark ? 0.10 : 0.055,
        ),
        borderRadius: BorderRadius.circular(compact ? 14 : 16),
        border: Border.all(color: adviceColor.withOpacity(0.15)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: compact ? 30 : 35,
            height: compact ? 30 : 35,
            decoration: BoxDecoration(
              color: adviceColor.withOpacity(0.10),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.lightbulb_rounded,
              color: adviceColor,
              size: compact ? 16 : 19,
            ),
          ),

          SizedBox(width: spacing),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Category Insight',
                  style: TextStyle(
                    color: colorScheme.onSurface,
                    fontSize: desktop
                        ? 13
                        : compact
                        ? 10.5
                        : 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  advice,
                  style: TextStyle(
                    color: colorScheme.onSurfaceVariant.withOpacity(0.74),
                    fontSize: desktop
                        ? 13
                        : compact
                        ? 10.5
                        : 11.5,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _healthColor(BuildContext context, int score) {
    if (score >= 80) {
      return const Color(0xFF16A34A);
    }

    if (score >= 60) {
      return const Color(0xFF65A30D);
    }

    if (score >= 40) {
      return const Color(0xFFF59E0B);
    }

    if (score >= 20) {
      return const Color(0xFFF97316);
    }

    return Theme.of(context).colorScheme.error;
  }

  IconData _healthIcon(int score) {
    if (score >= 80) {
      return Icons.health_and_safety_rounded;
    }

    if (score >= 60) {
      return Icons.trending_up_rounded;
    }

    if (score >= 40) {
      return Icons.warning_amber_rounded;
    }

    return Icons.error_outline_rounded;
  }

  Color _progressColor(BuildContext context, double percentage) {
    if (percentage >= 100) {
      return Theme.of(context).colorScheme.error;
    }

    if (percentage >= 80) {
      return const Color(0xFFF59E0B);
    }

    return const Color(0xFF16A34A);
  }

  String _healthRecommendation({
    required int score,
    required double percentageUsed,
    required String categoryAdvice,
  }) {
    if (categoryAdvice.trim().isNotEmpty) {
      return categoryAdvice.trim();
    }

    if (percentageUsed >= 100) {
      return 'Your budget has been exceeded. Review discretionary spending and focus on bringing expenses back under control.';
    }

    if (percentageUsed >= 80) {
      return 'You are approaching your budget limit. Keep discretionary spending controlled for the rest of the period.';
    }

    if (score >= 80) {
      return 'Your finances are in a strong position. Keep protecting the habits that are working.';
    }

    if (score >= 60) {
      return 'Your finances are generally healthy. Continue monitoring spending and building your savings position.';
    }

    if (score >= 40) {
      return 'There is room to improve your financial position. Focus on spending consistency and savings progress.';
    }

    return 'Review your spending and budget pressure to strengthen your financial position.';
  }

  String _usageDescription(double percentage) {
    if (percentage >= 100) {
      return 'Your spending has reached or exceeded the budget limit.';
    }

    if (percentage >= 80) {
      return 'You are close to reaching your budget limit.';
    }

    if (percentage >= 60) {
      return 'More than half of your budget has been used.';
    }

    return 'You still have room within your current budget.';
  }
}
