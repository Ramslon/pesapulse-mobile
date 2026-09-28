import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../services/api_services.dart';
import '../utils/responsive_helper.dart';

import '../widgets/app/adaptive_app_bar.dart';
import '../widgets/app/app_scaffold.dart';

const Color _premiumPurple = Color(0xFF6D3FD9);
const Color _premiumPurpleDark = Color(0xFF34205F);

const Color _budgetBlue = Color(0xFF3B82F6);
const Color _budgetBlueLight = Color(0xFF60A5FA);

class AdvancedBudgetInsightsScreen extends StatefulWidget {
  const AdvancedBudgetInsightsScreen({super.key});

  @override
  State<AdvancedBudgetInsightsScreen> createState() =>
      _AdvancedBudgetInsightsScreenState();
}

class _AdvancedBudgetInsightsScreenState
    extends State<AdvancedBudgetInsightsScreen> {
  bool _isLoading = true;
  String? _errorMessage;

  Map<String, dynamic>? _data;

  final NumberFormat _currency = NumberFormat.currency(
    locale: 'en_KE',
    symbol: 'KES ',
    decimalDigits: 2,
  );

  @override
  void initState() {
    super.initState();
    _loadInsights();
  }

  Future<void> _loadInsights() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await ApiService.getAdvancedBudgetInsights();

      if (!mounted) return;

      setState(() {
        _data = Map<String, dynamic>.from(response);
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _errorMessage = _cleanError(e);
      });

      debugPrint('Advanced Budget Insights Error: $e');
    }
  }

  String _cleanError(Object error) {
    final message = error.toString();

    if (message.startsWith('Exception: ')) {
      return message.substring('Exception: '.length);
    }

    return message;
  }

  double _double(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  int _int(dynamic value) {
    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  String _money(dynamic value) {
    return _currency.format(_double(value));
  }

  String _monthName(int month) {
    const months = [
      '',
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];

    if (month >= 1 && month <= 12) {
      return months[month];
    }

    return 'Current Month';
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      showOfflineBanner: true,
      showSyncIcon: true,
      appBar: const AdaptiveAppBar(title: 'Budget Intelligence'),
      body: _buildBody(Theme.of(context)),
    );
  }

  Widget _buildBody(ThemeData theme) {
    if (_isLoading && _data == null) {
      return _buildLoadingState(theme);
    }

    if (_errorMessage != null && _data == null) {
      return _buildErrorState(theme);
    }

    if (_data == null) {
      return _buildNoDataState(theme);
    }

    final compact = ResponsiveHelper.useCompactLayout(context);

    final landscape = ResponsiveHelper.isLandscape(context);

    final desktop = ResponsiveHelper.isDesktop(context);

    final horizontalPadding = ResponsiveHelper.horizontalPadding(context);

    final sectionSpacing = ResponsiveHelper.sectionSpacing(context);

    final contentMaxWidth = ResponsiveHelper.contentMaxWidth(context);

    final topPadding = compact ? 8.0 : 14.0;

    final bottomPadding = landscape && !desktop
        ? 40.0
        : compact
        ? 28.0
        : 38.0;

    return RefreshIndicator(
      color: _premiumPurple,
      onRefresh: _loadInsights,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: EdgeInsets.fromLTRB(
          horizontalPadding,
          topPadding,
          horizontalPadding,
          bottomPadding,
        ),
        children: [
          Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: contentMaxWidth),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHero(theme),

                  SizedBox(height: sectionSpacing),

                  _buildBudgetPosition(theme),

                  SizedBox(height: sectionSpacing),

                  _buildPaceSection(theme),

                  SizedBox(height: sectionSpacing),

                  _buildProjectionSection(theme),

                  SizedBox(height: sectionSpacing),

                  _buildPressureSection(theme),

                  SizedBox(height: sectionSpacing),

                  _buildCategorySection(theme),

                  SizedBox(height: sectionSpacing),

                  _buildRecommendationsSection(theme),

                  SizedBox(height: sectionSpacing),

                  _buildDataQualitySection(theme),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHero(ThemeData theme) {
    final compact = ResponsiveHelper.useCompactLayout(context);

    final landscape = ResponsiveHelper.isLandscape(context);

    final cardPadding = ResponsiveHelper.cardPadding(context);

    final period = Map<String, dynamic>.from(_data!['period'] ?? {});

    final budget = Map<String, dynamic>.from(_data!['budget'] ?? {});

    final month = _int(period['month']);
    final year = _int(period['year']);

    final daysElapsed = _int(period['days_elapsed']);

    final daysRemaining = _int(period['days_remaining']);

    final budgetAmount = _double(budget['amount']);

    final spent = _double(budget['spent']);

    final usagePercentage = _double(budget['usage_percentage']);

    final progress = (usagePercentage / 100).clamp(0.0, 1.0);

    final isOverBudget = spent > budgetAmount && budgetAmount > 0;

    final statusAccent = isOverBudget ? Colors.red : _budgetBlueLight;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(
        landscape
            ? compact
                  ? 17
                  : 21
            : cardPadding,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(compact ? 22 : 26),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_premiumPurple, _premiumPurpleDark],
        ),
        border: Border.all(color: Colors.white.withOpacity(0.12)),
        boxShadow: [
          BoxShadow(
            color: _premiumPurple.withOpacity(0.20),
            blurRadius: 26,
            offset: const Offset(0, 11),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeroHeader(theme, compact, month, year),

          SizedBox(height: compact ? 20 : 24),

          if (compact)
            Column(
              children: [
                _buildHeroAmount(
                  theme,
                  isOverBudget: isOverBudget,
                  spent: spent,
                  budgetAmount: budgetAmount,
                ),
                const SizedBox(height: 20),
                _buildHeroProgress(
                  theme,
                  progress,
                  usagePercentage,
                  statusAccent,
                  compact,
                ),
              ],
            )
          else
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: _buildHeroAmount(
                    theme,
                    isOverBudget: isOverBudget,
                    spent: spent,
                    budgetAmount: budgetAmount,
                  ),
                ),
                const SizedBox(width: 24),
                _buildHeroProgress(
                  theme,
                  progress,
                  usagePercentage,
                  statusAccent,
                  compact,
                ),
              ],
            ),

          SizedBox(height: compact ? 18 : 21),

          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: LinearProgressIndicator(
              minHeight: compact ? 8 : 9,
              value: progress,
              backgroundColor: Colors.white.withOpacity(0.12),
              valueColor: AlwaysStoppedAnimation<Color>(
                isOverBudget ? Colors.red : _budgetBlueLight,
              ),
            ),
          ),

          SizedBox(height: compact ? 10 : 12),

          Row(
            children: [
              Icon(
                Icons.calendar_today_outlined,
                size: compact ? 14 : 15,
                color: Colors.white.withOpacity(0.62),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  '$daysElapsed days elapsed',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.white.withOpacity(0.65),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Text(
                '$daysRemaining days remaining',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.white.withOpacity(0.90),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeroHeader(ThemeData theme, bool compact, int month, int year) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: compact ? 46 : 52,
          height: compact ? 46 : 52,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.10),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withOpacity(0.10)),
          ),
          child: Icon(
            Icons.auto_awesome_rounded,
            size: compact ? 22 : 25,
            color: Colors.white,
          ),
        ),

        SizedBox(width: compact ? 11 : 13),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      'Premium Budget Intelligence',
                      style:
                          (compact
                                  ? theme.textTheme.titleLarge
                                  : theme.textTheme.headlineSmall)
                              ?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                height: 1.15,
                              ),
                    ),
                  ),
                  const SizedBox(width: 9),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.10),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withOpacity(0.10)),
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
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                '${_monthName(month)} $year',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.white.withOpacity(0.70),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHeroAmount(
    ThemeData theme, {
    required bool isOverBudget,
    required double spent,
    required double budgetAmount,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isOverBudget ? 'Budget exceeded' : 'Current budget position',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: Colors.white.withOpacity(0.70),
            fontWeight: FontWeight.w600,
          ),
        ),

        const SizedBox(height: 6),

        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            _money(spent),
            maxLines: 1,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: -0.5,
            ),
          ),
        ),

        const SizedBox(height: 4),

        Text(
          'of ${_money(budgetAmount)} used',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: Colors.white.withOpacity(0.66),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildHeroProgress(
    ThemeData theme,
    double progress,
    double usagePercentage,
    Color accent,
    bool compact,
  ) {
    final size = compact ? 88.0 : 106.0;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircularProgressIndicator(
            value: progress,
            strokeWidth: compact ? 9 : 10,
            strokeCap: StrokeCap.round,
            backgroundColor: Colors.white.withOpacity(0.14),
            color: accent,
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  '${usagePercentage.toStringAsFixed(1)}%',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Text(
                'used',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: Colors.white.withOpacity(0.62),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBudgetPosition(ThemeData theme) {
    final compact = ResponsiveHelper.useCompactLayout(context);

    final landscape = ResponsiveHelper.isLandscape(context);

    final spacing = ResponsiveHelper.spacing(context);

    final budget = Map<String, dynamic>.from(_data!['budget'] ?? {});

    final amount = _double(budget['amount']);

    final spent = _double(budget['spent']);

    final remaining = _double(budget['remaining']);

    final tileWidth = compact
        ? double.infinity
        : landscape
        ? 235.0
        : 205.0;

    return _sectionCard(
      theme,
      compact: compact,
      eyebrow: 'BUDGET SNAPSHOT',
      title: 'Budget Position',
      subtitle: 'Your current position for this budget period.',
      icon: Icons.account_balance_wallet_rounded,
      child: Wrap(
        spacing: spacing,
        runSpacing: spacing,
        children: [
          _metricTile(
            theme,
            label: 'Budget',
            value: _money(amount),
            icon: Icons.wallet_rounded,
            width: tileWidth,
          ),
          _metricTile(
            theme,
            label: 'Spent',
            value: _money(spent),
            icon: Icons.trending_up_rounded,
            width: tileWidth,
          ),
          _metricTile(
            theme,
            label: remaining >= 0 ? 'Remaining' : 'Over budget',
            value: _money(remaining),
            icon: remaining >= 0
                ? Icons.savings_rounded
                : Icons.warning_amber_rounded,
            width: tileWidth,
            valueColor: remaining >= 0 ? null : Colors.red.shade600,
          ),
        ],
      ),
    );
  }

  Widget _buildPaceSection(ThemeData theme) {
    final compact = ResponsiveHelper.useCompactLayout(context);

    final landscape = ResponsiveHelper.isLandscape(context);

    final spacing = ResponsiveHelper.spacing(context);

    final pace = Map<String, dynamic>.from(_data!['pace'] ?? {});

    final expectedUsage = _double(pace['expected_usage_percentage']);

    final actualDaily = _double(pace['actual_daily_spending']);

    final allowedDaily = pace['allowed_daily_spending'] == null
        ? null
        : _double(pace['allowed_daily_spending']);

    final difference = _double(pace['pace_difference_percentage']);

    final status = pace['status']?.toString() ?? 'no_data';

    final isPositive = status == 'under_budget_pace';

    final isNegative = status == 'above_budget_pace' || status == 'over_budget';

    final statusColor = isNegative
        ? Colors.red
        : isPositive
        ? Colors.green
        : _budgetBlue;

    final statusIcon = isNegative
        ? Icons.trending_up_rounded
        : isPositive
        ? Icons.trending_down_rounded
        : status == 'on_budget_pace'
        ? Icons.trending_flat_rounded
        : Icons.speed_rounded;

    final statusLabel = switch (status) {
      'under_budget_pace' => 'Under budget pace',
      'above_budget_pace' => 'Above budget pace',
      'over_budget' => 'Over budget',
      'on_budget_pace' => 'On budget pace',
      _ => 'Insufficient data',
    };

    final tileWidth = compact
        ? double.infinity
        : landscape
        ? 220.0
        : 190.0;

    return _sectionCard(
      theme,
      compact: compact,
      eyebrow: 'SPENDING CONTROL',
      title: 'Spending Pace',
      subtitle: 'Compare actual spending with where you would expect to be.',
      icon: Icons.speed_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _statusPill(
            statusColor: statusColor,
            icon: statusIcon,
            label: statusLabel,
            compact: compact,
          ),

          SizedBox(height: compact ? 14 : 16),

          Wrap(
            spacing: spacing,
            runSpacing: spacing,
            children: [
              _metricTile(
                theme,
                label: 'Expected usage',
                value: '${expectedUsage.toStringAsFixed(1)}%',
                icon: Icons.schedule_rounded,
                width: tileWidth,
              ),
              _metricTile(
                theme,
                label: 'Actual daily spending',
                value: _money(actualDaily),
                icon: Icons.payments_outlined,
                width: tileWidth,
              ),
              _metricTile(
                theme,
                label: 'Allowed daily spending',
                value: allowedDaily == null
                    ? 'Unavailable'
                    : _money(allowedDaily),
                icon: Icons.tune_rounded,
                width: tileWidth,
              ),
              _metricTile(
                theme,
                label: 'Pace difference',
                value:
                    '${difference > 0 ? '+' : ''}'
                    '${difference.toStringAsFixed(1)} pp',
                icon: difference > 0
                    ? Icons.arrow_upward_rounded
                    : difference < 0
                    ? Icons.arrow_downward_rounded
                    : Icons.remove_rounded,
                width: tileWidth,
                valueColor: statusColor,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProjectionSection(ThemeData theme) {
    final compact = ResponsiveHelper.useCompactLayout(context);

    final landscape = ResponsiveHelper.isLandscape(context);

    final spacing = ResponsiveHelper.spacing(context);

    final projection = Map<String, dynamic>.from(_data!['projection'] ?? {});

    final projected = _double(projection['projected_month_end_spending']);

    final overrun = _double(projection['projected_overrun']);

    final projectedRemaining = projection['projected_remaining'] == null
        ? null
        : _double(projection['projected_remaining']);

    final confidence = projection['confidence']?.toString() ?? '';

    final confidenceMessage =
        projection['confidence_message']?.toString() ?? '';

    final confidenceColor = switch (confidence) {
      'high' => Colors.green,
      'medium' => _budgetBlue,
      'low' => Colors.orange,
      _ => theme.colorScheme.onSurfaceVariant,
    };

    final tileWidth = compact
        ? double.infinity
        : landscape
        ? 270.0
        : 225.0;

    return _sectionCard(
      theme,
      compact: compact,
      eyebrow: 'FORECAST',
      title: 'Month-End Projection',
      subtitle: 'Estimate based on your spending pace so far.',
      icon: Icons.auto_graph_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: spacing,
            runSpacing: spacing,
            children: [
              _metricTile(
                theme,
                label: 'Projected spending',
                value: _money(projected),
                icon: Icons.insights_rounded,
                width: tileWidth,
              ),
              _metricTile(
                theme,
                label: overrun > 0
                    ? 'Projected overrun'
                    : 'Projected under budget',
                value: overrun > 0
                    ? _money(overrun)
                    : projectedRemaining == null
                    ? '—'
                    : _money(projectedRemaining),
                icon: overrun > 0
                    ? Icons.warning_rounded
                    : Icons.check_circle_outline_rounded,
                width: tileWidth,
                valueColor: overrun > 0
                    ? Colors.red.shade600
                    : Colors.green.shade600,
              ),
            ],
          ),

          SizedBox(height: compact ? 15 : 18),

          Container(
            padding: EdgeInsets.all(compact ? 12 : 14),
            decoration: BoxDecoration(
              color: confidenceColor.withOpacity(0.06),
              borderRadius: BorderRadius.circular(compact ? 15 : 17),
              border: Border.all(color: confidenceColor.withOpacity(0.10)),
            ),
            child: Row(
              children: [
                Container(
                  width: compact ? 34 : 38,
                  height: compact ? 34 : 38,
                  decoration: BoxDecoration(
                    color: confidenceColor.withOpacity(0.11),
                    borderRadius: BorderRadius.circular(compact ? 10 : 11),
                  ),
                  child: Icon(
                    Icons.analytics_outlined,
                    color: confidenceColor,
                    size: compact ? 17 : 18,
                  ),
                ),

                SizedBox(width: compact ? 9 : 11),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Projection confidence',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        confidence.isEmpty
                            ? 'Unknown'
                            : _capitalize(confidence),
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: confidenceColor,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          if (confidenceMessage.isNotEmpty) ...[
            const SizedBox(height: 10),
            _infoSurface(
              theme,
              icon: Icons.info_outline_rounded,
              message: confidenceMessage,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPressureSection(ThemeData theme) {
    final compact = ResponsiveHelper.useCompactLayout(context);

    final landscape = ResponsiveHelper.isLandscape(context);

    final pressure = Map<String, dynamic>.from(_data!['pressure'] ?? {});

    final level = pressure['level']?.toString() ?? 'no_data';

    final score = _double(pressure['score']);

    final message = pressure['message']?.toString() ?? '';

    final color = switch (level) {
      'critical' => Colors.red,
      'high' => Colors.deepOrange,
      'moderate' => Colors.orange,
      'low' => Colors.green,
      _ => _budgetBlue,
    };

    final label = switch (level) {
      'critical' => 'Critical pressure',
      'high' => 'High pressure',
      'moderate' => 'Moderate pressure',
      'low' => 'Low pressure',
      'no_budget' => 'No budget',
      'no_expenses' => 'No expenses',
      _ => 'No data',
    };

    return _sectionCard(
      theme,
      compact: compact,
      eyebrow: 'RISK SIGNAL',
      title: 'Budget Pressure',
      subtitle:
          'How much pressure your current spending is putting on the budget.',
      icon: Icons.warning_amber_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: compact ? 58 : 66,
                height: compact ? 58 : 66,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.10),
                  shape: BoxShape.circle,
                  border: Border.all(color: color.withOpacity(0.10)),
                ),
                child: Icon(
                  level == 'low'
                      ? Icons.check_rounded
                      : Icons.priority_high_rounded,
                  color: color,
                  size: compact ? 26 : 29,
                ),
              ),

              SizedBox(width: compact ? 11 : 14),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (message.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        message,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              SizedBox(
                width: landscape
                    ? 12
                    : compact
                    ? 8
                    : 12,
              ),

              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    score.toStringAsFixed(0),
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: color,
                    ),
                  ),
                  Text(
                    'score',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ),

          SizedBox(height: compact ? 15 : 17),

          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: LinearProgressIndicator(
              minHeight: compact ? 7 : 8,
              value: (score / 100).clamp(0.0, 1.0),
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategorySection(ThemeData theme) {
    final compact = ResponsiveHelper.useCompactLayout(context);

    final categories = List<Map<String, dynamic>>.from(
      (_data!['categories']?['breakdown'] as List? ?? []).map(
        (item) => Map<String, dynamic>.from(item),
      ),
    );

    final topCategory = _data!['categories']?['top_category']?.toString();

    if (categories.isEmpty) {
      return _sectionCard(
        theme,
        compact: compact,
        eyebrow: 'CATEGORY ANALYSIS',
        title: 'Spending Pressure by Category',
        subtitle: 'Your highest spending categories will appear here.',
        icon: Icons.category_outlined,
        child: _emptyInline(
          theme,
          Icons.category_outlined,
          'No category spending data is available yet.',
        ),
      );
    }

    return _sectionCard(
      theme,
      compact: compact,
      eyebrow: 'CATEGORY ANALYSIS',
      title: 'Spending Pressure by Category',
      subtitle: topCategory == null || topCategory.isEmpty
          ? 'Where your spending is concentrated.'
          : '$topCategory is currently your largest category.',
      icon: Icons.category_outlined,
      child: Column(
        children: [
          if (topCategory != null && topCategory.isNotEmpty) ...[
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(
                horizontal: compact ? 10 : 12,
                vertical: compact ? 9 : 10,
              ),
              decoration: BoxDecoration(
                color: _budgetBlue.withOpacity(0.07),
                borderRadius: BorderRadius.circular(compact ? 13 : 15),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.trending_up_rounded,
                    size: compact ? 17 : 18,
                    color: _budgetBlue,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Top category: $topCategory',
                      style: TextStyle(
                        fontSize: compact ? 11 : 12,
                        fontWeight: FontWeight.w700,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: compact ? 14 : 17),
          ],

          ...List.generate(categories.length, (index) {
            final category = categories[index];

            return _buildCategoryRow(theme, category, index, compact);
          }),
        ],
      ),
    );
  }

  Widget _buildCategoryRow(
    ThemeData theme,
    Map<String, dynamic> category,
    int index,
    bool compact,
  ) {
    final name = category['category']?.toString() ?? 'Other';

    final amount = _double(category['amount']);

    final percentage = _double(category['percentage']);

    final progress = (percentage / 100).clamp(0.0, 1.0);

    final color = _categoryColor(name);

    return Padding(
      padding: EdgeInsets.only(bottom: compact ? 13 : 15),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: compact ? 28 : 31,
                height: compact ? 28 : 31,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.09),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(
                  _categoryIcon(name),
                  size: compact ? 14 : 15,
                  color: color,
                ),
              ),

              SizedBox(width: compact ? 8 : 10),

              Expanded(
                child: Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),

              Text(
                _money(amount),
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),

              const SizedBox(width: 9),

              SizedBox(
                width: compact ? 45 : 50,
                child: Text(
                  '${percentage.toStringAsFixed(1)}%',
                  textAlign: TextAlign.end,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 7),

          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: LinearProgressIndicator(
              minHeight: compact ? 6 : 7,
              value: progress,
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),

          if (index != 0) const SizedBox(height: 1),
        ],
      ),
    );
  }

  Widget _buildRecommendationsSection(ThemeData theme) {
    final compact = ResponsiveHelper.useCompactLayout(context);

    final recommendations = List<Map<String, dynamic>>.from(
      (_data!['recommendations'] as List? ?? []).map(
        (item) => Map<String, dynamic>.from(item),
      ),
    );

    if (recommendations.isEmpty) {
      return _sectionCard(
        theme,
        compact: compact,
        eyebrow: 'ACTION PLAN',
        title: 'Recommendations',
        subtitle: 'Personalized budget guidance.',
        icon: Icons.lightbulb_outline_rounded,
        child: _emptyInline(
          theme,
          Icons.check_circle_outline_rounded,
          'No additional actions are recommended right now.',
        ),
      );
    }

    return _sectionCard(
      theme,
      compact: compact,
      eyebrow: 'ACTION PLAN',
      title: 'Recommendations',
      subtitle: 'Personalized actions based on your current budget position.',
      icon: Icons.lightbulb_outline_rounded,
      child: Column(
        children: [
          ...recommendations.map((recommendation) {
            final type = recommendation['type']?.toString() ?? 'general';

            final priority = recommendation['priority']?.toString() ?? 'medium';

            final title =
                recommendation['title']?.toString() ?? 'Recommendation';

            final message = recommendation['message']?.toString() ?? '';

            final accent = _recommendationColor(priority, type);

            return Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 10),
              padding: EdgeInsets.all(compact ? 12 : 15),
              decoration: BoxDecoration(
                color: accent.withOpacity(0.06),
                borderRadius: BorderRadius.circular(compact ? 16 : 18),
                border: Border.all(color: accent.withOpacity(0.13)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: compact ? 36 : 40,
                    height: compact ? 36 : 40,
                    decoration: BoxDecoration(
                      color: accent.withOpacity(0.11),
                      borderRadius: BorderRadius.circular(compact ? 11 : 12),
                    ),
                    child: Icon(
                      _recommendationIcon(type),
                      color: accent,
                      size: compact ? 18 : 19,
                    ),
                  ),

                  SizedBox(width: compact ? 10 : 12),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                title,
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: accent.withOpacity(0.09),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                priority.toUpperCase(),
                                style: TextStyle(
                                  color: accent,
                                  fontSize: 8.5,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ],
                        ),

                        if (message.isNotEmpty) ...[
                          const SizedBox(height: 5),
                          Text(
                            message,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildDataQualitySection(ThemeData theme) {
    final compact = ResponsiveHelper.useCompactLayout(context);

    final quality = Map<String, dynamic>.from(_data!['data_quality'] ?? {});

    final hasBudget = quality['has_budget'] == true;

    final hasExpenses = quality['has_expenses'] == true;

    final spendingDays = _int(quality['spending_days']);

    final confidence =
        quality['projection_confidence']?.toString() ?? 'unknown';

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(compact ? 13 : 16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.38),
        borderRadius: BorderRadius.circular(compact ? 18 : 20),
        border: Border.all(color: theme.colorScheme.outline.withOpacity(0.07)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: compact ? 34 : 38,
            height: compact ? 34 : 38,
            decoration: BoxDecoration(
              color: _budgetBlue.withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.verified_outlined,
              size: compact ? 17 : 19,
              color: _budgetBlue,
            ),
          ),

          SizedBox(width: compact ? 10 : 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Analysis coverage',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),

                const SizedBox(height: 5),

                Text(
                  'Budget: '
                  '${hasBudget ? 'available' : 'not available'} • '
                  'Expenses: '
                  '${hasExpenses ? 'available' : 'not available'} • '
                  'Spending days: $spendingDays • '
                  'Projection confidence: $confidence',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionCard(
    ThemeData theme, {
    required bool compact,
    required String eyebrow,
    required String title,
    required String subtitle,
    required IconData icon,
    required Widget child,
  }) {
    final cardPadding = ResponsiveHelper.cardPadding(context);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(compact ? 14 : cardPadding),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(compact ? 19 : 22),
        border: Border.all(color: theme.colorScheme.outline.withOpacity(0.07)),
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
                  color: _budgetBlue.withOpacity(0.09),
                  borderRadius: BorderRadius.circular(compact ? 10 : 11),
                ),
                child: Icon(icon, size: compact ? 18 : 20, color: _budgetBlue),
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
                        color: _budgetBlue,
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

                    const SizedBox(height: 3),

                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          SizedBox(height: compact ? 15 : 19),

          child,
        ],
      ),
    );
  }

  Widget _metricTile(
    ThemeData theme, {
    required String label,
    required String value,
    required IconData icon,
    double? width,
    Color? valueColor,
  }) {
    final compact = ResponsiveHelper.useCompactLayout(context);

    return SizedBox(
      width: width,
      child: Container(
        padding: EdgeInsets.all(compact ? 11 : 13),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.36),
          borderRadius: BorderRadius.circular(compact ? 15 : 17),
          border: Border.all(
            color: theme.colorScheme.outline.withOpacity(0.045),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: compact ? 34 : 37,
              height: compact ? 34 : 37,
              decoration: BoxDecoration(
                color: _budgetBlue.withOpacity(0.10),
                borderRadius: BorderRadius.circular(compact ? 10 : 11),
              ),
              child: Icon(icon, size: compact ? 17 : 18, color: _budgetBlue),
            ),

            SizedBox(width: compact ? 9 : 10),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
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
                        fontWeight: FontWeight.w800,
                        color: valueColor,
                      ),
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

  Widget _statusPill({
    required Color statusColor,
    required IconData icon,
    required String label,
    required bool compact,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 10 : 12,
        vertical: compact ? 8 : 9,
      ),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.09),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: statusColor.withOpacity(0.11)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: compact ? 16 : 17, color: statusColor),
          const SizedBox(width: 7),
          Text(
            label,
            style: TextStyle(
              color: statusColor,
              fontSize: compact ? 11 : 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoSurface(
    ThemeData theme, {
    required IconData icon,
    required String message,
  }) {
    final compact = ResponsiveHelper.useCompactLayout(context);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(compact ? 11 : 13),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.38),
        borderRadius: BorderRadius.circular(compact ? 13 : 15),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: compact ? 17 : 18,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              message,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyInline(ThemeData theme, IconData icon, String message) {
    final compact = ResponsiveHelper.useCompactLayout(context);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(compact ? 13 : 15),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.35),
        borderRadius: BorderRadius.circular(compact ? 14 : 16),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: compact ? 18 : 20,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _recommendationColor(String priority, String type) {
    if (type == 'positive') {
      return Colors.green;
    }

    switch (priority) {
      case 'high':
        return Colors.red;
      case 'medium':
        return Colors.orange;
      default:
        return _budgetBlue;
    }
  }

  IconData _recommendationIcon(String type) {
    switch (type) {
      case 'budget':
        return Icons.account_balance_wallet_rounded;
      case 'pace':
        return Icons.speed_rounded;
      case 'daily_limit':
        return Icons.tune_rounded;
      case 'category':
        return Icons.category_rounded;
      case 'positive':
        return Icons.check_circle_rounded;
      default:
        return Icons.lightbulb_outline_rounded;
    }
  }

  Color _categoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'food':
        return Colors.orange;
      case 'transport':
        return Colors.blue;
      case 'shopping':
        return Colors.purple;
      case 'bills':
        return Colors.red;
      case 'health':
        return Colors.green;
      case 'education':
        return Colors.indigo;
      case 'entertainment':
        return Colors.pink;
      default:
        return _budgetBlue;
    }
  }

  IconData _categoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'food':
        return Icons.restaurant_rounded;
      case 'transport':
        return Icons.directions_car_rounded;
      case 'shopping':
        return Icons.shopping_bag_rounded;
      case 'bills':
        return Icons.receipt_long_rounded;
      case 'health':
        return Icons.favorite_rounded;
      case 'education':
        return Icons.school_rounded;
      case 'entertainment':
        return Icons.movie_rounded;
      default:
        return Icons.category_rounded;
    }
  }

  String _capitalize(String value) {
    if (value.isEmpty) {
      return value;
    }

    return value[0].toUpperCase() + value.substring(1);
  }

  Widget _buildLoadingState(ThemeData theme) {
    final compact = ResponsiveHelper.useCompactLayout(context);

    final colorScheme = theme.colorScheme;

    return Center(
      child: Padding(
        padding: EdgeInsets.all(compact ? 24 : 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: compact ? 64 : 72,
              height: compact ? 64 : 72,
              decoration: BoxDecoration(
                color: _premiumPurple.withOpacity(0.09),
                borderRadius: BorderRadius.circular(compact ? 18 : 20),
              ),
              child: CircularProgressIndicator(
                strokeWidth: compact ? 3 : 3.2,
                color: _premiumPurple,
              ),
            ),
            SizedBox(height: compact ? 15 : 18),
            Text(
              'Analyzing your budget',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              'Building your premium budget insights...',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoDataState(ThemeData theme) {
    final compact = ResponsiveHelper.useCompactLayout(context);

    return Center(
      child: Padding(
        padding: EdgeInsets.all(compact ? 20 : 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: compact ? 68 : 78,
              height: compact ? 68 : 78,
              decoration: BoxDecoration(
                color: _budgetBlue.withOpacity(0.08),
                borderRadius: BorderRadius.circular(compact ? 20 : 22),
              ),
              child: Icon(
                Icons.insights_outlined,
                size: compact ? 30 : 34,
                color: _budgetBlue,
              ),
            ),
            SizedBox(height: compact ? 14 : 18),
            Text(
              'No budget intelligence available',
              textAlign: TextAlign.center,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 7),
            Text(
              'Add a budget and some expenses to generate advanced insights.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(ThemeData theme) {
    final compact = ResponsiveHelper.useCompactLayout(context);

    final padding = ResponsiveHelper.horizontalPadding(context);

    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: padding,
          vertical: compact ? 20 : 28,
        ),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 520),
          padding: EdgeInsets.all(compact ? 18 : 24),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(compact ? 19 : 22),
            border: Border.all(
              color: theme.colorScheme.error.withOpacity(0.12),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: compact ? 58 : 66,
                height: compact ? 58 : 66,
                decoration: BoxDecoration(
                  color: theme.colorScheme.error.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(
                  Icons.cloud_off_rounded,
                  size: compact ? 27 : 30,
                  color: theme.colorScheme.error,
                ),
              ),

              SizedBox(height: compact ? 13 : 16),

              Text(
                'Unable to load Budget Intelligence',
                textAlign: TextAlign.center,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),

              const SizedBox(height: 8),

              Text(
                _errorMessage ?? 'Something went wrong.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  height: 1.4,
                ),
              ),

              SizedBox(height: compact ? 16 : 20),

              FilledButton.icon(
                onPressed: _loadInsights,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Try Again'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
