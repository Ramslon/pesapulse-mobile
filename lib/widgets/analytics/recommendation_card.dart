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
    switch (budgetStatus.trim().toLowerCase()) {
      case 'healthy':
        return const Color(0xFF16A34A);

      case 'warning':
        return const Color(0xFFF59E0B);

      case 'overspent':
        return const Color(0xFFF97316);

      case 'critical':
        return const Color(0xFFDC2626);

      default:
        return Theme.of(context).colorScheme.primary;
    }
  }

  IconData _statusIcon() {
    switch (budgetStatus.trim().toLowerCase()) {
      case 'critical':
        return Icons.warning_rounded;

      case 'overspent':
        return Icons.error_outline_rounded;

      case 'warning':
        return Icons.info_outline_rounded;

      case 'healthy':
        return Icons.check_circle_rounded;

      default:
        return Icons.auto_awesome_rounded;
    }
  }

  String _statusTitle() {
    switch (budgetStatus.trim().toLowerCase()) {
      case 'healthy':
        return 'Your spending is on track';

      case 'warning':
        return 'Your budget needs attention';

      case 'overspent':
        return 'Your spending is over budget';

      case 'critical':
        return 'Immediate budget attention needed';

      default:
        return 'Your financial picture at a glance';
    }
  }

  String _statusDescription() {
    switch (budgetStatus.trim().toLowerCase()) {
      case 'healthy':
        return 'Your spending is within a healthy range.';

      case 'warning':
        return 'You are approaching your current budget limit.';

      case 'overspent':
        return 'Spending has exceeded your current budget.';

      case 'critical':
        return 'Your current spending requires close attention.';

      default:
        return 'Review your spending to stay on track.';
    }
  }

  String _usageLabel(double usage) {
    if (usage >= 100) {
      return 'Over budget';
    }

    if (usage >= 80) {
      return 'Near limit';
    }

    if (usage >= 50) {
      return 'Moderate';
    }

    return 'Healthy';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final compact = ResponsiveHelper.useCompactLayout(context);

    final tablet = ResponsiveHelper.isTablet(context);

    final desktop = ResponsiveHelper.isDesktop(context);

    final dark = theme.brightness == Brightness.dark;

    final accent = _accentColor(context);

    final usage = budgetUsage.clamp(0.0, 100.0);

    final softAccent = accent.withOpacity(dark ? .14 : .075);

    final cardRadius = desktop
        ? 24.0
        : tablet
        ? 22.0
        : compact
        ? 18.0
        : 21.0;

    final cardPadding = desktop
        ? 20.0
        : tablet
        ? 18.0
        : compact
        ? 12.0
        : 16.0;

    final spacing = ResponsiveHelper.spacing(context);

    final recommendationText = recommendation.trim().isEmpty
        ? 'Keep tracking your spending and financial goals to receive more personalized recommendations.'
        : recommendation.trim();

    final categoryText = topCategory.trim().isEmpty
        ? 'No category data'
        : topCategory.trim();

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: ResponsiveHelper.contentMaxWidth(context),
        ),
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(cardRadius),
            border: Border.all(color: colorScheme.outline.withOpacity(.07)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(dark ? .10 : .045),
                blurRadius: compact ? 12 : 18,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          padding: EdgeInsets.all(cardPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ─────────────────────────────────────
              // Header
              // ─────────────────────────────────────
              Row(
                children: [
                  Container(
                    width: compact ? 40 : 44,
                    height: compact ? 40 : 44,
                    decoration: BoxDecoration(
                      color: softAccent,
                      borderRadius: BorderRadius.circular(compact ? 12 : 14),
                    ),
                    child: Icon(
                      _statusIcon(),
                      color: accent,
                      size: compact ? 21 : 23,
                    ),
                  ),

                  SizedBox(width: spacing),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Financial Insight',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontSize: compact ? 14 : 16,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -.15,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _statusTitle(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontSize: compact ? 9.5 : 11,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 8),

                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
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
                        color: accent,
                        fontSize: compact ? 8.5 : 9.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: .55,
                      ),
                    ),
                  ),
                ],
              ),

              SizedBox(height: compact ? 12 : 16),

              // ─────────────────────────────────────
              // Main recommendation
              // ─────────────────────────────────────
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(compact ? 12 : 14),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [softAccent, accent.withOpacity(dark ? .07 : .035)],
                  ),
                  borderRadius: BorderRadius.circular(compact ? 14 : 16),
                  border: Border.all(color: accent.withOpacity(.08)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: compact ? 28 : 32,
                      height: compact ? 28 : 32,
                      decoration: BoxDecoration(
                        color: accent.withOpacity(.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.auto_awesome_rounded,
                        color: accent,
                        size: compact ? 15 : 17,
                      ),
                    ),

                    SizedBox(width: compact ? 9 : 11),

                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Smart recommendation',
                            style: TextStyle(
                              color: accent,
                              fontSize: compact ? 10 : 11,
                              fontWeight: FontWeight.w800,
                            ),
                          ),

                          const SizedBox(height: 5),

                          Text(
                            recommendationText,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontSize: compact ? 12 : 13.5,
                              height: 1.45,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: compact ? 12 : 16),

              // ─────────────────────────────────────
              // Financial snapshot
              // ─────────────────────────────────────
              LayoutBuilder(
                builder: (context, constraints) {
                  final stacked = constraints.maxWidth < 430;

                  if (stacked) {
                    return Column(
                      children: [
                        _buildCategoryMetric(context, categoryText, compact),

                        const SizedBox(height: 10),

                        _buildBudgetMetric(context, usage, accent, compact),
                      ],
                    );
                  }

                  return Row(
                    children: [
                      Expanded(
                        child: _buildCategoryMetric(
                          context,
                          categoryText,
                          compact,
                        ),
                      ),

                      const SizedBox(width: 10),

                      Expanded(
                        child: _buildBudgetMetric(
                          context,
                          usage,
                          accent,
                          compact,
                        ),
                      ),
                    ],
                  );
                },
              ),

              if (categoryAdvice.trim().isNotEmpty) ...[
                SizedBox(height: compact ? 12 : 14),

                // ─────────────────────────────────
                // Spending tip
                // ─────────────────────────────────
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(compact ? 11 : 13),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest.withOpacity(
                      dark ? .40 : .52,
                    ),
                    borderRadius: BorderRadius.circular(compact ? 13 : 15),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: compact ? 28 : 32,
                        height: compact ? 28 : 32,
                        decoration: BoxDecoration(
                          color: colorScheme.primary.withOpacity(.09),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.tips_and_updates_rounded,
                          size: compact ? 14 : 16,
                          color: colorScheme.primary,
                        ),
                      ),

                      SizedBox(width: compact ? 8 : 10),

                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Spending tip',
                              style: TextStyle(
                                fontSize: compact ? 9.5 : 10.5,
                                fontWeight: FontWeight.w800,
                                color: colorScheme.primary,
                              ),
                            ),

                            const SizedBox(height: 4),

                            Text(
                              categoryAdvice.trim(),
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontSize: compact ? 11.5 : 12.5,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              SizedBox(height: compact ? 10 : 12),

              // ─────────────────────────────────────
              // Status description
              // ─────────────────────────────────────
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.insights_rounded,
                    size: compact ? 14 : 16,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 7),
                  Expanded(
                    child: Text(
                      _statusDescription(),
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontSize: compact ? 10 : 11,
                        color: colorScheme.onSurfaceVariant,
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryMetric(
    BuildContext context,
    String category,
    bool compact,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(compact ? 10 : 12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withOpacity(
          theme.brightness == Brightness.dark ? .38 : .55,
        ),
        borderRadius: BorderRadius.circular(compact ? 13 : 15),
      ),
      child: Row(
        children: [
          Container(
            width: compact ? 30 : 34,
            height: compact ? 30 : 34,
            decoration: BoxDecoration(
              color: colorScheme.primary.withOpacity(.09),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.pie_chart_rounded,
              size: compact ? 15 : 17,
              color: colorScheme.primary,
            ),
          ),

          SizedBox(width: compact ? 8 : 10),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Top category',
                  style: TextStyle(
                    fontSize: compact ? 9 : 10,
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  category,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: compact ? 11 : 12,
                    fontWeight: FontWeight.w800,
                    color: colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBudgetMetric(
    BuildContext context,
    double usage,
    Color accent,
    bool compact,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(compact ? 10 : 12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withOpacity(
          theme.brightness == Brightness.dark ? .38 : .55,
        ),
        borderRadius: BorderRadius.circular(compact ? 13 : 15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Budget usage',
                  style: TextStyle(
                    fontSize: compact ? 9 : 10,
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                '${usage.toStringAsFixed(0)}%',
                style: TextStyle(
                  fontSize: compact ? 12 : 13,
                  fontWeight: FontWeight.w900,
                  color: accent,
                ),
              ),
            ],
          ),

          const SizedBox(height: 7),

          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: TweenAnimationBuilder<double>(
              duration: const Duration(milliseconds: 800),
              curve: Curves.easeOutCubic,
              tween: Tween<double>(begin: 0, end: usage / 100),
              builder: (_, value, __) {
                return LinearProgressIndicator(
                  value: value.clamp(0.0, 1.0),
                  minHeight: compact ? 6 : 7,
                  backgroundColor: accent.withOpacity(.10),
                  valueColor: AlwaysStoppedAnimation<Color>(accent),
                );
              },
            ),
          ),

          const SizedBox(height: 5),

          Text(
            _usageLabel(usage),
            style: TextStyle(
              fontSize: compact ? 8.5 : 9.5,
              fontWeight: FontWeight.w700,
              color: accent,
            ),
          ),
        ],
      ),
    );
  }
}
