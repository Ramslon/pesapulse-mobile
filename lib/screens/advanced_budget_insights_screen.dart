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
      appBar: const AdaptiveAppBar(title: 'Budget Intelligence'),
      body: _buildBody(Theme.of(context)),
    );
  }

  Widget _buildBody(ThemeData theme) {
    if (_isLoading && _data == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null && _data == null) {
      return _buildErrorState(theme);
    }

    if (_data == null) {
      return const Center(child: Text('No budget intelligence available.'));
    }

    final compact = ResponsiveHelper.useCompactLayout(context);

    final landscape = ResponsiveHelper.isLandscape(context);

    final desktop = ResponsiveHelper.isDesktop(context);

    final horizontalPadding = ResponsiveHelper.horizontalPadding(context);

    final sectionSpacing = ResponsiveHelper.sectionSpacing(context);

    final spacing = ResponsiveHelper.spacing(context);

    final contentMaxWidth = ResponsiveHelper.contentMaxWidth(context);

    final cardPadding = ResponsiveHelper.cardPadding(context);

    final topPadding = compact ? 8.0 : 12.0;

    final bottomPadding = landscape && !desktop
        ? 40.0
        : compact
        ? 28.0
        : 36.0;

    return RefreshIndicator(
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
                  _buildHero(theme, compact, landscape, cardPadding),

                  SizedBox(height: sectionSpacing),

                  _buildBudgetPosition(theme, compact, landscape, spacing),

                  SizedBox(height: sectionSpacing),

                  _buildPaceSection(theme, compact, landscape, spacing),

                  SizedBox(height: sectionSpacing),

                  _buildProjectionSection(theme, compact, landscape, spacing),

                  SizedBox(height: sectionSpacing),

                  _buildPressureSection(theme, compact, landscape),

                  SizedBox(height: sectionSpacing),

                  _buildCategorySection(theme, compact, landscape, spacing),

                  SizedBox(height: sectionSpacing),

                  _buildRecommendationsSection(
                    theme,
                    compact,
                    landscape,
                    spacing,
                  ),

                  SizedBox(height: sectionSpacing),

                  _buildDataQualitySection(theme, compact),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHero(
    ThemeData theme,
    bool compact,
    bool landscape,
    double cardPadding,
  ) {
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

    // Purple is the Premium identity.
    // Red is reserved for the over-budget state.
    final statusAccent = isOverBudget ? Colors.red : _budgetBlue;

    final titleSection = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: compact ? 46 : 52,
          height: compact ? 46 : 52,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(.10),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.account_balance_wallet_rounded,
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
                              ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(.10),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'PREMIUM',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                        letterSpacing: .6,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                '${_monthName(month)} $year',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.white.withOpacity(.72),
                ),
              ),
            ],
          ),
        ),
      ],
    );

    return Container(
      padding: EdgeInsets.all(
        landscape
            ? compact
                  ? 16
                  : 20
            : cardPadding,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(compact ? 22 : 28),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_premiumPurple, _premiumPurpleDark],
        ),
        border: Border.all(color: Colors.white.withOpacity(.12)),
        boxShadow: [
          BoxShadow(
            color: _premiumPurple.withOpacity(.18),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          titleSection,

          SizedBox(height: compact ? 20 : 24),

          if (compact)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeroAmount(
                  theme,
                  isOverBudget,
                  spent,
                  budgetAmount,
                  statusAccent,
                ),
                const SizedBox(height: 20),
                Center(
                  child: _buildHeroProgress(
                    theme,
                    progress,
                    usagePercentage,
                    statusAccent,
                    compact,
                    showOnPurple: true,
                  ),
                ),
              ],
            )
          else
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: _buildHeroAmount(
                    theme,
                    isOverBudget,
                    spent,
                    budgetAmount,
                    statusAccent,
                  ),
                ),
                const SizedBox(width: 20),
                _buildHeroProgress(
                  theme,
                  progress,
                  usagePercentage,
                  statusAccent,
                  compact,
                  showOnPurple: true,
                ),
              ],
            ),

          SizedBox(height: compact ? 18 : 20),

          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: LinearProgressIndicator(
              minHeight: compact ? 8 : 9,
              value: progress,
              backgroundColor: Colors.white.withOpacity(.12),
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
                color: Colors.white.withOpacity(.65),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  '$daysElapsed days elapsed',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.white.withOpacity(.65),
                  ),
                ),
              ),
              Text(
                '$daysRemaining days remaining',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.white.withOpacity(.88),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeroAmount(
    ThemeData theme,
    bool isOverBudget,
    double spent,
    double budgetAmount,
    Color accent,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isOverBudget ? 'Budget exceeded' : 'Budget position',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          _money(spent),
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: accent,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'of ${_money(budgetAmount)} used',
          style: theme.textTheme.bodyMedium,
        ),
      ],
    );
  }

  Widget _buildHeroProgress(
    ThemeData theme,
    double progress,
    double usagePercentage,
    Color accent,
    bool compact, {
    bool showOnPurple = false,
  }) {
    final size = compact ? 86.0 : 104.0;

    final backgroundColor = showOnPurple
        ? Colors.white.withOpacity(.14)
        : theme.colorScheme.surfaceContainerHighest;

    final textColor = showOnPurple ? Colors.white : theme.colorScheme.onSurface;

    final secondaryTextColor = showOnPurple
        ? Colors.white.withOpacity(.65)
        : theme.colorScheme.onSurfaceVariant;

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
            backgroundColor: backgroundColor,
            color: accent,
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${usagePercentage.toStringAsFixed(1)}%',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: textColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'used',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: secondaryTextColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBudgetPosition(
    ThemeData theme,
    bool compact,
    bool landscape,
    double spacing,
  ) {
    final budget = Map<String, dynamic>.from(_data!['budget'] ?? {});

    final amount = _double(budget['amount']);
    final spent = _double(budget['spent']);
    final remaining = _double(budget['remaining']);

    final width = compact
        ? double.infinity
        : landscape
        ? 220.0
        : 190.0;

    return _sectionCard(
      theme,
      compact: compact,
      title: 'Budget Position',
      subtitle: 'Your current position for this budget period.',
      icon: Icons.account_balance_rounded,
      child: Wrap(
        spacing: spacing,
        runSpacing: spacing,
        children: [
          _metricTile(
            theme,
            label: 'Budget',
            value: _money(amount),
            icon: Icons.wallet_rounded,
            width: width,
          ),
          _metricTile(
            theme,
            label: 'Spent',
            value: _money(spent),
            icon: Icons.trending_up_rounded,
            width: width,
          ),
          _metricTile(
            theme,
            label: remaining >= 0 ? 'Remaining' : 'Over budget',
            value: _money(remaining),
            icon: remaining >= 0
                ? Icons.savings_rounded
                : Icons.warning_amber_rounded,
            width: width,
            valueColor: remaining >= 0 ? null : Colors.red,
          ),
        ],
      ),
    );
  }

  Widget _buildPaceSection(
    ThemeData theme,
    bool compact,
    bool landscape,
    double spacing,
  ) {
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

    final width = compact
        ? double.infinity
        : landscape
        ? 220.0
        : 190.0;

    return _sectionCard(
      theme,
      compact: compact,
      title: 'Spending Pace',
      subtitle: 'Compare actual spending with where you would expect to be.',
      icon: Icons.speed_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: compact ? 10 : 12,
              vertical: compact ? 8 : 9,
            ),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.10),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(statusIcon, size: 18, color: statusColor),
                const SizedBox(width: 7),
                Text(
                  statusLabel,
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
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
                width: width,
              ),
              _metricTile(
                theme,
                label: 'Actual daily spending',
                value: _money(actualDaily),
                icon: Icons.payments_outlined,
                width: width,
              ),
              _metricTile(
                theme,
                label: 'Allowed daily spending',
                value: allowedDaily == null
                    ? 'Unavailable'
                    : _money(allowedDaily),
                icon: Icons.tune_rounded,
                width: width,
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
                width: width,
                valueColor: statusColor,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProjectionSection(
    ThemeData theme,
    bool compact,
    bool landscape,
    double spacing,
  ) {
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

    final width = compact
        ? double.infinity
        : landscape
        ? 250.0
        : 210.0;

    return _sectionCard(
      theme,
      compact: compact,
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
                width: width,
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
                width: width,
                valueColor: overrun > 0 ? Colors.red : Colors.green,
              ),
            ],
          ),

          SizedBox(height: compact ? 14 : 16),

          Row(
            children: [
              Text(
                'Confidence',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: compact ? 9 : 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: confidenceColor.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  confidence.isEmpty
                      ? 'Unknown'
                      : confidence[0].toUpperCase() + confidence.substring(1),
                  style: TextStyle(
                    color: confidenceColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),

          if (confidenceMessage.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(compact ? 12 : 14),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withOpacity(
                  0.55,
                ),
                borderRadius: BorderRadius.circular(compact ? 14 : 16),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    size: 19,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      confidenceMessage,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPressureSection(ThemeData theme, bool compact, bool landscape) {
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
      title: 'Budget Pressure',
      subtitle:
          'How much pressure your current spending is putting on the budget.',
      icon: Icons.warning_amber_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: compact ? 52 : 58,
                height: compact ? 52 : 58,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color.withOpacity(0.10),
                ),
                child: Icon(
                  level == 'low'
                      ? Icons.check_rounded
                      : Icons.priority_high_rounded,
                  color: color,
                  size: compact ? 25 : 28,
                ),
              ),
              SizedBox(width: compact ? 10 : 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (message.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        message,
                        style: theme.textTheme.bodyMedium?.copyWith(
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
              Text(
                '${score.toStringAsFixed(0)}',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),

          SizedBox(height: compact ? 14 : 16),

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

  Widget _buildCategorySection(
    ThemeData theme,
    bool compact,
    bool landscape,
    double spacing,
  ) {
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
      title: 'Spending Pressure by Category',
      subtitle: topCategory == null || topCategory.isEmpty
          ? 'Where your spending is concentrated.'
          : '$topCategory is currently your largest category.',
      icon: Icons.category_outlined,
      child: Column(
        children: categories.map((category) {
          final name = category['category']?.toString() ?? 'Other';

          final amount = _double(category['amount']);

          final percentage = _double(category['percentage']);

          final progress = (percentage / 100).clamp(0.0, 1.0);

          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        name,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Text(
                      _money(amount),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 10),
                    SizedBox(
                      width: compact ? 44 : 48,
                      child: Text(
                        '${percentage.toStringAsFixed(1)}%',
                        textAlign: TextAlign.end,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: LinearProgressIndicator(
                    minHeight: compact ? 6 : 7,
                    value: progress,
                    backgroundColor: theme.colorScheme.surfaceContainerHighest,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      _budgetBlue,
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildRecommendationsSection(
    ThemeData theme,
    bool compact,
    bool landscape,
    double spacing,
  ) {
    final recommendations = List<Map<String, dynamic>>.from(
      (_data!['recommendations'] as List? ?? []).map(
        (item) => Map<String, dynamic>.from(item),
      ),
    );

    if (recommendations.isEmpty) {
      return _sectionCard(
        theme,
        compact: compact,
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
      title: 'Recommendations',
      subtitle: 'Personalized actions based on your current budget position.',
      icon: Icons.lightbulb_outline_rounded,
      child: Column(
        children: recommendations.map((recommendation) {
          final type = recommendation['type']?.toString() ?? 'general';

          final priority = recommendation['priority']?.toString() ?? 'medium';

          final title = recommendation['title']?.toString() ?? 'Recommendation';

          final message = recommendation['message']?.toString() ?? '';

          final accent = _recommendationColor(theme, priority, type);

          return Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 10),
            padding: EdgeInsets.all(compact ? 12 : 15),
            decoration: BoxDecoration(
              color: accent.withOpacity(0.07),
              borderRadius: BorderRadius.circular(compact ? 16 : 18),
              border: Border.all(color: accent.withOpacity(0.16)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: compact ? 36 : 38,
                  height: compact ? 36 : 38,
                  decoration: BoxDecoration(
                    color: accent.withOpacity(0.12),
                    shape: BoxShape.circle,
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
                      if (compact)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              priority.toUpperCase(),
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: accent,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        )
                      else
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                title,
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Text(
                              priority.toUpperCase(),
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: accent,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),

                      if (message.isNotEmpty) ...[
                        const SizedBox(height: 5),
                        Text(
                          message,
                          style: theme.textTheme.bodyMedium?.copyWith(
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
        }).toList(),
      ),
    );
  }

  Widget _buildDataQualitySection(ThemeData theme, bool compact) {
    final quality = Map<String, dynamic>.from(_data!['data_quality'] ?? {});

    final hasBudget = quality['has_budget'] == true;

    final hasExpenses = quality['has_expenses'] == true;

    final spendingDays = _int(quality['spending_days']);

    final confidence =
        quality['projection_confidence']?.toString() ?? 'unknown';

    return Container(
      padding: EdgeInsets.all(compact ? 14 : 16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.45),
        borderRadius: BorderRadius.circular(compact ? 18 : 20),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.verified_outlined,
            size: 20,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Analysis coverage',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  'Budget: ${hasBudget ? 'available' : 'not available'} • '
                  'Expenses: ${hasExpenses ? 'available' : 'not available'} • '
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
    required String title,
    required String subtitle,
    required IconData icon,
    required Widget child,
  }) {
    final sectionPadding = ResponsiveHelper.cardPadding(context);

    final horizontalCardPadding = compact ? 14.0 : sectionPadding;

    final verticalCardPadding = compact ? 16.0 : sectionPadding;

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(compact ? 20 : 24),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: horizontalCardPadding,
          vertical: verticalCardPadding,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: compact ? 34 : 38,
                  height: compact ? 34 : 38,
                  decoration: BoxDecoration(
                    color: _budgetBlue.withOpacity(.10),
                    borderRadius: BorderRadius.circular(compact ? 10 : 12),
                  ),
                  child: Icon(
                    icon,
                    size: compact ? 18 : 20,
                    color: _budgetBlue,
                  ),
                ),
                SizedBox(width: compact ? 9 : 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            SizedBox(height: compact ? 14 : 18),

            child,
          ],
        ),
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
        padding: EdgeInsets.all(compact ? 12 : 14),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.40),
          borderRadius: BorderRadius.circular(compact ? 16 : 18),
        ),
        child: Row(
          children: [
            Container(
              width: compact ? 34 : 36,
              height: compact ? 34 : 36,
              decoration: BoxDecoration(
                color: _budgetBlue.withOpacity(.10),
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
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: valueColor,
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

  Widget _emptyInline(ThemeData theme, IconData icon, String message) {
    final compact = ResponsiveHelper.useCompactLayout(context);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(compact ? 14 : 16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.35),
        borderRadius: BorderRadius.circular(compact ? 14 : 16),
      ),
      child: Row(
        children: [
          Icon(icon, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _recommendationColor(ThemeData theme, String priority, String type) {
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

  Widget _buildErrorState(ThemeData theme) {
    final compact = ResponsiveHelper.useCompactLayout(context);

    final padding = ResponsiveHelper.horizontalPadding(context);

    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: padding,
          vertical: compact ? 20 : 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.cloud_off_rounded,
              size: compact ? 46 : 54,
              color: theme.colorScheme.error,
            ),
            SizedBox(height: compact ? 12 : 16),
            Text(
              'Unable to load Budget Intelligence',
              textAlign: TextAlign.center,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage ?? 'Something went wrong.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
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
    );
  }
}
