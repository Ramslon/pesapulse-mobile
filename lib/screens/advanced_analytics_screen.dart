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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final compact = ResponsiveHelper.useCompactLayout(context);

    final horizontalPadding = ResponsiveHelper.horizontalPadding(context);

    final spacing = ResponsiveHelper.spacing(context);

    final sectionSpacing = ResponsiveHelper.sectionSpacing(context);

    final period = analytics['period'] as Map<String, dynamic>? ?? {};

    final quality = analytics['data_quality'] as Map<String, dynamic>? ?? {};

    final summary = analytics['summary'] as Map<String, dynamic>? ?? {};

    final comparison = analytics['comparison'] as Map<String, dynamic>? ?? {};

    final trend = analytics['trend'] as Map<String, dynamic>? ?? {};

    final categories = analytics['categories'] as Map<String, dynamic>? ?? {};

    final consistency =
        analytics['spending_consistency'] as Map<String, dynamic>? ?? {};

    final highestDay =
        analytics['highest_spending_day'] as Map<String, dynamic>?;

    final anomalies = analytics['anomalies'] is List
        ? analytics['anomalies'] as List
        : <dynamic>[];

    final monthly = trend['monthly'] is List
        ? trend['monthly'] as List
        : <dynamic>[];

    final breakdown = categories['breakdown'] is List
        ? categories['breakdown'] as List
        : <dynamic>[];

    final canCalculateTrend = quality['can_calculate_trend'] == true;

    final canCalculateConsistency =
        quality['can_calculate_consistency'] == true;

    final trendDirection =
        trend['direction']?.toString() ?? 'insufficient_data';

    return AppScaffold(
      appBar: const AdaptiveAppBar(title: 'Advanced Analytics'),
      body: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: EdgeInsets.fromLTRB(
          horizontalPadding,
          compact ? 12 : 20,
          horizontalPadding,
          compact ? 32 : 40,
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: ResponsiveHelper.contentMaxWidth(context),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildPremiumHeader(context, period: period),

                SizedBox(height: sectionSpacing),

                _buildSummaryCard(context, summary: summary),

                SizedBox(height: sectionSpacing),

                _buildComparisonCard(context, comparison: comparison),

                SizedBox(height: sectionSpacing),

                _buildTrendCard(
                  context,
                  monthly: monthly,
                  trendDirection: trendDirection,
                  canCalculate: canCalculateTrend,
                ),

                SizedBox(height: sectionSpacing),

                _buildConsistencyCard(
                  context,
                  consistency: consistency,
                  canCalculate: canCalculateConsistency,
                ),

                if (highestDay != null) ...[
                  SizedBox(height: sectionSpacing),
                  _buildHighestDayCard(context, highestDay: highestDay),
                ],

                if (breakdown.isNotEmpty) ...[
                  SizedBox(height: sectionSpacing),
                  _buildCategoryCard(context, breakdown: breakdown),
                ],

                SizedBox(height: sectionSpacing),

                _buildDataQualityCard(context, quality: quality),

                if (anomalies.isNotEmpty) ...[
                  SizedBox(height: sectionSpacing),
                  _buildAnomaliesCard(context, anomalies: anomalies),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPremiumHeader(
    BuildContext context, {
    required Map<String, dynamic> period,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final months = _int(period['months']);

    return Card(
      elevation: 0,
      color: colorScheme.primaryContainer.withOpacity(.45),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: EdgeInsets.all(ResponsiveHelper.cardPadding(context)),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colorScheme.primary.withOpacity(.12),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.auto_graph_rounded, color: colorScheme.primary),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Premium Analytics',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Advanced financial analysis for the last $months months.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurface.withOpacity(.7),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(
    BuildContext context, {
    required Map<String, dynamic> summary,
  }) {
    return _sectionCard(
      context,
      title: 'Period Summary',
      icon: Icons.account_balance_wallet_outlined,
      child: Column(
        children: [
          _metricRow(context, 'Total Spent', _money(summary['total_spent'])),
          _metricRow(context, 'Total Budget', _money(summary['total_budget'])),
          _metricRow(context, 'Remaining', _money(summary['remaining'])),
          _metricRow(
            context,
            'Average Monthly Spending',
            _money(summary['average_monthly_spending']),
          ),
          _metricRow(
            context,
            'Expenses Recorded',
            '${_int(summary['expense_count'])}',
          ),
        ],
      ),
    );
  }

  Widget _buildComparisonCard(
    BuildContext context, {
    required Map<String, dynamic> comparison,
  }) {
    final change = comparison['change_percentage'];

    final hasPercentage = change != null;

    return _sectionCard(
      context,
      title: 'Previous Period Comparison',
      icon: Icons.compare_arrows_rounded,
      child: Column(
        children: [
          _metricRow(
            context,
            'Previous Period',
            _money(comparison['previous_period_spending']),
          ),
          _metricRow(context, 'Change', _money(comparison['change_amount'])),
          _metricRow(
            context,
            'Percentage Change',
            hasPercentage
                ? '${_double(change).toStringAsFixed(2)}%'
                : 'Not available',
          ),
        ],
      ),
    );
  }

  Widget _buildTrendCard(
    BuildContext context, {
    required List monthly,
    required String trendDirection,
    required bool canCalculate,
  }) {
    return _sectionCard(
      context,
      title: 'Spending Trend',
      icon: Icons.show_chart_rounded,
      child: Column(
        children: [
          if (!canCalculate)
            _infoMessage(
              context,
              'There is not enough monthly spending data to determine a trend yet.',
            )
          else
            _metricRow(context, 'Trend', _formatTrend(trendDirection)),
          const SizedBox(height: 12),
          ...monthly.map((item) {
            final row = item as Map<String, dynamic>;

            return _metricRow(
              context,
              row['label']?.toString() ?? '',
              _money(row['spent']),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildConsistencyCard(
    BuildContext context, {
    required Map<String, dynamic> consistency,
    required bool canCalculate,
  }) {
    return _sectionCard(
      context,
      title: 'Spending Consistency',
      icon: Icons.tune_rounded,
      child: Column(
        children: [
          _metricRow(
            context,
            'Average Daily Spending',
            _money(consistency['average_daily_spending']),
          ),
          _metricRow(
            context,
            'Standard Deviation',
            _money(consistency['standard_deviation']),
          ),
          _metricRow(
            context,
            'Assessment',
            consistency['label']?.toString() ?? 'Insufficient Data',
          ),
          if (!canCalculate) ...[
            const SizedBox(height: 10),
            _infoMessage(
              context,
              'More spending days are needed before consistency can be calculated.',
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildHighestDayCard(
    BuildContext context, {
    required Map<String, dynamic> highestDay,
  }) {
    return _sectionCard(
      context,
      title: 'Highest Spending Day',
      icon: Icons.calendar_today_rounded,
      child: Column(
        children: [
          _metricRow(
            context,
            'Date',
            highestDay['date']?.toString() ?? 'Unknown',
          ),
          _metricRow(context, 'Amount', _money(highestDay['amount'])),
        ],
      ),
    );
  }

  Widget _buildCategoryCard(BuildContext context, {required List breakdown}) {
    return _sectionCard(
      context,
      title: 'Category Breakdown',
      icon: Icons.pie_chart_outline_rounded,
      child: Column(
        children: breakdown.map((item) {
          final row = item as Map<String, dynamic>;

          return _metricRow(
            context,
            row['category']?.toString() ?? 'Other',
            '${_money(row['amount'])} '
            '(${_double(row['percentage']).toStringAsFixed(1)}%)',
          );
        }).toList(),
      ),
    );
  }

  Widget _buildDataQualityCard(
    BuildContext context, {
    required Map<String, dynamic> quality,
  }) {
    final months = _int(quality['months_available']);

    final spendingMonths = _int(quality['months_with_spending']);

    final spendingDays = _int(quality['spending_days']);

    return _sectionCard(
      context,
      title: 'Data Quality',
      icon: Icons.fact_check_outlined,
      child: Column(
        children: [
          _metricRow(context, 'Months Analyzed', '$months'),
          _metricRow(context, 'Months With Spending', '$spendingMonths'),
          _metricRow(context, 'Spending Days', '$spendingDays'),
        ],
      ),
    );
  }

  Widget _buildAnomaliesCard(BuildContext context, {required List anomalies}) {
    return _sectionCard(
      context,
      title: 'Unusual Spending',
      icon: Icons.warning_amber_rounded,
      child: Column(
        children: anomalies.map((item) {
          final row = item as Map<String, dynamic>;

          return _metricRow(
            context,
            row['date']?.toString() ?? '',
            '${_money(row['amount'])} '
            '• ${row['severity'] ?? 'moderate'}',
          );
        }).toList(),
      ),
    );
  }

  Widget _sectionCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: EdgeInsets.all(ResponsiveHelper.cardPadding(context)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 21, color: colorScheme.primary),
                const SizedBox(width: 9),
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            child,
          ],
        ),
      ),
    );
  }

  Widget _metricRow(BuildContext context, String label, String value) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurface.withOpacity(.7),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoMessage(BuildContext context, String message) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withOpacity(.55),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        message,
        style: TextStyle(
          color: colorScheme.onSurface.withOpacity(.7),
          height: 1.35,
        ),
      ),
    );
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
