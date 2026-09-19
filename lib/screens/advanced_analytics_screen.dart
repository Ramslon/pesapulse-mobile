import 'package:flutter/material.dart';

import '../widgets/app/adaptive_app_bar.dart';
import '../widgets/app/app_scaffold.dart';
import '../utils/responsive_helper.dart';

class AdvancedAnalyticsScreen extends StatelessWidget {
  final Map<String, dynamic> analytics;

  const AdvancedAnalyticsScreen({super.key, required this.analytics});

  double _double(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  int _int(dynamic value) {
    if (value is int) {
      return value;
    }

    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  String _money(dynamic value) {
    return 'KES ${_double(value).toStringAsFixed(2)}';
  }

  String _moneyCompact(dynamic value) {
    return 'KES ${_double(value).toStringAsFixed(0)}';
  }

  @override
  Widget build(BuildContext context) {
    final compact = ResponsiveHelper.useCompactLayout(context);
    final tablet = ResponsiveHelper.isTablet(context);

    final horizontalPadding = ResponsiveHelper.horizontalPadding(context);

    final sectionSpacing = ResponsiveHelper.sectionSpacing(context);

    final period = _map(analytics['period']);

    final quality = _map(analytics['data_quality']);

    final summary = _map(analytics['summary']);

    final comparison = _map(analytics['comparison']);

    final trend = _map(analytics['trend']);

    final categories = _map(analytics['categories']);

    final consistency = _map(analytics['spending_consistency']);

    final highestDay = analytics['highest_spending_day'] is Map
        ? Map<String, dynamic>.from(analytics['highest_spending_day'] as Map)
        : null;

    final monthly = _listOfMaps(trend['monthly']);
    final breakdown = _listOfMaps(categories['breakdown']);
    final anomalies = _listOfMaps(analytics['anomalies']);

    final canCalculateTrend = quality['can_calculate_trend'] == true;

    final canCalculateConsistency =
        quality['can_calculate_consistency'] == true;

    final trendDirection =
        trend['direction']?.toString() ?? 'insufficient_data';

    return AppScaffold(
      appBar: const AdaptiveAppBar(title: 'Advanced Analytics'),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.fromLTRB(
          horizontalPadding,
          compact ? 10 : 18,
          horizontalPadding,
          compact ? 32 : 42,
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: ResponsiveHelper.contentMaxWidth(context),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHero(context, period: period),

                SizedBox(height: sectionSpacing),

                _buildFinancialSnapshot(context, summary: summary),

                SizedBox(height: sectionSpacing),

                _buildComparison(context, comparison: comparison),

                SizedBox(height: sectionSpacing),

                _buildMonthlyTrend(
                  context,
                  monthly: monthly,
                  trendDirection: trendDirection,
                  canCalculate: canCalculateTrend,
                ),

                if (breakdown.isNotEmpty) ...[
                  SizedBox(height: sectionSpacing),
                  _buildCategoryBreakdown(context, breakdown: breakdown),
                ],

                SizedBox(height: sectionSpacing),

                if (tablet || !compact)
                  _buildInsightPair(
                    context,
                    consistency: consistency,
                    canCalculateConsistency: canCalculateConsistency,
                    highestDay: highestDay,
                  )
                else ...[
                  _buildConsistency(
                    context,
                    consistency: consistency,
                    canCalculate: canCalculateConsistency,
                  ),
                  if (highestDay != null) ...[
                    const SizedBox(height: 12),
                    _buildHighestDay(context, highestDay: highestDay),
                  ],
                ],

                if (anomalies.isNotEmpty) ...[
                  SizedBox(height: sectionSpacing),
                  _buildAnomalies(context, anomalies: anomalies),
                ],

                SizedBox(height: sectionSpacing),

                _buildDataQuality(context, quality: quality),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Map<String, dynamic> _map(dynamic value) {
    if (value is Map<String, dynamic>) {
      return value;
    }

    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }

    return {};
  }

  List<Map<String, dynamic>> _listOfMaps(dynamic value) {
    if (value is! List) {
      return [];
    }

    return value
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  Widget _buildHero(
    BuildContext context, {
    required Map<String, dynamic> period,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final months = _int(period['months']);
    final start = period['start']?.toString() ?? '';
    final end = period['end']?.toString() ?? '';

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(ResponsiveHelper.cardPadding(context) + 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colorScheme.primaryContainer.withOpacity(.72),
            colorScheme.surface,
          ],
        ),
        border: Border.all(color: colorScheme.primary.withOpacity(.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withOpacity(.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.auto_graph_rounded,
                  color: colorScheme.primary,
                  size: 25,
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Premium Analytics',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 9,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: colorScheme.primary.withOpacity(.10),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'PREMIUM',
                            style: TextStyle(
                              color: colorScheme.primary,
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                              letterSpacing: .6,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'Deeper spending analysis, comparisons and financial patterns.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurface.withOpacity(.70),
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
            decoration: BoxDecoration(
              color: colorScheme.surface.withOpacity(.70),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.date_range_rounded,
                  size: 18,
                  color: colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '$months-month analysis  •  $start → $end',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFinancialSnapshot(
    BuildContext context, {
    required Map<String, dynamic> summary,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final totalSpent = _double(summary['total_spent']);
    final totalBudget = _double(summary['total_budget']);
    final remaining = _double(summary['remaining']);
    final averageMonthly = _double(summary['average_monthly_spending']);
    final expenseCount = _int(summary['expense_count']);

    final budgetUsage = totalBudget > 0
        ? (totalSpent / totalBudget).clamp(0.0, 1.0)
        : 0.0;

    final remainingColor = remaining >= 0
        ? colorScheme.primary
        : colorScheme.error;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Financial Snapshot',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth >= 700 ? 4 : 2;

            final gap = 10.0;

            final width = columns == 4
                ? (constraints.maxWidth - (gap * 3)) / 4
                : (constraints.maxWidth - gap) / 2;

            final tiles = [
              _snapshotTile(
                context,
                icon: Icons.payments_outlined,
                label: 'Total Spent',
                value: _moneyCompact(totalSpent),
              ),
              _snapshotTile(
                context,
                icon: Icons.account_balance_wallet_outlined,
                label: 'Budget',
                value: _moneyCompact(totalBudget),
              ),
              _snapshotTile(
                context,
                icon: Icons.savings_outlined,
                label: 'Remaining',
                value: _moneyCompact(remaining),
                valueColor: remainingColor,
              ),
              _snapshotTile(
                context,
                icon: Icons.calendar_month_outlined,
                label: 'Avg / Month',
                value: _moneyCompact(averageMonthly),
              ),
            ];

            return Wrap(
              spacing: gap,
              runSpacing: gap,
              children: tiles
                  .map((tile) => SizedBox(width: width, child: tile))
                  .toList(),
            );
          },
        ),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 13),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest.withOpacity(.38),
            borderRadius: BorderRadius.circular(15),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Budget usage',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurface.withOpacity(.65),
                    ),
                  ),
                  Text(
                    '${(budgetUsage * 100).toStringAsFixed(1)}%',
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ],
              ),
              const SizedBox(height: 7),
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: LinearProgressIndicator(
                  value: budgetUsage,
                  minHeight: 7,
                  backgroundColor: colorScheme.surfaceContainerHighest,
                  color: _budgetUsageColor(context, budgetUsage),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '$expenseCount expenses recorded in this period',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurface.withOpacity(.60),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _snapshotTile(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: colorScheme.outline.withOpacity(.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 19, color: colorScheme.primary),
          const SizedBox(height: 10),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurface.withOpacity(.62),
            ),
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w900,
                color: valueColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComparison(
    BuildContext context, {
    required Map<String, dynamic> comparison,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final previous = _double(comparison['previous_period_spending']);

    final change = _double(comparison['change_amount']);

    final percentage = comparison['change_percentage'];

    final hasPercentage = percentage != null;

    final changeIsPositive = change > 0;
    final changeIsNegative = change < 0;

    final changeColor = changeIsPositive
        ? colorScheme.error
        : changeIsNegative
        ? colorScheme.primary
        : colorScheme.onSurfaceVariant;

    final changeIcon = changeIsPositive
        ? Icons.trending_up_rounded
        : changeIsNegative
        ? Icons.trending_down_rounded
        : Icons.remove_rounded;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(ResponsiveHelper.cardPadding(context)),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colorScheme.outline.withOpacity(.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(
            context,
            icon: Icons.compare_arrows_rounded,
            title: 'Period Comparison',
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              Expanded(
                child: _comparisonMetric(
                  context,
                  label: 'Previous Period',
                  value: _moneyCompact(previous),
                ),
              ),
              Container(
                width: 1,
                height: 52,
                color: colorScheme.outline.withOpacity(.10),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(left: 16),
                  child: _comparisonMetric(
                    context,
                    label: 'Current Change',
                    value: _moneyCompact(change.abs()),
                    valueColor: changeColor,
                    icon: changeIcon,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(11),
            decoration: BoxDecoration(
              color: changeColor.withOpacity(.07),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(changeIcon, size: 18, color: changeColor),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    hasPercentage
                        ? '${_double(percentage).toStringAsFixed(2)}% change from the previous period.'
                        : 'A percentage comparison is unavailable because the previous period had no spending.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurface.withOpacity(.72),
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _comparisonMetric(
    BuildContext context, {
    required String label,
    required String value,
    Color? valueColor,
    IconData? icon,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurface.withOpacity(.62),
          ),
        ),
        const SizedBox(height: 5),
        Row(
          children: [
            if (icon != null) ...[
              Icon(icon, size: 18, color: valueColor),
              const SizedBox(width: 5),
            ],
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  value,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: valueColor,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMonthlyTrend(
    BuildContext context, {
    required List<Map<String, dynamic>> monthly,
    required String trendDirection,
    required bool canCalculate,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final maxSpent = monthly.isEmpty
        ? 0.0
        : monthly
              .map((item) => _double(item['spent']))
              .reduce((a, b) => a > b ? a : b);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(ResponsiveHelper.cardPadding(context)),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colorScheme.outline.withOpacity(.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _sectionTitle(
                  context,
                  icon: Icons.show_chart_rounded,
                  title: 'Monthly Spending Trend',
                ),
              ),
              _trendChip(context, trendDirection, canCalculate),
            ],
          ),
          const SizedBox(height: 18),
          if (!canCalculate)
            _insufficientDataBanner(
              context,
              message:
                  'At least two months with spending are needed before a meaningful trend can be calculated.',
            ),
          const SizedBox(height: 8),
          if (monthly.isEmpty)
            _emptyInline(context, 'No monthly spending data is available.')
          else
            Column(
              children: monthly.map((item) {
                final amount = _double(item['spent']);

                final ratio = maxSpent > 0 ? amount / maxSpent : 0.0;

                final label = item['label']?.toString() ?? '';

                return Padding(
                  padding: const EdgeInsets.only(bottom: 13),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            label,
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            _moneyCompact(amount),
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: LinearProgressIndicator(
                          value: ratio,
                          minHeight: 8,
                          backgroundColor: colorScheme.surfaceContainerHighest,
                          color: colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  Widget _trendChip(BuildContext context, String trend, bool canCalculate) {
    final colorScheme = Theme.of(context).colorScheme;

    final color = !canCalculate
        ? colorScheme.onSurfaceVariant
        : trend == 'increasing'
        ? colorScheme.error
        : trend == 'decreasing'
        ? colorScheme.primary
        : Colors.orange;

    final icon = !canCalculate
        ? Icons.help_outline_rounded
        : trend == 'increasing'
        ? Icons.trending_up_rounded
        : trend == 'decreasing'
        ? Icons.trending_down_rounded
        : Icons.trending_flat_rounded;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(.09),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 4),
          Text(
            canCalculate ? _formatTrend(trend) : 'Insufficient Data',
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryBreakdown(
    BuildContext context, {
    required List<Map<String, dynamic>> breakdown,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final topCategory = breakdown.isNotEmpty
        ? breakdown.first['category']?.toString() ?? 'Other'
        : 'Other';

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(ResponsiveHelper.cardPadding(context)),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colorScheme.outline.withOpacity(.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(
            context,
            icon: Icons.pie_chart_outline_rounded,
            title: 'Category Breakdown',
          ),
          const SizedBox(height: 8),
          Text(
            '$topCategory is currently your largest spending category.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurface.withOpacity(.64),
            ),
          ),
          const SizedBox(height: 16),
          ...breakdown.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;

            final percentage = _double(item['percentage']);

            final amount = _double(item['amount']);

            return Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: colorScheme.primary.withOpacity(.08),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${index + 1}',
                          style: TextStyle(
                            color: colorScheme.primary,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const SizedBox(width: 9),
                      Expanded(
                        child: Text(
                          item['category']?.toString() ?? 'Other',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                      Text(
                        _moneyCompact(amount),
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: LinearProgressIndicator(
                            value: percentage.clamp(0.0, 100.0) / 100,
                            minHeight: 7,
                            backgroundColor:
                                colorScheme.surfaceContainerHighest,
                            color: _categoryColor(context, index),
                          ),
                        ),
                      ),
                      const SizedBox(width: 9),
                      SizedBox(
                        width: 48,
                        child: Text(
                          '${percentage.toStringAsFixed(1)}%',
                          textAlign: TextAlign.right,
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildInsightPair(
    BuildContext context, {
    required Map<String, dynamic> consistency,
    required bool canCalculateConsistency,
    required Map<String, dynamic>? highestDay,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _buildConsistency(
            context,
            consistency: consistency,
            canCalculate: canCalculateConsistency,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: highestDay != null
              ? _buildHighestDay(context, highestDay: highestDay)
              : _emptyInline(context, 'No highest spending day available.'),
        ),
      ],
    );
  }

  Widget _buildConsistency(
    BuildContext context, {
    required Map<String, dynamic> consistency,
    required bool canCalculate,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final average = _double(consistency['average_daily_spending']);

    final deviation = _double(consistency['standard_deviation']);

    final label = consistency['label']?.toString() ?? 'Insufficient Data';

    return Container(
      padding: EdgeInsets.all(ResponsiveHelper.cardPadding(context)),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colorScheme.outline.withOpacity(.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(
            context,
            icon: Icons.tune_rounded,
            title: 'Spending Consistency',
          ),
          const SizedBox(height: 14),
          Text(
            label,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          _miniMetric(context, 'Average / Day', _money(average)),
          _miniMetric(context, 'Standard Deviation', _money(deviation)),
          if (!canCalculate) ...[
            const SizedBox(height: 8),
            Text(
              'More spending days are needed for a meaningful consistency assessment.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurface.withOpacity(.62),
                height: 1.35,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildHighestDay(
    BuildContext context, {
    required Map<String, dynamic> highestDay,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: EdgeInsets.all(ResponsiveHelper.cardPadding(context)),
      decoration: BoxDecoration(
        color: colorScheme.primary.withOpacity(.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colorScheme.primary.withOpacity(.10)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(
            context,
            icon: Icons.local_fire_department_outlined,
            title: 'Highest Spending Day',
          ),
          const SizedBox(height: 14),
          Text(
            _money(highestDay['amount']),
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w900,
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            highestDay['date']?.toString() ?? 'Unknown date',
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurface.withOpacity(.64),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnomalies(
    BuildContext context, {
    required List<Map<String, dynamic>> anomalies,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(ResponsiveHelper.cardPadding(context)),
      decoration: BoxDecoration(
        color: colorScheme.error.withOpacity(.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colorScheme.error.withOpacity(.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(
            context,
            icon: Icons.warning_amber_rounded,
            title: 'Unusual Spending',
            iconColor: colorScheme.error,
          ),
          const SizedBox(height: 12),
          Text(
            'These spending days were unusually high compared with your typical activity.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurface.withOpacity(.68),
              height: 1.35,
            ),
          ),
          const SizedBox(height: 14),
          ...anomalies.map((item) {
            final severity = item['severity']?.toString() ?? 'moderate';

            final severityColor = severity == 'high'
                ? colorScheme.error
                : Colors.orange;

            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: severityColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      item['date']?.toString() ?? 'Unknown date',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                  Text(
                    _money(item['amount']),
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildDataQuality(
    BuildContext context, {
    required Map<String, dynamic> quality,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final months = _int(quality['months_available']);

    final spendingMonths = _int(quality['months_with_spending']);

    final spendingDays = _int(quality['spending_days']);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withOpacity(.30),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.fact_check_outlined, size: 19, color: colorScheme.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Analysis Coverage',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$months months analyzed • '
                  '$spendingMonths months with spending • '
                  '$spendingDays spending days',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurface.withOpacity(.62),
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(
    BuildContext context, {
    required IconData icon,
    required String title,
    Color? iconColor,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      children: [
        Icon(icon, size: 20, color: iconColor ?? colorScheme.primary),
        const SizedBox(width: 9),
        Expanded(
          child: Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }

  Widget _miniMetric(BuildContext context, String label, String value) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurface.withOpacity(.62),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _insufficientDataBanner(
    BuildContext context, {
    required String message,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withOpacity(.45),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline_rounded,
            size: 18,
            color: colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: colorScheme.onSurface.withOpacity(.68),
                fontSize: 12,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyInline(BuildContext context, String message) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withOpacity(.35),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        message,
        style: TextStyle(color: colorScheme.onSurface.withOpacity(.65)),
      ),
    );
  }

  Color _budgetUsageColor(BuildContext context, double usage) {
    if (usage >= 1) {
      return Theme.of(context).colorScheme.error;
    }

    if (usage >= .8) {
      return Colors.orange;
    }

    return Theme.of(context).colorScheme.primary;
  }

  Color _categoryColor(BuildContext context, int index) {
    final colorScheme = Theme.of(context).colorScheme;

    final colors = [
      colorScheme.primary,
      colorScheme.secondary,
      Colors.orange,
      Colors.green,
      Colors.deepPurple,
      Colors.teal,
    ];

    return colors[index % colors.length];
  }

  String _formatTrend(String value) {
    switch (value) {
      case 'increasing':
        return 'Increasing';
      case 'decreasing':
        return 'Decreasing';
      case 'stable':
        return 'Stable';
      default:
        return 'Insufficient Data';
    }
  }
}
