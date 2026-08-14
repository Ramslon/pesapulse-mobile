import 'package:flutter/material.dart';

import '/utils/responsive_helper.dart';

class RecommendationCard extends StatelessWidget {
  final String budgetStatus;
  final String recommendation;
  final String categoryAdvice;
  final String topCategory;
  final double budgetUsage;

  const RecommendationCard({
    super.key,
    required this.budgetStatus,
    required this.recommendation,
    required this.categoryAdvice,
    required this.topCategory,
    required this.budgetUsage,
  });

  Color _accentColor(BuildContext context) {
    switch (budgetStatus.toLowerCase()) {
      case 'healthy':
        return Colors.green;

      case 'warning':
        return Colors.orange;

      case 'overspent':
        return Colors.deepOrange;

      case 'critical':
        return Colors.red;

      default:
        return Theme.of(context).colorScheme.primary;
    }
  }

  IconData _statusIcon() {
    switch (budgetStatus.toLowerCase()) {
      case 'critical':
        return Icons.warning_rounded;

      case 'overspent':
        return Icons.error_outline_rounded;

      case 'warning':
        return Icons.info_outline_rounded;

      case 'healthy':
        return Icons.check_circle_outline_rounded;

      default:
        return Icons.lightbulb_outline_rounded;
    }
  }

  String _statusDescription() {
    switch (budgetStatus.toLowerCase()) {
      case 'healthy':
        return 'Your spending is within a healthy range.';

      case 'warning':
        return 'Keep an eye on your spending as you approach your budget.';

      case 'overspent':
        return 'Your spending has exceeded the current budget.';

      case 'critical':
        return 'Immediate attention is recommended for your spending.';

      default:
        return 'Review your spending to stay on track.';
    }
  }

