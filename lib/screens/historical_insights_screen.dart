import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../services/api_services.dart';
import '../utils/responsive_helper.dart';
import '../widgets/app/adaptive_app_bar.dart';
import '../widgets/app/app_scaffold.dart';
import '../widgets/premium/premium_state_widgets.dart';

const Color _premiumPurple = Color(0xFF6D3FD9);
const Color _premiumPurpleDark = Color(0xFF34205F);
const Color _analyticsTeal = Color(0xFF14B8A6);

class HistoricalInsightsScreen extends StatefulWidget {
  const HistoricalInsightsScreen({super.key});

  @override
  State<HistoricalInsightsScreen> createState() =>
      _HistoricalInsightsScreenState();
}

class _HistoricalInsightsScreenState extends State<HistoricalInsightsScreen> {
  final NumberFormat _currency = NumberFormat.currency(
    locale: 'en_KE',
    symbol: 'KES ',
    decimalDigits: 2,
  );

  bool _isLoading = true;
  bool _isRefreshing = false;
  String? _errorMessage;

  int _selectedMonths = 12;

  Map<String, dynamic>? _data;

  @override
  void initState() {
    super.initState();
    _loadHistoricalInsights();
  }

  // ---------------------------------------------------------------------------
  // DATA
  // ---------------------------------------------------------------------------

