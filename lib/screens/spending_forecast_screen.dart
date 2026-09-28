import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../services/api_services.dart';
import '../utils/responsive_helper.dart';

import '../widgets/app/adaptive_app_bar.dart';
import '../widgets/app/app_scaffold.dart';

const Color _premiumPurple = Color(0xFF6D3FD9);
const Color _premiumPurpleDark = Color(0xFF34205F);
const Color _analyticsTeal = Color(0xFF14B8A6);

class SpendingForecastScreen extends StatefulWidget {
  const SpendingForecastScreen({super.key});

  @override
  State<SpendingForecastScreen> createState() => _SpendingForecastScreenState();
}

class _SpendingForecastScreenState extends State<SpendingForecastScreen> {
  bool _isLoading = true;
  bool _isRefreshing = false;

  String? _errorMessage;

  Map<String, dynamic> _data = {};

  final NumberFormat _currencyFormatter = NumberFormat('#,##0.00');

  @override
  void initState() {
    super.initState();
    _loadForecast();
  }

  // ============================================================
  // DATA
  // ============================================================

  Future<void> _loadForecast({bool refresh = false}) async {
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
      final response = await ApiService.getSpendingForecast(
        months: 6,
        forecastMonths: 3,
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
    }
  }

  String _cleanError(Object error) {
    final message = error.toString();

    if (message.startsWith('Exception: ')) {
      return message.substring('Exception: '.length);
    }

    return message;
  }

  double _toDouble(dynamic value) {
    if (value == null) return 0;

    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(value.toString()) ?? 0;
  }

  int _toInt(dynamic value) {
    if (value == null) return 0;

    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(value.toString()) ?? 0;
  }

  String _money(double value) {
    return 'KES ${_currencyFormatter.format(value)}';
  }

  String _monthLabel(String value) {
    final parts = value.split('-');

    if (parts.length != 2) {
      return value;
    }

    final year = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);

    if (year == null || month == null) {
      return value;
    }

