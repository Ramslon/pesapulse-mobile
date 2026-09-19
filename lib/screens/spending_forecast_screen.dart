import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../services/api_services.dart';
import '../utils/responsive_helper.dart';

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

  Color _trendColor(String direction, ColorScheme scheme) {
    switch (direction) {
      case 'increasing':
        return scheme.error;
      case 'decreasing':
        return Colors.green;
      case 'stable':
        return scheme.primary;
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
        return scheme.primary;
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

  Widget _sectionTitle(BuildContext context, String title, {String? subtitle}) {
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.only(bottom: ResponsiveHelper.spacing(context)),
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
                color: theme.colorScheme.onSurface.withOpacity(.68),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildHero(BuildContext context, Map<String, dynamic> period) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final historicalMonths = _toInt(period['historical_months']);

    final forecastMonths = _toInt(period['forecast_months']);

    return Card(
      elevation: 0,
      color: scheme.primaryContainer.withOpacity(.35),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(
          ResponsiveHelper.useCompactLayout(context) ? 18 : 22,
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(ResponsiveHelper.cardPadding(context)),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: EdgeInsets.all(
                ResponsiveHelper.useCompactLayout(context) ? 11 : 14,
              ),
              decoration: BoxDecoration(
                color: scheme.primary.withOpacity(.12),
                borderRadius: BorderRadius.circular(
                  ResponsiveHelper.useCompactLayout(context) ? 13 : 16,
                ),
              ),
              child: Icon(
                Icons.auto_graph_rounded,
                color: scheme.primary,
                size: ResponsiveHelper.useCompactLayout(context) ? 24 : 30,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Spending Forecast',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Use your historical spending patterns to understand what may happen next.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurface.withOpacity(.72),
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      Chip(
                        avatar: const Icon(Icons.history_rounded, size: 17),
                        label: Text('$historicalMonths months history'),
                      ),
                      Chip(
                        avatar: const Icon(
                          Icons.online_prediction_rounded,
                          size: 17,
                        ),
                        label: Text('$forecastMonths months forecast'),
                      ),
                      const Chip(
                        avatar: Icon(Icons.workspace_premium_rounded, size: 17),
                        label: Text('Premium'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

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

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = ResponsiveHelper.useCompactLayout(context);

        // Dynamically adjust columns
        final crossAxisCount = compact
            ? 2
            : constraints.maxWidth >= 1200
            ? 4
            : constraints.maxWidth >= 800
            ? 3
            : 2;

        final spacing = ResponsiveHelper.spacing(context);

        // Dynamically adjust aspect ratio
        final childAspectRatio = compact
            ? 1.3
            : constraints.maxWidth >= 1200
            ? 2.2
            : constraints.maxWidth >= 800
            ? 1.8
            : 1.5;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: items.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: spacing,
            mainAxisSpacing: spacing,
            childAspectRatio: childAspectRatio,
          ),
          itemBuilder: (context, index) {
            final item = items[index];

            return Card(
              elevation: 0,
              child: Padding(
                padding: EdgeInsets.all(ResponsiveHelper.cardPadding(context)),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(item.$3, color: theme.colorScheme.primary),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.$1,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(.65),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item.$2,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildHistoryChart(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    if (_history.isEmpty) {
      return const SizedBox.shrink();
    }

    final spots = <FlSpot>[];

    for (var index = 0; index < _history.length; index++) {
      spots.add(FlSpot(index.toDouble(), _toDouble(_history[index]['spent'])));
    }

    final maxValue = _history.fold<double>(0, (max, item) {
      return math.max(max, _toDouble(item['spent']));
    });

    final maxY = maxValue <= 0 ? 1.0 : maxValue * 1.25;

    return Card(
      elevation: 0,
      child: Padding(
        padding: EdgeInsets.all(ResponsiveHelper.cardPadding(context)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Historical spending',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Monthly spending across the selected historical period.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurface.withOpacity(.65),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: ResponsiveHelper.isLandscape(context) ? 220 : 260,
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
                              color: scheme.onSurface.withOpacity(.55),
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
                                color: scheme.onSurface.withOpacity(.6),
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
                      color: scheme.primary,
                      dotData: const FlDotData(show: true),
                      belowBarData: BarAreaData(
                        show: true,
                        color: scheme.primary.withOpacity(.08),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrendCard(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final trend = _data['trend'] as Map<String, dynamic>? ?? {};
    final direction = trend['direction']?.toString() ?? 'insufficient_data';
    final slope = _toDouble(trend['slope']);

    final color = _trendColor(direction, scheme);

    return Card(
      elevation: 0,
      child: Padding(
        padding: EdgeInsets.all(ResponsiveHelper.cardPadding(context)),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              backgroundColor: color.withOpacity(.12),
              foregroundColor: color,
              child: Icon(_trendIcon(direction)),
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
                  Text(
                    'Trend slope: ${slope.toStringAsFixed(2)}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurface.withOpacity(.58),
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

  Widget _buildForecastSection(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final forecast = _data['forecast'] as Map<String, dynamic>? ?? {};

    final monthly = _forecast;

    final canForecast = _data['data_quality']?['can_forecast'] == true;

    if (!canForecast || monthly.isEmpty) {
      return Card(
        elevation: 0,
        child: Padding(
          padding: EdgeInsets.all(ResponsiveHelper.cardPadding(context)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.lock_clock_outlined, color: scheme.primary),
                  const SizedBox(width: 10),
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
              const SizedBox(height: 10),
              Text(
                _data['confidence']?['message']?.toString() ??
                    'There is not enough historical spending data to produce a reliable forecast.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurface.withOpacity(.68),
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHighest.withOpacity(.55),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.info_outline_rounded, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'PesaPulse will start forecasting once enough monthly spending history is available.',
                        style: theme.textTheme.bodySmall?.copyWith(height: 1.4),
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

    final totalProjected = _toDouble(forecast['total_projected_spending']);

    final averageProjected = _toDouble(
      forecast['average_projected_monthly_spending'],
    );

    final highestMonth =
        forecast['highest_projected_month'] as Map<String, dynamic>?;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Card(
          elevation: 0,
          child: Padding(
            padding: EdgeInsets.all(ResponsiveHelper.cardPadding(context)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Projected spending',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final compact = ResponsiveHelper.useCompactLayout(context);

                    final items = [
                      (
                        'Total projected',
                        _money(totalProjected),
                        Icons.summarize_outlined,
                      ),
                      (
                        'Average per month',
                        _money(averageProjected),
                        Icons.calendar_view_month_outlined,
                      ),
                      (
                        'Highest projected month',
                        highestMonth == null
                            ? '—'
                            : _monthLongLabel(
                                highestMonth['month']?.toString() ?? '',
                              ),
                        Icons.arrow_upward_rounded,
                      ),
                    ];

                    if (compact || constraints.maxWidth < 850) {
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
                          if (i < items.length - 1) const SizedBox(width: 16),
                        ],
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ],
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
        Icon(icon, color: theme.colorScheme.primary, size: 21),
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

  Widget _buildConfidenceCard(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final confidence = _data['confidence'] as Map<String, dynamic>? ?? {};

    final level = confidence['level']?.toString() ?? 'insufficient_data';

    final message =
        confidence['message']?.toString() ??
        'There is not enough historical spending data to produce a reliable forecast.';

    final color = _confidenceColor(level, scheme);

    return Card(
      elevation: 0,
      child: Padding(
        padding: EdgeInsets.all(ResponsiveHelper.cardPadding(context)),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              backgroundColor: color.withOpacity(.12),
              foregroundColor: color,
              child: Icon(_confidenceIcon(level)),
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
      ),
    );
  }

  Widget _buildCategories(BuildContext context) {
    if (_categories.isEmpty) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Card(
      elevation: 0,
      child: Padding(
        padding: EdgeInsets.all(ResponsiveHelper.cardPadding(context)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Category contribution',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'How your historical spending is distributed across categories.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurface.withOpacity(.65),
              ),
            ),
            const SizedBox(height: 18),
            for (var index = 0; index < _categories.length; index++) ...[
              if (index > 0) const SizedBox(height: 16),
              _buildCategoryRow(context, _categories[index]),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryRow(
    BuildContext context,
    Map<String, dynamic> category,
  ) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final name = category['category']?.toString() ?? 'Other';

    final amount = _toDouble(category['historical_spending']);

    final percentage = _toDouble(category['percentage']);

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                name,
                style: theme.textTheme.bodyMedium?.copyWith(
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
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(99),
          child: LinearProgressIndicator(
            value: (percentage / 100).clamp(0, 1),
            minHeight: 8,
            backgroundColor: scheme.surfaceContainerHighest,
          ),
        ),
        const SizedBox(height: 5),
        Align(
          alignment: Alignment.centerRight,
          child: Text(
            '${percentage.toStringAsFixed(1)}%',
            style: theme.textTheme.labelSmall?.copyWith(
              color: scheme.onSurface.withOpacity(.58),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRecommendations(BuildContext context) {
    if (_recommendations.isEmpty) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Card(
      elevation: 0,
      child: Padding(
        padding: EdgeInsets.all(ResponsiveHelper.cardPadding(context)),
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
        Icon(icon, color: theme.colorScheme.primary, size: 22),
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
                  Text(
                    priority.toUpperCase(),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.primary,
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

  Widget _buildDataQuality(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final quality = _data['data_quality'] as Map<String, dynamic>? ?? {};

    final monthsAvailable = _toInt(quality['months_available']);

    final monthsWithSpending = _toInt(quality['months_with_spending']);

    final canForecast = quality['can_forecast'] == true;

    final currentMonthPartial = quality['current_month_is_partial'] == true;

    final partialMonthNote = quality['partial_month_note']?.toString();

    final basis = quality['forecast_basis']?.toString() ?? '';

    return Card(
      elevation: 0,
      child: Padding(
        padding: EdgeInsets.all(ResponsiveHelper.cardPadding(context)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.fact_check_outlined, color: scheme.primary),
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
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: scheme.tertiaryContainer.withOpacity(.4),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.calendar_today_outlined,
                      size: 20,
                      color: scheme.onTertiaryContainer,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        partialMonthNote,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onTertiaryContainer,
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
      ),
    );
  }

  Widget _buildQualityRow(BuildContext context, String label, String value) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
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

  Widget _buildErrorState(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: Padding(
          padding: EdgeInsets.all(ResponsiveHelper.cardPadding(context)),
          child: Card(
            elevation: 0,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.cloud_off_rounded, size: 46, color: scheme.error),
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
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    final period = _data['period'] as Map<String, dynamic>? ?? {};

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
                ResponsiveHelper.spacing(context),
                ResponsiveHelper.horizontalPadding(context),
                ResponsiveHelper.sectionSpacing(context) * 2,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildHero(context, period),

                  SizedBox(height: ResponsiveHelper.sectionSpacing(context)),

                  _sectionTitle(
                    context,
                    'Historical overview',
                    subtitle:
                        'Your recent spending activity before forecasting.',
                  ),

                  _buildSummaryGrid(context),

                  SizedBox(height: ResponsiveHelper.sectionSpacing(context)),

                  _buildHistoryChart(context),

                  SizedBox(height: ResponsiveHelper.sectionSpacing(context)),

                  _sectionTitle(context, 'Spending trend'),

                  _buildTrendCard(context),

                  SizedBox(height: ResponsiveHelper.sectionSpacing(context)),

                  _sectionTitle(
                    context,
                    'Future outlook',
                    subtitle:
                        'Projected spending based on your historical pattern.',
                  ),

                  _buildForecastSection(context),

                  SizedBox(height: ResponsiveHelper.sectionSpacing(context)),

                  _buildConfidenceCard(context),

                  if (_categories.isNotEmpty) ...[
                    SizedBox(height: ResponsiveHelper.sectionSpacing(context)),
                    _sectionTitle(context, 'Category contribution'),
                    _buildCategories(context),
                  ],

                  if (_recommendations.isNotEmpty) ...[
                    SizedBox(height: ResponsiveHelper.sectionSpacing(context)),
                    _buildRecommendations(context),
                  ],

                  SizedBox(height: ResponsiveHelper.sectionSpacing(context)),

                  _buildDataQuality(context),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Spending Forecast'),
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