  Future<void> _loadHistoricalInsights({bool refresh = false}) async {
    if (refresh) {
      if (_isRefreshing) return;

      setState(() {
        _isRefreshing = true;
        _errorMessage = null;
      });
    } else {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final response = await ApiService.getHistoricalInsights(
        months: _selectedMonths,
      );

      if (!mounted) return;

      setState(() {
        _data = response;
        _isLoading = false;
        _isRefreshing = false;
        _errorMessage = null;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _isRefreshing = false;
        _errorMessage = _cleanError(e);
      });

      debugPrint('Historical Insights Error: $e');
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
    if (value == null) return 0;

    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(value.toString()) ?? 0;
  }

  int _int(dynamic value) {
    if (value == null) return 0;

    if (value is int) return value;

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(value.toString()) ?? 0;
  }

  String _money(dynamic value) {
    return _currency.format(_double(value));
  }

  String _percentage(dynamic value) {
    final number = _double(value);

    if (number == number.roundToDouble()) {
      return '${number.toInt()}%';
    }

    return '${number.toStringAsFixed(1)}%';
  }

  String _monthLabel(dynamic value) {
    if (value == null) return '';

    final text = value.toString();

    try {
      final date = DateTime.parse('$text-01');
      return DateFormat('MMMM yyyy').format(date);
    } catch (_) {
      return text;
    }
  }

  String _monthShortLabel(dynamic value) {
    if (value == null) return '';

    final text = value.toString();

    try {
      final date = DateTime.parse('$text-01');
      return DateFormat('MMM').format(date);
    } catch (_) {
      return text.length > 3 ? text.substring(0, 3) : text;
    }
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

  List<Map<String, dynamic>> _list(dynamic value) {
    if (value is! List) {
      return [];
    }

    return value
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  Map<String, dynamic> get _summary => _map(_data?['summary']);

  Map<String, dynamic> get _trend => _map(_data?['trend']);

  Map<String, dynamic> get _categories => _map(_data?['categories']);

  Map<String, dynamic> get _dataQuality => _map(_data?['data_quality']);

  List<Map<String, dynamic>> get _monthly => _list(_data?['monthly']);

  List<Map<String, dynamic>> get _historicalInsights =>
      _list(_data?['historical_insights']);

  List<Map<String, dynamic>> get _categoryBreakdown =>
      _list(_categories['breakdown']);

  // ---------------------------------------------------------------------------
  // TREND HELPERS
  // ---------------------------------------------------------------------------

  String _directionLabel(String direction) {
    switch (direction.toLowerCase()) {
      case 'increasing':
        return 'Increasing';

      case 'decreasing':
        return 'Decreasing';

      case 'stable':
        return 'Stable';

      default:
        return 'Trend';
    }
  }

  Color _directionColor(String direction) {
    switch (direction.toLowerCase()) {
      case 'increasing':
        return Colors.red;

      case 'decreasing':
        return Colors.green;

      case 'stable':
        return _analyticsTeal;

      default:
        return _analyticsTeal;
    }
  }

  IconData _directionIcon(String direction) {
    switch (direction.toLowerCase()) {
      case 'increasing':
        return Icons.trending_up_rounded;

      case 'decreasing':
        return Icons.trending_down_rounded;

      case 'stable':
        return Icons.trending_flat_rounded;

      default:
        return Icons.insights_rounded;
    }
  }

  // ---------------------------------------------------------------------------
  // CATEGORY HELPERS
  // ---------------------------------------------------------------------------

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

  IconData _categoryIcon(String category) {
    switch (category) {
      case 'Food':
        return Icons.restaurant_rounded;

      case 'Transport':
        return Icons.directions_car_rounded;

      case 'Shopping':
        return Icons.shopping_bag_rounded;

      case 'Bills':
        return Icons.receipt_long_rounded;

      case 'Entertainment':
        return Icons.movie_rounded;

      case 'Health':
        return Icons.health_and_safety_rounded;

      case 'Education':
        return Icons.school_rounded;

      case 'Other':
      default:
        return Icons.category_rounded;
    }
  }

  // ---------------------------------------------------------------------------
  // BUILD
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppScaffold(
      appBar: const AdaptiveAppBar(title: 'Historical Insights'),
      body: _buildBody(context, theme),
    );
  }

  Widget _buildBody(BuildContext context, ThemeData theme) {
    // Initial loading: there is no historical data to display yet.
    if (_isLoading && _data == null) {
      return const PremiumLoadingState(
        title: 'Preparing historical insights',
        message: 'Analyzing your spending history and identifying patterns...',
        accentColor: _premiumPurple,
        icon: Icons.auto_graph_rounded,
      );
    }

    // Initial load failed: there is no existing data to keep on screen.
    if (_errorMessage != null && _data == null) {
      return PremiumErrorState(
        title: 'Unable to load historical insights',
        message:
            _errorMessage ??
            'Something went wrong while loading your historical spending data.',
        onRetry: _loadHistoricalInsights,
        accentColor: _premiumPurple,
        icon: Icons.cloud_off_rounded,
        retryLabel: 'Try Again',
      );
    }

    // Defensive fallback.
    if (_data == null) {
      return PremiumErrorState(
        title: 'Historical insights unavailable',
        message: 'No historical insight data is currently available.',
        onRetry: _loadHistoricalInsights,
        accentColor: _premiumPurple,
        icon: Icons.analytics_outlined,
        retryLabel: 'Reload',
      );
    }

    final horizontalPadding = ResponsiveHelper.horizontalPadding(context);

    final contentMaxWidth = ResponsiveHelper.contentMaxWidth(context);

    return Stack(
      children: [
        RefreshIndicator(
          color: _analyticsTeal,
          onRefresh: () => _loadHistoricalInsights(refresh: true),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.fromLTRB(
              horizontalPadding,
              ResponsiveHelper.spacing(context),
              horizontalPadding,
              40,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: contentMaxWidth),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Existing data remains visible if a refresh fails.
                    if (_errorMessage != null) ...[
                      PremiumInlineError(
                        message: _errorMessage!,
                        accentColor: _analyticsTeal,
                      ),
                      const SizedBox(height: 16),
                    ],

                    _buildHero(context),

                    SizedBox(height: ResponsiveHelper.sectionSpacing(context)),

                    _buildPeriodSelector(context),

                    SizedBox(height: ResponsiveHelper.sectionSpacing(context)),

                    _buildSummary(context),

                    SizedBox(height: ResponsiveHelper.sectionSpacing(context)),

                    _buildTrendCard(context),

                    SizedBox(height: ResponsiveHelper.sectionSpacing(context)),

                    _buildMonthlyHistory(context),

                    SizedBox(height: ResponsiveHelper.sectionSpacing(context)),

                    _buildHighestLowest(context),

                    SizedBox(height: ResponsiveHelper.sectionSpacing(context)),

                    _buildCategorySection(context),

                    SizedBox(height: ResponsiveHelper.sectionSpacing(context)),

                    _buildInsightsSection(context),

                    SizedBox(height: ResponsiveHelper.sectionSpacing(context)),

                    _buildDataQuality(context),
                  ],
                ),
              ),
            ),
          ),
        ),