    try {
      return DateFormat('MMM').format(DateTime(year, month));
    } catch (_) {
      return value;
    }
  }

  String _monthLongLabel(String value) {
    final parts = value.split('-');

    if (parts.length != 2) {
      return value;
    }

    final year = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);

    if (year == null || month == null) {
      return value;
    }

    try {
      return DateFormat('MMMM yyyy').format(DateTime(year, month));
    } catch (_) {
      return value;
    }
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

  List<Map<String, dynamic>> get _history {
    final value = _data['history']?['monthly'];

    if (value is! List) {
      return [];
    }

    return value
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  List<Map<String, dynamic>> get _forecast {
    final value = _data['forecast']?['monthly'];

    if (value is! List) {
      return [];
    }

    return value
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  List<Map<String, dynamic>> get _categories {
    final value = _data['categories']?['breakdown'];

    if (value is! List) {
      return [];
    }

    return value
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  List<Map<String, dynamic>> get _recommendations {
    final value = _data['recommendations'];

    if (value is! List) {
      return [];
    }

    return value
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  // ============================================================
  // COLORS / STATES
  // ============================================================

  Color _trendColor(String direction, ColorScheme scheme) {
    switch (direction) {
      case 'increasing':
        return Colors.red;

      case 'decreasing':
        return Colors.green;

      case 'stable':
        return _analyticsTeal;

      default:
        return scheme.outline;
    }
  }

  IconData _trendIcon(String direction) {
    switch (direction) {
      case 'increasing':
        return Icons.trending_up_rounded;
      case 'decreasing':
        return Icons.trending_down_rounded;
      case 'stable':
        return Icons.trending_flat_rounded;
      default:
        return Icons.insights_outlined;
    }
  }

  String _trendTitle(String direction) {
    switch (direction) {
      case 'increasing':
        return 'Spending is increasing';
      case 'decreasing':
        return 'Spending is decreasing';
      case 'stable':
        return 'Spending is relatively stable';
      default:
        return 'Trend needs more data';
    }
  }

  String _trendDescription(String direction) {
    switch (direction) {
      case 'increasing':
        return 'Your historical spending is showing an upward pattern.';
      case 'decreasing':
        return 'Your historical spending is showing a downward pattern.';
      case 'stable':
        return 'Your recent spending history does not show a strong directional change.';
      default:
        return 'PesaPulse needs more spending months before it can determine a reliable trend.';
    }
  }

  Color _confidenceColor(String level, ColorScheme scheme) {
    switch (level) {
      case 'high':
        return Colors.green;
      case 'medium':
        return _analyticsTeal;
      case 'low':
        return Colors.orange;
      default:
        return scheme.outline;
    }
  }

  IconData _confidenceIcon(String level) {
    switch (level) {
      case 'high':
        return Icons.verified_rounded;
      case 'medium':
        return Icons.analytics_outlined;
      case 'low':
        return Icons.warning_amber_rounded;
      default:
        return Icons.info_outline_rounded;
    }
  }

  String _confidenceTitle(String level) {
    switch (level) {
      case 'high':
        return 'High confidence';
      case 'medium':
        return 'Medium confidence';
      case 'low':
        return 'Low confidence';
      default:
        return 'Not enough data';
    }
  }

  // ============================================================
  // COMMON UI
  // ============================================================

  Widget _sectionTitle(
    BuildContext context,
    String title, {
    String? subtitle,
    IconData? icon,
  }) {
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.only(bottom: ResponsiveHelper.spacing(context)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) ...[
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: _analyticsTeal.withOpacity(.10),
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(icon, size: 20, color: _analyticsTeal),
            ),
            const SizedBox(width: 11),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(.64),
                      height: 1.35,
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

  Widget _card({
    required BuildContext context,
    required Widget child,
    EdgeInsets? padding,
  }) {
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      child: Padding(
        padding:
            padding ?? EdgeInsets.all(ResponsiveHelper.cardPadding(context)),
        child: child,
      ),
    );
  }

  // ============================================================
  // HERO
  // ============================================================

  Widget _buildHero(BuildContext context, Map<String, dynamic> period) {
    final theme = Theme.of(context);

    final historicalMonths = _toInt(period['historical_months']);

    final forecastMonths = _toInt(period['forecast_months']);

    final compact = ResponsiveHelper.useCompactLayout(context);

    final dense = ResponsiveHelper.useDenseVerticalLayout(context);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(
        compact ? 18 : ResponsiveHelper.cardPadding(context) + 2,
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
            blurRadius: 28,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: compact ? 46 : 56,
            height: compact ? 46 : 56,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(.10),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.auto_graph_rounded,
              color: Colors.white,
              size: compact ? 24 : 29,
            ),
          ),

          SizedBox(width: compact ? 12 : 17),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        'Spending Forecast',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          height: 1.15,
                        ),
                      ),
                    ),

                    if (!compact) ...[
                      const SizedBox(width: 12),
                      _premiumBadge(),
                    ],
                  ],
                ),

                if (compact) ...[const SizedBox(height: 8), _premiumBadge()],

                SizedBox(height: dense ? 9 : 12),

                Text(
                  'Use your historical spending patterns to understand what may happen next.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.white.withOpacity(.74),
                    height: 1.45,
                  ),
                ),

                SizedBox(height: dense ? 12 : 16),

                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _heroChip(
                      icon: Icons.history_rounded,
                      label: '$historicalMonths months history',
                    ),
                    _heroChip(
                      icon: Icons.online_prediction_rounded,
                      label: '$forecastMonths months forecast',
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

  Widget _premiumBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(.10),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(.10)),
      ),
      child: const Text(
        'PREMIUM',
        style: TextStyle(
          color: Colors.white,
          fontSize: 9,
          fontWeight: FontWeight.w900,
          letterSpacing: .7,
        ),
      ),
    );
  }

  Widget _heroChip({required IconData icon, required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(.18),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(.08)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.white.withOpacity(.90)),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // SUMMARY
  // ============================================================

  Widget _buildSummaryGrid(BuildContext context) {
    final theme = Theme.of(context);

    final history = _data['history'] as Map<String, dynamic>? ?? {};

    final totalSpending = _toDouble(history['total_spending']);
    final averageMonthly = _toDouble(history['average_monthly_spending']);
    final averageActiveMonth = _toDouble(
      history['average_active_month_spending'],
    );
    final monthsAvailable = _toInt(history['months_available']);
    final monthsWithSpending = _toInt(history['months_with_spending']);

    final items = [
      ('Total spending', _money(totalSpending), Icons.payments_outlined),
      (
        'Average monthly',
        _money(averageMonthly),
        Icons.calendar_month_outlined,
      ),
      (
        'Active-month average',
        _money(averageActiveMonth),
        Icons.show_chart_rounded,
      ),
      (
        'Spending months',
        '$monthsWithSpending / $monthsAvailable',
        Icons.date_range_rounded,
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

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        crossAxisSpacing: spacing,
        mainAxisSpacing: spacing,
        childAspectRatio: _summaryCardAspectRatio(context),
      ),
      itemBuilder: (context, index) {
        final item = items[index];

        return _card(
          context: context,
          child: _buildCardContent(context, theme, item),
        );
      },
    );
  }

  double _summaryCardAspectRatio(BuildContext context) {
    if (ResponsiveHelper.isMobilePortrait(context)) {
      return 1.25;
    }

    if (ResponsiveHelper.isMobileLandscape(context)) {
      return 1.55;
    }

    if (ResponsiveHelper.isTabletPortrait(context)) {
      return 1.45;
    }

    if (ResponsiveHelper.isTabletLandscape(context)) {
      return 1.55;
    }

    return 1.65;
  }

  Widget _buildCardContent(
    BuildContext context,
    ThemeData theme,
    (String, String, IconData) item,
  ) {
    final compact = ResponsiveHelper.useCompactLayout(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: compact ? 32 : 38,
          height: compact ? 32 : 38,
          decoration: BoxDecoration(
            color: _analyticsTeal.withOpacity(.10),
            borderRadius: BorderRadius.circular(compact ? 9 : 11),
          ),
          child: Icon(item.$3, color: _analyticsTeal, size: compact ? 18 : 20),
        ),
        SizedBox(height: compact ? 8 : 12),
        Text(
          item.$1,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.bodySmall?.copyWith(
            fontSize: compact ? 11 : 12,
            color: theme.colorScheme.onSurface.withOpacity(.62),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          item.$2,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.titleMedium?.copyWith(
            fontSize: compact ? 13 : 15,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // HISTORY CHART
  // ============================================================

  Widget _buildHistoryChart(BuildContext context) {
    if (_history.isEmpty) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final spots = <FlSpot>[];

    for (var index = 0; index < _history.length; index++) {
      spots.add(FlSpot(index.toDouble(), _toDouble(_history[index]['spent'])));
    }

    final maxValue = _history.fold<double>(
      0,
      (max, item) => math.max(max, _toDouble(item['spent'])),
    );

    final maxY = maxValue <= 0 ? 1.0 : maxValue * 1.25;

    final chartHeight = ResponsiveHelper.useDenseVerticalLayout(context)
        ? 230.0
        : ResponsiveHelper.isDesktop(context)
        ? 300.0
        : 270.0;

    return _card(
      context: context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Historical spending',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            'Monthly spending across the selected historical period.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: scheme.onSurface.withOpacity(.62),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: chartHeight,
            child: LineChart(
              LineChartData(
                minY: 0,
                maxY: maxY,
                minX: 0,
                maxX: (_history.length - 1).toDouble(),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: maxY <= 4 ? 1 : maxY / 4,
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
                      getTitlesWidget: (value, meta) {
                        return Text(
                          value >= 1000
                              ? '${(value / 1000).toStringAsFixed(1)}k'
                              : value.toStringAsFixed(0),
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: scheme.onSurface.withOpacity(.52),
                          ),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        final index = value.round();

                        if (index < 0 || index >= _history.length) {
                          return const SizedBox.shrink();
                        }

                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            _monthLabel(
                              _history[index]['month']?.toString() ?? '',
                            ),
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: scheme.onSurface.withOpacity(.58),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    barWidth: 3,
                    color: _analyticsTeal,
                    dotData: const FlDotData(show: true),
                    belowBarData: BarAreaData(
                      show: true,
                      color: _analyticsTeal.withOpacity(.10),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // TREND
  // ============================================================

  Widget _buildTrendCard(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final trend = _data['trend'] as Map<String, dynamic>? ?? {};

    final direction = trend['direction']?.toString() ?? 'insufficient_data';

    final slope = _toDouble(trend['slope']);

    final color = _trendColor(direction, scheme);

    return _card(
      context: context,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withOpacity(.10),
              shape: BoxShape.circle,
            ),
            child: Icon(_trendIcon(direction), color: color),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _trendTitle(direction),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  _trendDescription(direction),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurface.withOpacity(.68),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Trend slope: ${slope.toStringAsFixed(2)}',
                    style: theme.textTheme.labelSmall?.copyWith(
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

  // ============================================================
  // FORECAST
  // ============================================================

  Widget _buildForecastSection(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final forecast = _data['forecast'] as Map<String, dynamic>? ?? {};

    final monthly = _forecast;

    final canForecast = _data['data_quality']?['can_forecast'] == true;

    if (!canForecast || monthly.isEmpty) {
      return _card(
        context: context,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: _analyticsTeal.withOpacity(.10),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.lock_clock_outlined,
                    color: _analyticsTeal,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Forecast not available yet',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              _data['confidence']?['message']?.toString() ??
                  'There is not enough historical spending data to produce a reliable forecast.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: scheme.onSurface.withOpacity(.68),
                height: 1.45,
              ),
            ),
            const SizedBox(height: 14),
            _infoBanner(
              context,
              'PesaPulse will start forecasting once enough monthly spending history is available.',
            ),
          ],
        ),
      );
    }

    final totalProjected = _toDouble(forecast['total_projected_spending']);

    final averageProjected = _toDouble(
      forecast['average_projected_monthly_spending'],
    );

    final highestMonth =
        forecast['highest_projected_month'] as Map<String, dynamic>?;

    final items = [
      ('Total projected', _money(totalProjected), Icons.summarize_outlined),
      (
        'Average per month',
        _money(averageProjected),
        Icons.calendar_view_month_outlined,
      ),
      (
        'Highest projected month',
        highestMonth == null
            ? '—'
            : _monthLongLabel(highestMonth['month']?.toString() ?? ''),
        Icons.arrow_upward_rounded,
      ),
    ];

    return _card(
      context: context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Projected spending',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final compact = ResponsiveHelper.useCompactLayout(context);

              if (compact ||
                  ResponsiveHelper.isMobileLandscape(context) ||
                  constraints.maxWidth < 700) {
                return Column(
                  children: [
                    for (var i = 0; i < items.length; i++) ...[
                      if (i > 0) const Divider(height: 24),
                      _buildMetricRow(
                        context,
                        label: items[i].$1,
                        value: items[i].$2,
                        icon: items[i].$3,
                      ),
                    ],
                  ],
                );
              }

              return Row(
                children: [
                  for (var i = 0; i < items.length; i++) ...[
                    Expanded(
                      child: _buildMetricRow(
                        context,
                        label: items[i].$1,
                        value: items[i].$2,
                        icon: items[i].$3,
                      ),
                    ),
                    if (i < items.length - 1)
                      SizedBox(width: ResponsiveHelper.spacing(context)),
                  ],
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMetricRow(
    BuildContext context, {
    required String label,
    required String value,
    required IconData icon,
  }) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: _analyticsTeal.withOpacity(.10),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: _analyticsTeal, size: 19),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(.62),
                ),
              ),
              const SizedBox(height: 3),
              Text(
                value,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ============================================================
  // CONFIDENCE
  // ============================================================

  Widget _buildConfidenceCard(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final confidence = _data['confidence'] as Map<String, dynamic>? ?? {};

    final level = confidence['level']?.toString() ?? 'insufficient_data';

    final message =
        confidence['message']?.toString() ??
        'There is not enough historical spending data to produce a reliable forecast.';

    final color = _confidenceColor(level, scheme);

    return _card(
      context: context,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withOpacity(.10),
              shape: BoxShape.circle,
            ),
            child: Icon(_confidenceIcon(level), color: color),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _confidenceTitle(level),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  message,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurface.withOpacity(.68),
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
  // CATEGORIES
  // ============================================================

  Widget _buildCategories(BuildContext context) {
    if (_categories.isEmpty) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return _card(
      context: context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Category contribution',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            'How your historical spending is distributed across categories.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: scheme.onSurface.withOpacity(.62),
            ),
          ),
          const SizedBox(height: 18),
          for (var index = 0; index < _categories.length; index++) ...[
            if (index > 0) SizedBox(height: ResponsiveHelper.spacing(context)),
            _buildCategoryRow(context, _categories[index]),
          ],
        ],
      ),
    );
  }

  Widget _buildCategoryRow(BuildContext context, Map<String, dynamic> item) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final category = item['category']?.toString() ?? 'Other';
    final amount = _toDouble(item['amount']);

    final percentage = _toDouble(
      item['percentage'] ??
          item['percent'] ??
          item['share'] ??
          item['contribution'],
    );

    final color = _categoryColor(category);

    final displayPercentage = percentage > 1 ? percentage : percentage * 100;

    return Container(
      padding: EdgeInsets.all(ResponsiveHelper.cardPadding(context) * 0.75),
      decoration: BoxDecoration(
        color: color.withOpacity(0.045),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.10)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(_categoryIcon(category), color: color, size: 21),
              ),

              SizedBox(width: ResponsiveHelper.spacing(context) * 0.7),

              Expanded(
                child: Text(
                  category,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),

              const SizedBox(width: 8),

              Text(
                _money(amount),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),

          SizedBox(height: ResponsiveHelper.spacing(context) * 0.65),

          if (percentage > 0) ...[
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: (displayPercentage / 100).clamp(0.0, 1.0),
                      minHeight: 7,
                      backgroundColor: color.withOpacity(0.10),
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                    ),
                  ),
                ),

                const SizedBox(width: 10),

                Text(
                  '${displayPercentage.toStringAsFixed(1)}%',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ] else ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: 0,
                minHeight: 7,
                backgroundColor: scheme.onSurface.withOpacity(0.08),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ============================================================
  // RECOMMENDATIONS
  // ============================================================

  Widget _buildRecommendations(BuildContext context) {
    if (_recommendations.isEmpty) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);

    return _card(
      context: context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Recommendations',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          for (var index = 0; index < _recommendations.length; index++) ...[
            if (index > 0) const Divider(height: 24),
            _buildRecommendation(context, _recommendations[index]),
          ],
        ],
      ),
    );
  }

  Widget _buildRecommendation(
    BuildContext context,
    Map<String, dynamic> recommendation,
  ) {
    final theme = Theme.of(context);

    final title = recommendation['title']?.toString() ?? 'Recommendation';

    final message = recommendation['message']?.toString() ?? '';

    final priority = recommendation['priority']?.toString() ?? 'medium';

    final priorityColor = priority == 'medium' ? Colors.orange : _analyticsTeal;

    IconData icon;

    switch (recommendation['type']?.toString()) {
      case 'data':
        icon = Icons.data_usage_rounded;
        break;
      case 'category':
        icon = Icons.category_outlined;
        break;
      default:
        icon = Icons.lightbulb_outline_rounded;
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: _analyticsTeal.withOpacity(.10),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: _analyticsTeal, size: 20),
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
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    priority.toUpperCase(),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: priorityColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 5),
              Text(
                message,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(.68),
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ============================================================
  // DATA QUALITY
  // ============================================================

  Widget _buildDataQuality(BuildContext context) {
    final theme = Theme.of(context);

    final quality = _data['data_quality'] as Map<String, dynamic>? ?? {};

    final monthsAvailable = _toInt(quality['months_available']);

    final monthsWithSpending = _toInt(quality['months_with_spending']);

    final canForecast = quality['can_forecast'] == true;

    final currentMonthPartial = quality['current_month_is_partial'] == true;

    final partialMonthNote = quality['partial_month_note']?.toString();

    final basis = quality['forecast_basis']?.toString() ?? '';

    return _card(
      context: context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _analyticsTeal.withOpacity(.10),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: const Icon(
                  Icons.fact_check_outlined,
                  color: _analyticsTeal,
                  size: 21,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Data quality',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildQualityRow(context, 'Historical months', '$monthsAvailable'),
          _buildQualityRow(
            context,
            'Months with spending',
            '$monthsWithSpending',
          ),
          _buildQualityRow(
            context,
            'Forecast available',
            canForecast ? 'Yes' : 'Not yet',
          ),
          if (basis.isNotEmpty)
            _buildQualityRow(context, 'Forecast basis', basis),
          if (currentMonthPartial &&
              partialMonthNote != null &&
              partialMonthNote.isNotEmpty) ...[
            const SizedBox(height: 6),
            _infoBanner(
              context,
              partialMonthNote,
              icon: Icons.calendar_today_outlined,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildQualityRow(BuildContext context, String label, String value) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 11),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(.62),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // INFO / ERROR
  // ============================================================

  Widget _infoBanner(
    BuildContext context,
    String message, {
    IconData icon = Icons.info_outline_rounded,
  }) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _analyticsTeal.withOpacity(.07),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _analyticsTeal.withOpacity(.12)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: _analyticsTeal),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: theme.textTheme.bodySmall?.copyWith(height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: Padding(
          padding: EdgeInsets.all(ResponsiveHelper.cardPadding(context)),
          child: _card(
            context: context,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: scheme.error.withOpacity(.10),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.cloud_off_rounded,
                    size: 32,
                    color: scheme.error,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'Unable to load spending forecast',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _errorMessage ??
                      'Something went wrong while loading the forecast.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurface.withOpacity(.68),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 18),
                FilledButton.icon(
                  onPressed: () => _loadForecast(),
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Try Again'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // CONTENT
  // ============================================================

  Widget _buildContent(BuildContext context) {
    final period = _data['period'] as Map<String, dynamic>? ?? {};

    final sectionSpacing = ResponsiveHelper.sectionSpacing(context);

    return RefreshIndicator(
      onRefresh: () => _loadForecast(refresh: true),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: ResponsiveHelper.contentMaxWidth(context),
            ),
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                ResponsiveHelper.horizontalPadding(context),
                sectionSpacing,
                ResponsiveHelper.horizontalPadding(context),
                sectionSpacing * 2,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildHero(context, period),

                  SizedBox(height: sectionSpacing),

                  _sectionTitle(
                    context,
                    'Historical overview',
                    subtitle:
                        'Your recent spending activity before forecasting.',
                    icon: Icons.history_rounded,
                  ),

                  _buildSummaryGrid(context),

                  SizedBox(height: sectionSpacing),

                  _buildHistoryChart(context),

                  SizedBox(height: sectionSpacing),

                  _sectionTitle(
                    context,
                    'Spending trend',
                    icon: Icons.trending_up_rounded,
                  ),

                  _buildTrendCard(context),

                  SizedBox(height: sectionSpacing),

                  _sectionTitle(
                    context,
                    'Future outlook',
                    subtitle:
                        'Projected spending based on your historical pattern.',
                    icon: Icons.online_prediction_rounded,
                  ),

                  _buildForecastSection(context),

                  SizedBox(height: sectionSpacing),

                  _buildConfidenceCard(context),

                  if (_categories.isNotEmpty) ...[
                    SizedBox(height: sectionSpacing),
                    _sectionTitle(
                      context,
                      'Category contribution',
                      subtitle:
                          'See which categories have contributed most to your historical spending.',
                      icon: Icons.category_outlined,
                    ),
                    _buildCategories(context),
                  ],

                  if (_recommendations.isNotEmpty) ...[
                    SizedBox(height: sectionSpacing),
                    _sectionTitle(
                      context,
                      'Smart recommendations',
                      subtitle:
                          'Insights generated from your spending patterns.',
                      icon: Icons.lightbulb_outline_rounded,
                    ),
                    _buildRecommendations(context),
                  ],

                  SizedBox(height: sectionSpacing),

                  _buildDataQuality(context),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: AdaptiveAppBar(
        title: 'Spending Forecast',
        actions: [
          if (!_isLoading)
            IconButton(
              tooltip: 'Refresh forecast',
              onPressed: _isRefreshing
                  ? null
                  : () => _loadForecast(refresh: true),
              icon: _isRefreshing
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.refresh_rounded),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null && _data.isEmpty
          ? _buildErrorState(context)
          : _buildContent(context),
    );
  }
}
