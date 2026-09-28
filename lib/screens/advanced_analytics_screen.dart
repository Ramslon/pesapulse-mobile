import 'package:flutter/material.dart';

import '../widgets/app/adaptive_app_bar.dart';
import '../widgets/app/app_scaffold.dart';
import '../utils/responsive_helper.dart';

const Color _premiumPurple = Color(0xFF6D3FD9);
const Color _premiumPurpleDark = Color(0xFF34205F);

const Color _analyticsTeal = Color(0xFF14B8A6);
const Color _analyticsTealDark = Color(0xFF0F766E);

class AdvancedAnalyticsScreen extends StatelessWidget {
  final Map<String, dynamic> analytics;

  const AdvancedAnalyticsScreen({super.key, required this.analytics});

  // ============================================================
  // DATA HELPERS
  // ============================================================

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

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final compact = ResponsiveHelper.useCompactLayout(context);
    final landscape = ResponsiveHelper.isLandscape(context);
    final desktop = ResponsiveHelper.isDesktop(context);

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
      showOfflineBanner: true,
      showSyncIcon: true,
      appBar: const AdaptiveAppBar(title: 'Advanced Analytics'),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.fromLTRB(
          horizontalPadding,
          compact
              ? 8
              : landscape && !desktop
              ? 12
              : 18,
          horizontalPadding,
          compact ? 30 : 42,
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

                _buildBehavioralInsights(
                  context,
                  consistency: consistency,
                  canCalculateConsistency: canCalculateConsistency,
                  highestDay: highestDay,
                ),

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

  // ============================================================
  // HERO
  // ============================================================

  Widget _buildHero(
    BuildContext context, {
    required Map<String, dynamic> period,
  }) {
    final theme = Theme.of(context);

    final compact = ResponsiveHelper.useCompactLayout(context);
    final landscape = ResponsiveHelper.isLandscape(context);
    final desktop = ResponsiveHelper.isDesktop(context);

    final months = _int(period['months']);
    final start = period['start']?.toString() ?? '';
    final end = period['end']?.toString() ?? '';

    final titleSize = compact
        ? 23.0
        : landscape
        ? 26.0
        : desktop
        ? 30.0
        : 29.0;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(
        compact
            ? 16
            : landscape
            ? 20
            : 25,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(compact ? 22 : 26),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_premiumPurple, _premiumPurpleDark],
        ),
        border: Border.all(color: Colors.white.withOpacity(0.11)),
        boxShadow: [
          BoxShadow(
            color: _premiumPurple.withOpacity(0.19),
            blurRadius: 25,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: compact ? 48 : 54,
                height: compact ? 48 : 54,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.10),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white.withOpacity(0.08)),
                ),
                child: Icon(
                  Icons.auto_graph_rounded,
                  color: Colors.white,
                  size: compact ? 23 : 27,
                ),
              ),

              SizedBox(width: compact ? 11 : 14),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeroTitle(context, titleSize: titleSize),

                    const SizedBox(height: 7),

                    Text(
                      'Deeper spending analysis, comparisons '
                      'and financial patterns.',
                      maxLines: compact ? 3 : 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withOpacity(0.72),
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          SizedBox(height: compact ? 16 : 19),

          _buildAnalysisWindow(context, months: months, start: start, end: end),
        ],
      ),
    );
  }

  Widget _buildHeroTitle(BuildContext context, {required double titleSize}) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final narrow = constraints.maxWidth < 280;

        if (narrow) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Premium Analytics',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: titleSize,
                  fontWeight: FontWeight.w900,
                  height: 1.1,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 7),
              _premiumBadge(),
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                'Premium Analytics',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: titleSize,
                  fontWeight: FontWeight.w900,
                  height: 1.1,
                  letterSpacing: -0.3,
                ),
              ),
            ),
            const SizedBox(width: 8),
            _premiumBadge(),
          ],
        );
      },
    );
  }

  Widget _premiumBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.10),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: const Text(
        'PREMIUM',
        style: TextStyle(
          color: Colors.white,
          fontSize: 9,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.65,
        ),
      ),
    );
  }

  Widget _buildAnalysisWindow(
    BuildContext context, {
    required int months,
    required String start,
    required String end,
  }) {
    final compact = ResponsiveHelper.useCompactLayout(context);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 11 : 13,
        vertical: compact ? 10 : 11,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.075),
        borderRadius: BorderRadius.circular(compact ? 13 : 15),
        border: Border.all(color: Colors.white.withOpacity(0.07)),
      ),
      child: Row(
        children: [
          Container(
            width: compact ? 30 : 33,
            height: compact ? 30 : 33,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.09),
              borderRadius: BorderRadius.circular(9),
            ),
            child: const Icon(
              Icons.date_range_rounded,
              size: 17,
              color: Colors.white,
            ),
          ),

          SizedBox(width: compact ? 8 : 10),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ANALYSIS WINDOW',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.56),
                    fontSize: compact ? 8.5 : 9,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '$months-month analysis',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          Flexible(
            child: Text(
              '$start → $end',
              textAlign: TextAlign.right,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white.withOpacity(0.78),
                fontSize: compact ? 10 : 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // FINANCIAL SNAPSHOT
  // ============================================================

  Widget _buildFinancialSnapshot(
    BuildContext context, {
    required Map<String, dynamic> summary,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final compact = ResponsiveHelper.useCompactLayout(context);

    final totalSpent = _double(summary['total_spent']);
    final totalBudget = _double(summary['total_budget']);
    final remaining = _double(summary['remaining']);
    final averageMonthly = _double(summary['average_monthly_spending']);
    final expenseCount = _int(summary['expense_count']);

    final budgetUsage = totalBudget > 0
        ? (totalSpent / totalBudget).clamp(0.0, 1.0)
        : 0.0;

    final remainingColor = remaining >= 0 ? _analyticsTeal : Colors.red;

    return _sectionCard(
      context,
      eyebrow: 'FINANCIAL OVERVIEW',
      title: 'Financial Snapshot',
      subtitle: 'Your spending position across the analyzed period.',
      icon: Icons.dashboard_outlined,
      child: Column(
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final columns = _snapshotColumns(context, constraints.maxWidth);

              final gap = ResponsiveHelper.spacing(context);

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

              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: tiles.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: columns,
                  crossAxisSpacing: gap,
                  mainAxisSpacing: gap,
                  mainAxisExtent: _snapshotCardHeight(context),
                ),
                itemBuilder: (context, index) {
                  return tiles[index];
                },
              );
            },
          ),

          SizedBox(height: compact ? 11 : 13),

          Container(
            width: double.infinity,
            padding: EdgeInsets.all(compact ? 11 : 13),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withOpacity(0.34),
              borderRadius: BorderRadius.circular(compact ? 14 : 16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Budget usage',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurface.withOpacity(0.62),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Text(
                      '${(budgetUsage * 100).toStringAsFixed(1)}%',
                      style: TextStyle(
                        fontSize: compact ? 11 : 12,
                        fontWeight: FontWeight.w900,
                        color: _budgetUsageColor(budgetUsage),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 7),

                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: LinearProgressIndicator(
                    value: budgetUsage,
                    minHeight: compact ? 7 : 8,
                    backgroundColor: colorScheme.surfaceContainerHighest,
                    color: _budgetUsageColor(budgetUsage),
                  ),
                ),

                const SizedBox(height: 8),

                Row(
                  children: [
                    Icon(
                      Icons.receipt_long_outlined,
                      size: compact ? 14 : 15,
                      color: colorScheme.onSurface.withOpacity(0.42),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        '$expenseCount expenses recorded in this period',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurface.withOpacity(0.55),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  int _snapshotColumns(BuildContext context, double width) {
    if (ResponsiveHelper.isDesktop(context)) {
      return 4;
    }

    if (ResponsiveHelper.isTabletLandscape(context)) {
      return 4;
    }

    if (ResponsiveHelper.isTabletPortrait(context)) {
      return 2;
    }

    if (ResponsiveHelper.isMobileLandscape(context)) {
      return width >= 700 ? 4 : 2;
    }

    return 2;
  }

  double _snapshotCardHeight(BuildContext context) {
    if (ResponsiveHelper.isMobilePortrait(context)) {
      return 108;
    }

    if (ResponsiveHelper.isMobileLandscape(context)) {
      return 100;
    }

    if (ResponsiveHelper.isTabletPortrait(context)) {
      return 112;
    }

    if (ResponsiveHelper.isTabletLandscape(context)) {
      return 108;
    }

    return 116;
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

    final compact = ResponsiveHelper.useCompactLayout(context);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(compact ? 11 : 13),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(compact ? 15 : 17),
        border: Border.all(color: colorScheme.outline.withOpacity(0.07)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: compact ? 31 : 34,
            height: compact ? 31 : 34,
            decoration: BoxDecoration(
              color: _analyticsTeal.withOpacity(0.09),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, size: compact ? 16 : 18, color: _analyticsTeal),
          ),

          SizedBox(width: compact ? 9 : 10),

          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontSize: compact ? 9.5 : 10.5,
                    color: colorScheme.onSurface.withOpacity(0.56),
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 4),

                FittedBox(
                  alignment: Alignment.centerLeft,
                  fit: BoxFit.scaleDown,
                  child: Text(
                    value,
                    maxLines: 1,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: valueColor ?? colorScheme.onSurface,
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

  // ============================================================
  // COMPARISON
  // ============================================================

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

    final changeColor = change > 0
        ? Colors.red
        : change < 0
        ? Colors.green
        : _analyticsTeal;

    final changeIcon = change > 0
        ? Icons.trending_up_rounded
        : change < 0
        ? Icons.trending_down_rounded
        : Icons.trending_flat_rounded;

    final compact = ResponsiveHelper.useCompactLayout(context);

    return _sectionCard(
      context,
      eyebrow: 'PERIOD COMPARISON',
      title: 'Current vs Previous',
      subtitle: 'See how spending has changed from the previous period.',
      icon: Icons.compare_arrows_rounded,
      child: Column(
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final stacked = constraints.maxWidth < 520;

              if (stacked) {
                return Column(
                  children: [
                    _comparisonMetricCard(
                      context,
                      label: 'Previous Period',
                      value: _moneyCompact(previous),
                      icon: Icons.history_rounded,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(height: 9),
                    _comparisonMetricCard(
                      context,
                      label: 'Current Change',
                      value: _moneyCompact(change.abs()),
                      icon: changeIcon,
                      color: changeColor,
                    ),
                  ],
                );
              }

              return Row(
                children: [
                  Expanded(
                    child: _comparisonMetricCard(
                      context,
                      label: 'Previous Period',
                      value: _moneyCompact(previous),
                      icon: Icons.history_rounded,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _comparisonMetricCard(
                      context,
                      label: 'Current Change',
                      value: _moneyCompact(change.abs()),
                      icon: changeIcon,
                      color: changeColor,
                    ),
                  ),
                ],
              );
            },
          ),

          const SizedBox(height: 10),

          Container(
            width: double.infinity,
            padding: EdgeInsets.all(compact ? 10 : 12),
            decoration: BoxDecoration(
              color: changeColor.withOpacity(0.06),
              borderRadius: BorderRadius.circular(compact ? 13 : 14),
              border: Border.all(color: changeColor.withOpacity(0.08)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(changeIcon, size: compact ? 17 : 18, color: changeColor),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    hasPercentage
                        ? '${_double(percentage).toStringAsFixed(2)}% change from the previous period.'
                        : 'A percentage comparison is unavailable because the previous period had no spending.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurface.withOpacity(0.68),
                      height: 1.4,
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

  Widget _comparisonMetricCard(
    BuildContext context, {
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    final theme = Theme.of(context);
    final compact = ResponsiveHelper.useCompactLayout(context);
    final colorScheme = theme.colorScheme;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(compact ? 11 : 13),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withOpacity(0.32),
        borderRadius: BorderRadius.circular(compact ? 14 : 16),
      ),
      child: Row(
        children: [
          Container(
            width: compact ? 33 : 36,
            height: compact ? 33 : 36,
            decoration: BoxDecoration(
              color: color.withOpacity(0.09),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: compact ? 16 : 18, color: color),
          ),

          SizedBox(width: compact ? 8 : 10),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurface.withOpacity(0.55),
                  ),
                ),
                const SizedBox(height: 3),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    value,
                    maxLines: 1,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: color,
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

  // ============================================================
  // MONTHLY TREND
  // ============================================================

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

    return _sectionCard(
      context,
      eyebrow: 'TREND ANALYSIS',
      title: 'Monthly Spending Trend',
      subtitle: 'Track how spending has moved across the analyzed months.',
      icon: Icons.show_chart_rounded,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  canCalculate
                      ? 'Observed spending progression'
                      : 'Trend requires more data',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurface.withOpacity(0.56),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _trendChip(context, trendDirection, canCalculate),
            ],
          ),

          const SizedBox(height: 14),

          if (!canCalculate)
            _insufficientDataBanner(
              context,
              message:
                  'At least two months with spending are needed before a meaningful trend can be calculated.',
            ),

          if (!canCalculate) const SizedBox(height: 9),

          if (monthly.isEmpty)
            _emptyInline(context, 'No monthly spending data is available.')
          else
            Column(
              children: monthly.asMap().entries.map((entry) {
                final item = entry.value;

                final amount = _double(item['spent']);

                final ratio = maxSpent > 0
                    ? (amount / maxSpent).clamp(0.0, 1.0)
                    : 0.0;

                final label = item['label']?.toString() ?? '';

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _monthlyTrendRow(
                    context,
                    label: label,
                    amount: amount,
                    ratio: ratio,
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  Widget _monthlyTrendRow(
    BuildContext context, {
    required String label,
    required double amount,
    required double ratio,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final compact = ResponsiveHelper.useCompactLayout(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: compact ? 27 : 30,
              height: compact ? 27 : 30,
              decoration: BoxDecoration(
                color: _analyticsTeal.withOpacity(0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.calendar_month_outlined,
                size: compact ? 14 : 15,
                color: _analyticsTeal,
              ),
            ),

            const SizedBox(width: 8),

            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),

            const SizedBox(width: 8),

            Flexible(
              child: FittedBox(
                alignment: Alignment.centerRight,
                fit: BoxFit.scaleDown,
                child: Text(
                  _moneyCompact(amount),
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 6),

        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: LinearProgressIndicator(
            value: ratio,
            minHeight: compact ? 7 : 8,
            backgroundColor: colorScheme.surfaceContainerHighest,
            color: _analyticsTeal,
          ),
        ),
      ],
    );
  }

  Widget _trendChip(BuildContext context, String trend, bool canCalculate) {
    final colorScheme = Theme.of(context).colorScheme;

    late Color color;
    late IconData icon;
    late String label;

    if (!canCalculate) {
      color = colorScheme.onSurfaceVariant;
      icon = Icons.help_outline_rounded;
      label = 'Insufficient Data';
    } else {
      switch (trend) {
        case 'increasing':
          color = Colors.red;
          icon = Icons.trending_up_rounded;
          label = 'Increasing';
          break;

        case 'decreasing':
          color = Colors.green;
          icon = Icons.trending_down_rounded;
          label = 'Decreasing';
          break;

        case 'stable':
          color = _analyticsTeal;
          icon = Icons.trending_flat_rounded;
          label = 'Stable';
          break;

        default:
          color = colorScheme.onSurfaceVariant;
          icon = Icons.help_outline_rounded;
          label = 'Insufficient Data';
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.09),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.08)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 9.5,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // CATEGORY BREAKDOWN
  // ============================================================

  Widget _buildCategoryBreakdown(
    BuildContext context, {
    required List<Map<String, dynamic>> breakdown,
  }) {
    final theme = Theme.of(context);

    final compact = ResponsiveHelper.useCompactLayout(context);

    final topCategory = breakdown.isNotEmpty
        ? breakdown.first['category']?.toString() ?? 'Other'
        : 'Other';

    return _sectionCard(
      context,
      eyebrow: 'CATEGORY ANALYSIS',
      title: 'Category Breakdown',
      subtitle: '$topCategory is currently your largest spending category.',
      icon: Icons.pie_chart_outline_rounded,
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(compact ? 10 : 12),
            decoration: BoxDecoration(
              color: _analyticsTeal.withOpacity(0.06),
              borderRadius: BorderRadius.circular(compact ? 13 : 15),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.trending_up_rounded,
                  size: compact ? 17 : 18,
                  color: _analyticsTeal,
                ),
                const SizedBox(width: 7),
                Expanded(
                  child: Text(
                    'Highest category: $topCategory',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: compact ? 14 : 17),

          ...breakdown.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;

            final percentage = _double(item['percentage']);

            final amount = _double(item['amount']);

            final category = item['category']?.toString() ?? 'Other';

            return Padding(
              padding: const EdgeInsets.only(bottom: 13),
              child: _categoryRow(
                context,
                index: index,
                category: category,
                amount: amount,
                percentage: percentage,
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _categoryRow(
    BuildContext context, {
    required int index,
    required String category,
    required double amount,
    required double percentage,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final compact = ResponsiveHelper.useCompactLayout(context);

    final color = _categoryColor(category);

    return LayoutBuilder(
      builder: (context, constraints) {
        final narrow = constraints.maxWidth < 390;

        if (narrow) {
          return _compactCategoryRow(
            context,
            index: index,
            category: category,
            amount: amount,
            percentage: percentage,
            color: color,
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _categoryNumber(index: index, color: color, compact: compact),

                SizedBox(width: compact ? 8 : 9),

                Expanded(
                  child: Text(
                    category,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),

                const SizedBox(width: 8),

                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerRight,
                    child: Text(
                      _moneyCompact(amount),
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 8),

                SizedBox(
                  width: compact ? 45 : 49,
                  child: Text(
                    '${percentage.toStringAsFixed(1)}%',
                    textAlign: TextAlign.right,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurface.withOpacity(0.60),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 6),

            _categoryProgress(
              context,
              percentage: percentage,
              color: color,
              compact: compact,
            ),
          ],
        );
      },
    );
  }

  Widget _compactCategoryRow(
    BuildContext context, {
    required int index,
    required String category,
    required double amount,
    required double percentage,
    required Color color,
  }) {
    final theme = Theme.of(context);
    final compact = ResponsiveHelper.useCompactLayout(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _categoryNumber(index: index, color: color, compact: compact),

            const SizedBox(width: 8),

            Expanded(
              child: Text(
                category,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),

            const SizedBox(width: 8),

            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerRight,
                child: Text(
                  _moneyCompact(amount),
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 5),

        Row(
          children: [
            const SizedBox(width: 39),
            Expanded(
              child: _categoryProgress(
                context,
                percentage: percentage,
                color: color,
                compact: compact,
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 45,
              child: Text(
                '${percentage.toStringAsFixed(1)}%',
                textAlign: TextAlign.right,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: color.withOpacity(0.80),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _categoryNumber({
    required int index,
    required Color color,
    required bool compact,
  }) {
    return Container(
      width: compact ? 29 : 31,
      height: compact ? 29 : 31,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color.withOpacity(0.09),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '${index + 1}',
        style: TextStyle(
          color: color,
          fontSize: compact ? 10 : 11,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  Widget _categoryProgress(
    BuildContext context, {
    required double percentage,
    required Color color,
    required bool compact,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: LinearProgressIndicator(
        value: (percentage / 100).clamp(0.0, 1.0),
        minHeight: compact ? 6 : 7,
        backgroundColor: colorScheme.surfaceContainerHighest,
        color: color,
      ),
    );
  }

  // ============================================================
  // BEHAVIORAL INSIGHTS
  // ============================================================

  Widget _buildBehavioralInsights(
    BuildContext context, {
    required Map<String, dynamic> consistency,
    required bool canCalculateConsistency,
    required Map<String, dynamic>? highestDay,
  }) {
    final consistencyCard = _buildConsistency(
      context,
      consistency: consistency,
      canCalculate: canCalculateConsistency,
    );

    final highestDayCard = highestDay != null
        ? _buildHighestDay(context, highestDay: highestDay)
        : _emptyInsightCard(
            context,
            icon: Icons.calendar_today_outlined,
            title: 'Highest Spending Day',
            message: 'No highest-spending day is available for this period.',
          );

    return LayoutBuilder(
      builder: (context, constraints) {
        final stacked = constraints.maxWidth < 680;

        if (stacked) {
          return Column(
            children: [
              consistencyCard,
              const SizedBox(height: 12),
              highestDayCard,
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: consistencyCard),
            const SizedBox(width: 12),
            Expanded(child: highestDayCard),
          ],
        );
      },
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

    return _sectionCard(
      context,
      eyebrow: 'BEHAVIOR PATTERN',
      title: 'Spending Consistency',
      subtitle: 'How predictable your daily spending has been.',
      icon: Icons.tune_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(11),
            decoration: BoxDecoration(
              color: _analyticsTeal.withOpacity(0.06),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Row(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: _analyticsTeal.withOpacity(0.10),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.insights_rounded,
                    size: 16,
                    color: _analyticsTeal,
                  ),
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: Text(
                    label,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: _analyticsTealDark,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          _miniMetric(context, 'Average / Day', _money(average)),

          _miniMetric(context, 'Standard Deviation', _money(deviation)),

          if (!canCalculate) ...[
            const SizedBox(height: 5),
            Text(
              'More spending days are needed for a meaningful consistency assessment.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurface.withOpacity(0.62),
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

    return _sectionCard(
      context,
      eyebrow: 'DAILY EXTREME',
      title: 'Highest Spending Day',
      subtitle: 'The single highest-spending day in the period.',
      icon: Icons.local_fire_department_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              _money(highestDay['amount']),
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w900,
                color: _analyticsTeal,
              ),
            ),
          ),

          const SizedBox(height: 9),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withOpacity(0.30),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.calendar_today_outlined,
                  size: 15,
                  color: colorScheme.onSurface.withOpacity(0.43),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    highestDay['date']?.toString() ?? 'Unknown date',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurface.withOpacity(0.60),
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

  Widget _emptyInsightCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String message,
  }) {
    return _sectionCard(
      context,
      eyebrow: 'BEHAVIOR PATTERN',
      title: title,
      subtitle: '',
      icon: icon,
      child: _emptyInline(context, message),
    );
  }

  // ============================================================
  // ANOMALIES
  // ============================================================

  Widget _buildAnomalies(
    BuildContext context, {
    required List<Map<String, dynamic>> anomalies,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final compact = ResponsiveHelper.useCompactLayout(context);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(compact ? 14 : 18),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.045),
        borderRadius: BorderRadius.circular(compact ? 19 : 22),
        border: Border.all(color: Colors.red.withOpacity(0.10)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: compact ? 35 : 39,
                height: compact ? 35 : 39,
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(compact ? 10 : 11),
                ),
                child: Icon(
                  Icons.warning_amber_rounded,
                  size: compact ? 18 : 20,
                  color: Colors.red,
                ),
              ),

              SizedBox(width: compact ? 9 : 11),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'RISK SIGNAL',
                      style: TextStyle(
                        fontSize: compact ? 9 : 9.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.85,
                        color: Colors.red,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Unusual Spending',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 7),

          Text(
            'These spending days were unusually high compared with your typical activity.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurface.withOpacity(0.66),
              height: 1.4,
            ),
          ),

          const SizedBox(height: 14),

          ...anomalies.map((item) {
            final severity = item['severity']?.toString() ?? 'moderate';

            final severityColor = severity == 'high'
                ? Colors.red
                : Colors.orange;

            return Padding(
              padding: const EdgeInsets.only(bottom: 9),
              child: _anomalyRow(
                context,
                item: item,
                severity: severity,
                severityColor: severityColor,
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _anomalyRow(
    BuildContext context, {
    required Map<String, dynamic> item,
    required String severity,
    required Color severityColor,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final compact = ResponsiveHelper.useCompactLayout(context);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(compact ? 10 : 12),
      decoration: BoxDecoration(
        color: colorScheme.surface.withOpacity(0.68),
        borderRadius: BorderRadius.circular(compact ? 13 : 15),
      ),
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

          const SizedBox(width: 9),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['date']?.toString() ?? 'Unknown date',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  severity.toUpperCase(),
                  style: TextStyle(
                    color: severityColor,
                    fontSize: 8.5,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.6,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerRight,
              child: Text(
                _money(item['amount']),
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // DATA QUALITY
  // ============================================================

  Widget _buildDataQuality(
    BuildContext context, {
    required Map<String, dynamic> quality,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final compact = ResponsiveHelper.useCompactLayout(context);

    final months = _int(quality['months_available']);

    final spendingMonths = _int(quality['months_with_spending']);

    final spendingDays = _int(quality['spending_days']);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(compact ? 13 : 16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withOpacity(0.30),
        borderRadius: BorderRadius.circular(compact ? 16 : 18),
        border: Border.all(color: colorScheme.outline.withOpacity(0.06)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: compact ? 34 : 38,
            height: compact ? 34 : 38,
            decoration: BoxDecoration(
              color: _analyticsTeal.withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.fact_check_outlined,
              size: compact ? 17 : 19,
              color: _analyticsTeal,
            ),
          ),

          SizedBox(width: compact ? 10 : 12),

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
                    color: colorScheme.onSurface.withOpacity(0.60),
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

  // ============================================================
  // SHARED UI
  // ============================================================

  Widget _sectionCard(
    BuildContext context, {
    required String eyebrow,
    required String title,
    required String subtitle,
    required IconData icon,
    required Widget child,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final compact = ResponsiveHelper.useCompactLayout(context);

    final cardPadding = ResponsiveHelper.cardPadding(context);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(compact ? 14 : cardPadding),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(compact ? 19 : 22),
        border: Border.all(color: colorScheme.outline.withOpacity(0.07)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.022),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: compact ? 36 : 40,
                height: compact ? 36 : 40,
                decoration: BoxDecoration(
                  color: _analyticsTeal.withOpacity(0.09),
                  borderRadius: BorderRadius.circular(compact ? 10 : 11),
                ),
                child: Icon(
                  icon,
                  size: compact ? 18 : 20,
                  color: _analyticsTeal,
                ),
              ),

              SizedBox(width: compact ? 10 : 12),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      eyebrow,
                      style: TextStyle(
                        fontSize: compact ? 9 : 9.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.85,
                        color: _analyticsTeal,
                      ),
                    ),

                    const SizedBox(height: 3),

                    Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        height: 1.15,
                      ),
                    ),

                    if (subtitle.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),

          SizedBox(height: compact ? 15 : 18),

          child,
        ],
      ),
    );
  }

  Widget _miniMetric(BuildContext context, String label, String value) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurface.withOpacity(0.58),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerRight,
              child: Text(
                value,
                textAlign: TextAlign.right,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
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

    final compact = ResponsiveHelper.useCompactLayout(context);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(compact ? 10 : 11),
      decoration: BoxDecoration(
        color: _analyticsTeal.withOpacity(0.07),
        borderRadius: BorderRadius.circular(compact ? 12 : 13),
        border: Border.all(color: _analyticsTeal.withOpacity(0.08)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline_rounded,
            size: compact ? 17 : 18,
            color: _analyticsTeal,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: colorScheme.onSurface.withOpacity(0.66),
                fontSize: compact ? 11 : 12,
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

    final compact = ResponsiveHelper.useCompactLayout(context);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(compact ? 11 : 12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withOpacity(0.32),
        borderRadius: BorderRadius.circular(compact ? 12 : 13),
      ),
      child: Text(
        message,
        style: TextStyle(
          color: colorScheme.onSurface.withOpacity(0.62),
          fontSize: compact ? 11 : 12,
          height: 1.4,
        ),
      ),
    );
  }

  // ============================================================
  // COLORS
  // ============================================================

  Color _budgetUsageColor(double usage) {
    if (usage >= 1) {
      return Colors.red;
    }

    if (usage >= 0.8) {
      return Colors.orange;
    }

    return _analyticsTeal;
  }

  Color _categoryColor(String category) {
    const categoryColors = {
      'Food': Colors.orange,
      'Transport': Colors.blue,
      'Shopping': Colors.purple,
      'Bills': Colors.red,
      'Entertainment': Colors.pink,
      'Health': Colors.green,
      'Education': Colors.indigo,
      'Other': Colors.blueGrey,
    };

    return categoryColors[category] ?? Colors.blueGrey;
  }
}