        // Keep the lightweight refresh indicator because Historical Insights
        // already tracks refresh separately from initial loading.
        if (_isRefreshing)
          const Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: LinearProgressIndicator(minHeight: 2, color: _analyticsTeal),
          ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // HERO
  // ---------------------------------------------------------------------------

  Widget _buildHero(BuildContext context) {
    final isCompact = ResponsiveHelper.isMobilePortrait(context);

    return Container(
      constraints: const BoxConstraints(minHeight: 190),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_premiumPurpleDark, _premiumPurple],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: _premiumPurple.withOpacity(0.20),
            blurRadius: 28,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned(
            right: -45,
            top: -55,
            child: _decorativeCircle(
              size: 170,
              color: Colors.white.withOpacity(0.07),
            ),
          ),
          Positioned(
            right: 70,
            bottom: -75,
            child: _decorativeCircle(
              size: 150,
              color: Colors.white.withOpacity(0.05),
            ),
          ),
          Positioned(
            left: -45,
            bottom: -70,
            child: _decorativeCircle(
              size: 130,
              color: Colors.white.withOpacity(0.04),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(
              ResponsiveHelper.isDesktop(context) ? 30 : 24,
            ),
            child: isCompact
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeroIcon(),
                      const SizedBox(height: 18),
                      _buildHeroText(context),
                    ],
                  )
                : Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      _buildHeroIcon(),
                      const SizedBox(width: 20),
                      Expanded(child: _buildHeroText(context)),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _decorativeCircle({required double size, required Color color}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }

  Widget _buildHeroIcon() {
    return Container(
      width: 66,
      height: 66,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.13),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.16)),
      ),
      child: const Icon(
        Icons.auto_graph_rounded,
        color: Colors.white,
        size: 32,
      ),
    );
  }

  Widget _buildHeroText(BuildContext context) {
    final titleSize = ResponsiveHelper.isMobilePortrait(context) ? 24.0 : 28.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.13),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: Colors.white.withOpacity(0.15)),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.workspace_premium_rounded,
                color: Colors.amber,
                size: 15,
              ),
              SizedBox(width: 6),
              Text(
                'PREMIUM ANALYTICS',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.7,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Historical Insights',
          style: TextStyle(
            color: Colors.white,
            fontSize: titleSize,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 7),
        Text(
          'Understand how your spending and budgeting behavior has changed over time.',
          style: TextStyle(
            color: Colors.white.withOpacity(0.78),
            fontSize: 13.5,
            height: 1.45,
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // PERIOD SELECTOR
  // ---------------------------------------------------------------------------

  Widget _buildPeriodSelector(BuildContext context) {
    final theme = Theme.of(context);

    return _card(
      context: context,
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: _analyticsTeal.withOpacity(0.10),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.calendar_month_rounded,
              color: _analyticsTeal,
              size: 22,
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Historical period',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Choose how much history to analyze',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withOpacity(
                0.55,
              ),
              borderRadius: BorderRadius.circular(13),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<int>(
                value: _selectedMonths,
                borderRadius: BorderRadius.circular(14),
                padding: const EdgeInsets.symmetric(horizontal: 8),
                items: const [
                  DropdownMenuItem(value: 3, child: Text('3 months')),
                  DropdownMenuItem(value: 6, child: Text('6 months')),
                  DropdownMenuItem(value: 12, child: Text('12 months')),
                  DropdownMenuItem(value: 18, child: Text('18 months')),
                  DropdownMenuItem(value: 24, child: Text('24 months')),
                ],
                onChanged: (value) {
                  if (value == null || value == _selectedMonths) {
                    return;
                  }

                  setState(() {
                    _selectedMonths = value;
                  });

                  _loadHistoricalInsights();
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // SUMMARY
  // ---------------------------------------------------------------------------

  Widget _buildSummary(BuildContext context) {
    final theme = Theme.of(context);

    final items = [
      (
        'Total spending',
        _money(_summary['total_spending']),
        Icons.payments_rounded,
        _analyticsTeal,
      ),
      (
        'Average monthly',
        _money(_summary['average_monthly_spending']),
        Icons.calendar_month_rounded,
        _analyticsTeal,
      ),
      (
        'Total budgeted',
        _money(_summary['total_budgeted']),
        Icons.account_balance_wallet_rounded,
        _premiumPurple,
      ),
      (
        'Budget usage',
        _percentage(_summary['budget_usage_percentage']),
        Icons.pie_chart_rounded,
        _premiumPurple,
      ),
      (
        'Spending months',
        '${_int(_summary['months_with_spending'])}',
        Icons.date_range_rounded,
        _analyticsTeal,
      ),
    ];

    final columns = ResponsiveHelper.gridColumns(
      context,
      mobilePortrait: 2,
      mobileLandscape: 3,
      tabletPortrait: 3,
      tabletLandscape: 4,
      desktop: 4,
    );

    final spacing = ResponsiveHelper.spacing(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeading(
          context,
          icon: Icons.insights_rounded,
          title: 'At a glance',
          subtitle: 'Your overall historical spending picture',
        ),
        SizedBox(height: spacing),

        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: items.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: spacing,
            mainAxisSpacing: spacing,

            // Use an explicit height instead of childAspectRatio.
            mainAxisExtent: _summaryCardHeight(context),
          ),
          itemBuilder: (context, index) {
            final item = items[index];

            return _buildSummaryMetric(
              context,
              theme: theme,
              title: item.$1,
              value: item.$2,
              icon: item.$3,
              color: item.$4,
            );
          },
        ),
      ],
    );
  }

  double _summaryCardHeight(BuildContext context) {
    if (ResponsiveHelper.isMobilePortrait(context)) {
      return 112;
    }

    if (ResponsiveHelper.isMobileLandscape(context)) {
      return 105;
    }

    if (ResponsiveHelper.isTabletPortrait(context)) {
      return 115;
    }

    if (ResponsiveHelper.isTabletLandscape(context)) {
      return 120;
    }

    return 125;
  }

  Widget _buildSummaryMetric(
    BuildContext context, {
    required ThemeData theme,
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return _card(
      context: context,

      // Smaller padding because these are compact metric cards.
      padding: ResponsiveHelper.isMobilePortrait(context) ? 14 : 16,

      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color.withOpacity(0.10),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 19),
          ),

          const SizedBox(width: 11),

          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                  ),
                ),

                const SizedBox(height: 5),

                FittedBox(
                  alignment: Alignment.centerLeft,
                  fit: BoxFit.scaleDown,
                  child: Text(
                    value,
                    maxLines: 1,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: theme.colorScheme.onSurface,
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

  // ---------------------------------------------------------------------------
  // TREND
  // ---------------------------------------------------------------------------

  Widget _buildTrendCard(BuildContext context) {
    final direction = (_trend['direction'] ?? '').toString().toLowerCase();

    final hasEnoughData =
        _trend['can_analyze'] == true ||
        _trend['can_analyze']?.toString() == '1';

    if (!hasEnoughData && _trend.isNotEmpty) {
      return _buildTrendInsufficientData(context);
    }

    final directionColor = _directionColor(direction);

    final changeAmount = _double(_trend['change_amount']);
    final changePercentage = _double(_trend['change_percentage']);

    final content = _card(
      context: context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeading(
            context,
            icon: Icons.trending_up_rounded,
            title: 'Spending trend',
            subtitle: 'How your spending has changed',
            showCardIcon: false,
          ),
          const SizedBox(height: 18),
          ResponsiveHelper.useCompactLayout(context)
              ? Column(
                  children: [
                    _buildTrendStatus(
                      context,
                      direction: direction,
                      color: directionColor,
                    ),
                    const SizedBox(height: 16),
                    _buildTrendMetrics(
                      context,
                      changeAmount: changeAmount,
                      changePercentage: changePercentage,
                    ),
                  ],
                )
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      flex: 4,
                      child: _buildTrendStatus(
                        context,
                        direction: direction,
                        color: directionColor,
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      flex: 6,
                      child: _buildTrendMetrics(
                        context,
                        changeAmount: changeAmount,
                        changePercentage: changePercentage,
                      ),
                    ),
                  ],
                ),
        ],
      ),
    );

    return content;
  }

  Widget _buildTrendStatus(
    BuildContext context, {
    required String direction,
    required Color color,
  }) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: color.withOpacity(0.07),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withOpacity(0.14)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(_directionIcon(direction), color: color, size: 24),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Current direction',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _directionLabel(direction),
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrendMetrics(
    BuildContext context, {
    required double changeAmount,
    required double changePercentage,
  }) {
    final theme = Theme.of(context);

    final columns = ResponsiveHelper.isMobilePortrait(context) ? 2 : 2;

    final spacing = ResponsiveHelper.spacing(context);

    final items = [
      ('Change', _money(changeAmount.abs()), Icons.swap_vert_rounded),
      (
        'Change rate',
        _percentage(changePercentage.abs()),
        Icons.percent_rounded,
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        crossAxisSpacing: spacing,
        mainAxisSpacing: spacing,
        childAspectRatio: 1.8,
      ),
      itemBuilder: (context, index) {
        final item = items[index];

        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.45),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(item.$3, color: _analyticsTeal, size: 19),
              const SizedBox(height: 8),
              Text(
                item.$1,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 2),
              FittedBox(
                alignment: Alignment.centerLeft,
                fit: BoxFit.scaleDown,
                child: Text(
                  item.$2,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTrendInsufficientData(BuildContext context) {
    return _card(
      context: context,
      child: _infoMessage(
        context,
        icon: Icons.timeline_rounded,
        title: 'Trend analysis needs more data',
        message:
            'Keep recording your spending across more months to unlock a reliable historical trend.',
        color: _analyticsTeal,
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // MONTHLY HISTORY
  // ---------------------------------------------------------------------------

  Widget _buildMonthlyHistory(BuildContext context) {
    final theme = Theme.of(context);

    final spendingEntries = _monthly.where((entry) {
      return _double(entry['spent']) > 0;
    }).toList();

    return _card(
      context: context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeading(
            context,
            icon: Icons.show_chart_rounded,
            title: 'Monthly history',
            subtitle: 'Spending movement across the selected period',
            showCardIcon: false,
          ),
          const SizedBox(height: 20),
          if (spendingEntries.isEmpty)
            _infoMessage(
              context,
              icon: Icons.bar_chart_rounded,
              title: 'No spending history yet',
              message:
                  'Once you record expenses, your monthly spending pattern will appear here.',
              color: _analyticsTeal,
            )
          else
            SizedBox(
              height: _chartHeight(context),
              child: _buildMonthlyChart(context, theme),
            ),
        ],
      ),
    );
  }

  double _chartHeight(BuildContext context) {
    if (ResponsiveHelper.isMobilePortrait(context)) {
      return 245;
    }

    if (ResponsiveHelper.isMobileLandscape(context)) {
      return 215;
    }

    if (ResponsiveHelper.isTabletPortrait(context)) {
      return 275;
    }

    return 300;
  }

  Widget _buildMonthlyChart(BuildContext context, ThemeData theme) {
    final values = _monthly.map((entry) => _double(entry['spent'])).toList();

    final maxValue = values.isEmpty ? 0.0 : values.reduce(math.max);

    final maxY = maxValue <= 0 ? 100.0 : maxValue * 1.25;

    final interval = _chartInterval(maxY);

    final spots = <FlSpot>[];

    for (int index = 0; index < _monthly.length; index++) {
      spots.add(FlSpot(index.toDouble(), _double(_monthly[index]['spent'])));
    }

    return LineChart(
      LineChartData(
        minX: 0,
        maxX: math.max(0, (_monthly.length - 1).toDouble()),
        minY: 0,
        maxY: maxY,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: interval,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: theme.dividerColor.withOpacity(0.12),
              strokeWidth: 1,
            );
          },
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 48,
              interval: interval,
              getTitlesWidget: (value, meta) {
                return Text(
                  _compactAmount(value),
                  style: TextStyle(
                    fontSize: 9,
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: _bottomTitleInterval(context),
              getTitlesWidget: (value, meta) {
                final index = value.round();

                if (index < 0 || index >= _monthly.length) {
                  return const SizedBox.shrink();
                }

                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    _monthShortLabel(_monthly[index]['month']),
                    style: TextStyle(
                      fontSize: 9,
                      color: theme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        lineTouchData: LineTouchData(
          enabled: true,
          handleBuiltInTouches: true,
          touchTooltipData: LineTouchTooltipData(
            tooltipRoundedRadius: 12,
            getTooltipItems: (spots) {
              return spots.map((spot) {
                final index = spot.x.round();

                if (index < 0 || index >= _monthly.length) {
                  return null;
                }

                final month = _monthLabel(_monthly[index]['month']);

                return LineTooltipItem(
                  '$month\n',
                  TextStyle(
                    color: theme.colorScheme.onSurface,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                  children: [
                    TextSpan(
                      text: _money(spot.y),
                      style: const TextStyle(
                        color: _analyticsTeal,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                );
              }).toList();
            },
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            curveSmoothness: 0.22,
            color: _analyticsTeal,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: _monthly.length <= 12,
              getDotPainter: (spot, percent, barData, index) {
                return FlDotCirclePainter(
                  radius: 3.5,
                  color: _analyticsTeal,
                  strokeWidth: 2,
                  strokeColor: theme.colorScheme.surface,
                );
              },
            ),
            belowBarData: BarAreaData(
              show: true,
              color: _analyticsTeal.withOpacity(0.08),
            ),
          ),
        ],
      ),
    );
  }

  double _chartInterval(double maxY) {
    if (maxY <= 100) return 25;
    if (maxY <= 500) return 100;
    if (maxY <= 1000) return 250;
    if (maxY <= 5000) return 1000;
    if (maxY <= 10000) return 2500;

    return maxY / 4;
  }

  double _bottomTitleInterval(BuildContext context) {
    final count = _monthly.length;

    if (count <= 6) return 1;

    if (ResponsiveHelper.isMobilePortrait(context)) {
      return count <= 12 ? 2 : 3;
    }

    if (count <= 12) return 2;

    return 3;
  }

  String _compactAmount(double value) {
    if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)}M';
    }

    if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(1)}K';
    }

    return value.toStringAsFixed(0);
  }

  // ---------------------------------------------------------------------------
  // HIGHEST / LOWEST
  // ---------------------------------------------------------------------------

  Widget _buildHighestLowest(BuildContext context) {
    final theme = Theme.of(context);

    final highest = _map(_summary['highest_spending_month']);
    final lowest = _map(_summary['lowest_spending_month']);

    final items = [
      (
        'Highest spending',
        _monthLabel(highest['month']),
        _money(highest['spent']),
        Icons.arrow_upward_rounded,
        Colors.red,
      ),
      (
        'Lowest spending',
        _monthLabel(lowest['month']),
        _money(lowest['spent']),
        Icons.arrow_downward_rounded,
        Colors.green,
      ),
    ];

    final columns = ResponsiveHelper.isMobilePortrait(context) ? 1 : 2;

    final spacing = ResponsiveHelper.spacing(context);

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        crossAxisSpacing: spacing,
        mainAxisSpacing: spacing,
        childAspectRatio: columns == 1 ? 2.7 : 2.2,
      ),
      itemBuilder: (context, index) {
        final item = items[index];

        return _card(
          context: context,
          padding: ResponsiveHelper.cardPadding(context),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: item.$5.withOpacity(0.10),
                  shape: BoxShape.circle,
                ),
                child: Icon(item.$4, color: item.$5, size: 23),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      item.$1,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.$2.isEmpty ? 'No data' : item.$2,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.$3,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: item.$5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // CATEGORIES
  // ---------------------------------------------------------------------------

  Widget _buildCategorySection(BuildContext context) {
    final theme = Theme.of(context);

    if (_categoryBreakdown.isEmpty) {
      return _card(
        context: context,
        child: _infoMessage(
          context,
          icon: Icons.category_rounded,
          title: 'No category history yet',
          message:
              'Record more expenses to see how your spending is distributed across categories.',
          color: _analyticsTeal,
        ),
      );
    }

    final topCategory = (_categories['top_category'] ?? '').toString();

    return _card(
      context: context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeading(
            context,
            icon: Icons.category_rounded,
            title: 'Historical categories',
            subtitle: 'Where your money has been going',
            showCardIcon: false,
          ),
          if (topCategory.isNotEmpty) ...[
            const SizedBox(height: 16),
            _buildTopCategory(context, topCategory),
          ],
          const SizedBox(height: 18),
          ...List.generate(_categoryBreakdown.length, (index) {
            final category = _categoryBreakdown[index];

            return Padding(
              padding: EdgeInsets.only(
                bottom: index == _categoryBreakdown.length - 1 ? 0 : 14,
              ),
              child: _buildCategoryRow(context, theme, category),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildTopCategory(BuildContext context, String category) {
    final color = _categoryColor(category);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
      decoration: BoxDecoration(
        color: color.withOpacity(0.07),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: color.withOpacity(0.13)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(_categoryIcon(category), color: color, size: 19),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Text(
              'Top category: $category',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          Icon(Icons.star_rounded, color: color, size: 19),
        ],
      ),
    );
  }

  Widget _buildCategoryRow(
    BuildContext context,
    ThemeData theme,
    Map<String, dynamic> category,
  ) {
    final name = (category['category'] ?? 'Other').toString();
    final amount = _double(category['amount']);
    final percentage = _double(category['percentage']).clamp(0, 100);
    final color = _categoryColor(name);

    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.30),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor.withOpacity(0.08)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.11),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(_categoryIcon(name), color: color, size: 19),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Text(
                  name,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                _money(amount),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 11),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: percentage / 100,
                    minHeight: 7,
                    backgroundColor: color.withOpacity(0.10),
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                width: 42,
                child: Text(
                  _percentage(percentage),
                  textAlign: TextAlign.right,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // INSIGHTS
  // ---------------------------------------------------------------------------

  Widget _buildInsightsSection(BuildContext context) {
    if (_historicalInsights.isEmpty) {
      return _card(
        context: context,
        child: _infoMessage(
          context,
          icon: Icons.lightbulb_outline_rounded,
          title: 'No historical observations yet',
          message:
              'As more spending data becomes available, PesaPulse will generate historical observations for you.',
          color: _analyticsTeal,
        ),
      );
    }

    return _card(
      context: context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeading(
            context,
            icon: Icons.lightbulb_rounded,
            title: 'Historical observations',
            subtitle: 'Patterns identified from your spending history',
            showCardIcon: false,
          ),
          const SizedBox(height: 18),
          ...List.generate(_historicalInsights.length, (index) {
            final insight = _historicalInsights[index];

            return Padding(
              padding: EdgeInsets.only(
                bottom: index == _historicalInsights.length - 1 ? 0 : 12,
              ),
              child: _buildInsightItem(context, insight),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildInsightItem(BuildContext context, Map<String, dynamic> insight) {
    final theme = Theme.of(context);

    final priority = (insight['priority'] ?? 'low').toString().toLowerCase();

    final color = _insightPriorityColor(priority);

    final title = (insight['title'] ?? 'Historical insight').toString();

    final message = (insight['message'] ?? '').toString();

    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.30),
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: theme.dividerColor.withOpacity(0.08)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color.withOpacity(0.11),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(Icons.lightbulb_rounded, color: color, size: 21),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
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
                    _buildPriorityPill(context, priority, color),
                  ],
                ),
                if (message.isNotEmpty) ...[
                  const SizedBox(height: 7),
                  Text(
                    message,
                    style: theme.textTheme.bodySmall?.copyWith(
                      height: 1.45,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _insightPriorityColor(String priority) {
    switch (priority) {
      case 'high':
        return Colors.red;

      case 'medium':
        return Colors.orange;

      case 'low':
      default:
        return _analyticsTeal;
    }
  }

  Widget _buildPriorityPill(
    BuildContext context,
    String priority,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Text(
        priority.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 8.5,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // DATA QUALITY
  // ---------------------------------------------------------------------------

  Widget _buildDataQuality(BuildContext context) {
    final theme = Theme.of(context);

    final monthsAvailable = _int(_dataQuality['months_available']);

    final monthsWithSpending = _int(_dataQuality['months_with_spending']);

    final monthsWithBudget = _int(_dataQuality['months_with_budget']);

    final canAnalyze =
        _dataQuality['can_analyze_trend'] == true ||
        _dataQuality['can_analyze_trend']?.toString() == '1';

    final isCurrentMonthPartial =
        _dataQuality['is_current_month_partial'] == true ||
        _dataQuality['is_current_month_partial']?.toString() == '1';

    return _card(
      context: context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeading(
            context,
            icon: Icons.verified_rounded,
            title: 'Data quality',
            subtitle: 'Coverage behind these insights',
            showCardIcon: false,
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
            decoration: BoxDecoration(
              color: canAnalyze
                  ? Colors.green.withOpacity(0.07)
                  : Colors.orange.withOpacity(0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: canAnalyze
                    ? Colors.green.withOpacity(0.14)
                    : Colors.orange.withOpacity(0.14),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  canAnalyze ? Icons.check_circle_rounded : Icons.info_rounded,
                  color: canAnalyze ? Colors.green : Colors.orange,
                  size: 20,
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: Text(
                    canAnalyze
                        ? 'Trend analysis available'
                        : 'More historical data is recommended',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _buildQualityRow(
            context,
            label: 'Months analyzed',
            value: '$monthsAvailable',
            icon: Icons.calendar_view_month_rounded,
          ),
          _buildQualityDivider(context),
          _buildQualityRow(
            context,
            label: 'Months with spending',
            value: '$monthsWithSpending',
            icon: Icons.payments_outlined,
          ),
          _buildQualityDivider(context),
          _buildQualityRow(
            context,
            label: 'Months with budget',
            value: '$monthsWithBudget',
            icon: Icons.account_balance_wallet_outlined,
          ),
          if (isCurrentMonthPartial) ...[
            _buildQualityDivider(context),
            _buildQualityRow(
              context,
              label: 'Current month',
              value: 'Partial',
              icon: Icons.timelapse_rounded,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildQualityRow(
    BuildContext context, {
    required String label,
    required String value,
    required IconData icon,
  }) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Icon(icon, color: theme.colorScheme.onSurfaceVariant, size: 18),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        Text(
          value,
          style: theme.textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }

  Widget _buildQualityDivider(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 11),
      child: Divider(
        height: 1,
        color: Theme.of(context).dividerColor.withOpacity(0.10),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // SHARED UI
  // ---------------------------------------------------------------------------

  Widget _buildSectionHeading(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    bool showCardIcon = true,
  }) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showCardIcon)
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: _analyticsTeal.withOpacity(0.10),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(icon, color: _analyticsTeal, size: 21),
          ),
        if (showCardIcon) const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.2,
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
    );
  }

  Widget _card({
    required BuildContext context,
    required Widget child,
    double? padding,
  }) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(padding ?? ResponsiveHelper.cardPadding(context)),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: theme.dividerColor.withOpacity(0.08)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.035),
            blurRadius: 20,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _infoMessage(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String message,
    required Color color,
  }) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: color.withOpacity(0.12)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.10),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  message,
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
}