  String _usageLabel(double usage) {
    if (usage >= 100) {
      return 'Over budget';
    }

    if (usage >= 80) {
      return 'Approaching limit';
    }

    if (usage >= 50) {
      return 'Moderate usage';
    }

    return 'Healthy usage';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final accentColor = _accentColor(context);

    final usage = budgetUsage.clamp(0.0, 100.0);

    final isDark = theme.brightness == Brightness.dark;

    final isCompact = ResponsiveHelper.useCompactLayout(context);
    final isDense = ResponsiveHelper.useDenseVerticalLayout(context);

    final cardPadding = ResponsiveHelper.cardPadding(context);

    final normalSpacing = ResponsiveHelper.spacing(context);

    final sectionSpacing = ResponsiveHelper.sectionSpacing(context);

    final cardBackground = isDark
        ? colorScheme.surfaceContainerHighest
        : colorScheme.surface;

    final softAccent = accentColor.withOpacity(isDark ? 0.16 : 0.09);

    final iconSize = isCompact ? 42.0 : 46.0;

    final titleFontSize = isCompact ? 17.0 : 18.0;

    final recommendationFontSize = isCompact ? 13.5 : 14.5;

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: ResponsiveHelper.contentMaxWidth(context),
        ),
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: cardBackground,
            borderRadius: BorderRadius.circular(isCompact ? 18 : 22),
            border: Border.all(color: accentColor.withOpacity(0.16)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.12 : 0.06),
                blurRadius: isCompact ? 12 : 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Padding(
            padding: EdgeInsets.all(cardPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ---------------------------------------------------------
                // Header
                // ---------------------------------------------------------
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: iconSize,
                      height: iconSize,
                      decoration: BoxDecoration(
                        color: softAccent,
                        borderRadius: BorderRadius.circular(
                          isCompact ? 13 : 15,
                        ),
                      ),
                      child: Icon(
                        _statusIcon(),
                        color: accentColor,
                        size: isCompact ? 23 : 25,
                      ),
                    ),

                    SizedBox(width: normalSpacing),

                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Smart Recommendation',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontSize: titleFontSize,
                              fontWeight: FontWeight.w800,
                            ),
                          ),

                          const SizedBox(height: 3),

                          Text(
                            'Personalized guidance based on your spending',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.textTheme.bodySmall?.color
                                  ?.withOpacity(0.65),
                            ),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(width: normalSpacing * 0.5),

                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: isCompact ? 8 : 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: softAccent,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        budgetStatus.isEmpty
                            ? 'REVIEW'
                            : budgetStatus.toUpperCase(),
                        style: TextStyle(
                          color: accentColor,
                          fontSize: isCompact ? 9.5 : 10.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.6,
                        ),
                      ),
                    ),
                  ],
                ),

                SizedBox(
                  height: isDense ? normalSpacing : sectionSpacing * 0.75,
                ),

                // ---------------------------------------------------------
                // Main recommendation
                // ---------------------------------------------------------
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(isCompact ? 14 : 16),
                  decoration: BoxDecoration(
                    color: softAccent,
                    borderRadius: BorderRadius.circular(isCompact ? 15 : 17),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.auto_awesome_rounded,
                        color: accentColor,
                        size: isCompact ? 20 : 21,
                      ),

                      SizedBox(width: normalSpacing * 0.75),

                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'What you should know',
                              style: TextStyle(
                                color: accentColor,
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                              ),
                            ),

                            const SizedBox(height: 6),

                            Text(
                              recommendation.isEmpty
                                  ? 'Keep tracking your spending and financial goals to receive more personalized recommendations.'
                                  : recommendation,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontSize: recommendationFontSize,
                                height: 1.5,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: sectionSpacing * 0.75),

                // ---------------------------------------------------------
                // Top spending category
                // ---------------------------------------------------------
                Row(
                  children: [
                    Container(
                      width: isCompact ? 38 : 40,
                      height: isCompact ? 38 : 40,
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.pie_chart_outline_rounded,
                        size: 21,
                        color: colorScheme.primary,
                      ),
                    ),

                    SizedBox(width: normalSpacing * 0.85),

                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Top Spending Category',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.textTheme.bodySmall?.color
                                  ?.withOpacity(0.60),
                              fontWeight: FontWeight.w500,
                            ),
                          ),

                          const SizedBox(height: 2),

                          Text(
                            topCategory.isEmpty
                                ? 'No category data'
                                : topCategory,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),

                    Icon(
                      Icons.chevron_right_rounded,
                      color: theme.iconTheme.color?.withOpacity(0.45),
                    ),
                  ],
                ),

                SizedBox(height: sectionSpacing * 0.7),

                // ---------------------------------------------------------
                // Category advice
                // ---------------------------------------------------------
                if (categoryAdvice.isNotEmpty)
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(isCompact ? 13 : 15),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest.withOpacity(
                        isDark ? 0.55 : 0.65,
                      ),
                      borderRadius: BorderRadius.circular(isCompact ? 14 : 16),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.tips_and_updates_outlined,
                          color: colorScheme.primary,
                          size: 21,
                        ),

                        SizedBox(width: normalSpacing * 0.75),

                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Spending Tip',
                                style: theme.textTheme.labelLarge?.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),

                              const SizedBox(height: 5),

                              Text(
                                categoryAdvice,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  height: 1.45,
                                  fontSize: isCompact ? 12.5 : 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                SizedBox(height: sectionSpacing * 0.75),

                // ---------------------------------------------------------
                // Budget usage
                // ---------------------------------------------------------
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Budget Usage',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.textTheme.bodySmall?.color
                                  ?.withOpacity(0.60),
                              fontWeight: FontWeight.w500,
                            ),
                          ),

                          const SizedBox(height: 3),

                          TweenAnimationBuilder<double>(
                            duration: const Duration(milliseconds: 900),
                            curve: Curves.easeOutCubic,
                            tween: Tween<double>(begin: 0, end: usage),
                            builder: (_, value, __) {
                              return Text(
                                '${value.toStringAsFixed(1)}%',
                                style: theme.textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: accentColor,
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),

                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: softAccent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _usageLabel(usage),
                        style: TextStyle(
                          color: accentColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                TweenAnimationBuilder<double>(
                  duration: const Duration(milliseconds: 900),
                  curve: Curves.easeOutCubic,
                  tween: Tween<double>(begin: 0, end: usage / 100),
                  builder: (_, value, __) {
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: LinearProgressIndicator(
                        value: value,
                        minHeight: isCompact ? 8 : 9,
                        backgroundColor: colorScheme.surfaceContainerHighest,
                        valueColor: AlwaysStoppedAnimation<Color>(accentColor),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 7),

                Text(
                  _statusDescription(),
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontSize: 12,
                    color: theme.textTheme.bodySmall?.color?.withOpacity(0.60),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
