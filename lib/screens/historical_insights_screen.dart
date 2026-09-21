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

  // ============================================================
  // LOAD
  // ============================================================

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

  // ============================================================
  // HELPERS
  // ============================================================

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

  String _percentage(dynamic value) {
    if (value == null) {
      return '—';
    }

    return '${_double(value).toStringAsFixed(1)}%';
  }

  String _monthLabel(String? value) {
    if (value == null || value.isEmpty) {
      return 'Unknown';
    }

    try {
      final parts = value.split('-');

      if (parts.length != 2) {
        return value;
      }

      final date = DateTime(int.parse(parts[0]), int.parse(parts[1]));

      return DateFormat('MMM yyyy').format(date);
    } catch (_) {
      return value;
    }
  }

  String _monthShortLabel(String? value) {
    if (value == null || value.isEmpty) {
      return '';
    }

    try {
      final parts = value.split('-');

      if (parts.length != 2) {
        return value;
      }

      final date = DateTime(int.parse(parts[0]), int.parse(parts[1]));

      return DateFormat('MMM').format(date);
    } catch (_) {
      return value;
    }
  }

  Map<String, dynamic> _map(dynamic value) {
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

  String _directionLabel(String direction) {
    switch (direction) {
      case 'increasing':
        return 'Spending Increasing';

      case 'decreasing':
        return 'Spending Decreasing';

      case 'stable':
        return 'Spending Stable';

      default:
        return 'Insufficient Data';
    }
  }

  Color _directionColor(BuildContext context, String direction) {
    switch (direction) {
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
    switch (direction) {
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

  // ============================================================
  // GETTERS
  // ============================================================

  Map<String, dynamic> get _summary {
    return _map(_data?['summary']);
  }

  Map<String, dynamic> get _trend {
    return _map(_data?['trend']);
  }

  Map<String, dynamic> get _categories {
    return _map(_data?['categories']);
  }

  Map<String, dynamic> get _dataQuality {
    return _map(_data?['data_quality']);
  }

  List<Map<String, dynamic>> get _monthly {
    return _list(_data?['monthly']);
  }

  List<Map<String, dynamic>> get _historicalInsights {
    return _list(_data?['historical_insights']);
  }

  List<Map<String, dynamic>> get _categoryBreakdown {
    return _list(_categories['breakdown']);
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppScaffold(
      appBar: const AdaptiveAppBar(title: 'Historical Insights'),
      body: _buildBody(theme),
    );
  }

  Widget _buildBody(ThemeData theme) {
    if (_isLoading && _data == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_data == null) {
      return _buildErrorState(theme);
    }

    final compact = ResponsiveHelper.useCompactLayout(context);

    final horizontalPadding = ResponsiveHelper.horizontalPadding(context);

    final contentMaxWidth = ResponsiveHelper.contentMaxWidth(context);

    return RefreshIndicator(
      onRefresh: () => _loadHistoricalInsights(refresh: true),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: EdgeInsets.fromLTRB(
          horizontalPadding,
          16,
          horizontalPadding,
          32,
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: contentMaxWidth),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHero(theme, compact),

                const SizedBox(height: 16),

                _buildPeriodSelector(theme, compact),

                const SizedBox(height: 16),

                _buildSummary(theme, compact),

                const SizedBox(height: 16),

                _buildTrendCard(theme, compact),

                const SizedBox(height: 16),

                _buildMonthlyHistory(theme, compact),

                const SizedBox(height: 16),

                _buildHighestLowest(theme, compact),

                const SizedBox(height: 16),

                _buildCategorySection(theme, compact),

                const SizedBox(height: 16),

                _buildInsightsSection(theme, compact),

                const SizedBox(height: 16),

                _buildDataQuality(theme, compact),

                if (_errorMessage != null) ...[
                  const SizedBox(height: 16),
                  _buildInlineError(theme),
                ],
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

  Widget _buildHero(ThemeData theme, bool compact) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(compact ? 20 : 24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
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
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: compact ? 46 : 52,
            height: compact ? 46 : 52,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(.10),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.history_rounded,
              color: Colors.white,
              size: 27,
            ),
          ),

          SizedBox(width: compact ? 12 : 16),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        'Historical Insights',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                    const SizedBox(width: 10),

                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(.10),
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: const Text(
                        'PREMIUM',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: .5,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                Text(
                  'Understand how your spending and budgeting behavior has changed over time.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.white.withOpacity(.72),
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
  // ============================================================
  // PERIOD SELECTOR
  // ============================================================

  Widget _buildPeriodSelector(ThemeData theme, bool compact) {
    return Card(
      elevation: 0,
      child: Padding(
        padding: EdgeInsets.all(compact ? 14 : 18),
        child: Row(
          children: [
            Icon(Icons.calendar_month_rounded, color: _analyticsTeal),

            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Historical period',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            DropdownButtonHideUnderline(
              child: DropdownButton<int>(
                value: _selectedMonths,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: _analyticsTeal,
                  fontWeight: FontWeight.w700,
                ),
                items: const [
                  DropdownMenuItem(value: 3, child: Text('3 months')),
                  DropdownMenuItem(value: 6, child: Text('6 months')),
                  DropdownMenuItem(value: 12, child: Text('12 months')),
                  DropdownMenuItem(value: 18, child: Text('18 months')),
                  DropdownMenuItem(value: 24, child: Text('24 months')),
                ],
                onChanged: _isRefreshing
                    ? null
                    : (value) async {
                        if (value == null || value == _selectedMonths) {
                          return;
                        }

                        setState(() {
                          _selectedMonths = value;
                        });

                        await _loadHistoricalInsights();
                      },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // SUMMARY
  // ============================================================

  Widget _buildSummary(ThemeData theme, bool compact) {
    final totalSpending = _summary['total_spending'];

    final averageMonthly = _summary['average_monthly_spending'];

    final totalBudgeted = _summary['total_budgeted'];

    final usage = _summary['budget_usage_percentage'];

    final activeMonths = _int(_summary['months_with_spending']);

    final cards = [
      _summaryMetric(
        theme,
        title: 'Total Spending',
        value: _money(totalSpending),
        icon: Icons.payments_rounded,
      ),
      _summaryMetric(
        theme,
        title: 'Avg. Monthly',
        value: _money(averageMonthly),
        icon: Icons.calculate_rounded,
      ),
      _summaryMetric(
        theme,
        title: 'Total Budgeted',
        value: _money(totalBudgeted),
        icon: Icons.account_balance_wallet_rounded,
      ),
      _summaryMetric(
        theme,
        title: 'Budget Usage',
        value: _percentage(usage),
        icon: Icons.pie_chart_outline_rounded,
      ),
    ];

    if (compact) {
      return Column(
        children: [
          Row(
            children: [
              Expanded(child: cards[0]),
              const SizedBox(width: 10),
              Expanded(child: cards[1]),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: cards[2]),
              const SizedBox(width: 10),
              Expanded(child: cards[3]),
            ],
          ),
          const SizedBox(height: 10),
          _summaryMetric(
            theme,
            title: 'Months With Spending',
            value: '$activeMonths',
            icon: Icons.event_available_rounded,
            fullWidth: true,
          ),
        ],
      );
    }

    return Column(
      children: [
        Row(
          children: [
            Expanded(child: cards[0]),
            const SizedBox(width: 12),
            Expanded(child: cards[1]),
            const SizedBox(width: 12),
            Expanded(child: cards[2]),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: cards[3]),
            const SizedBox(width: 12),
            Expanded(
              child: _summaryMetric(
                theme,
                title: 'Months With Spending',
                value: '$activeMonths',
                icon: Icons.event_available_rounded,
              ),
            ),
            const Expanded(child: SizedBox()),
          ],
        ),
      ],
    );
  }

  Widget _summaryMetric(
    ThemeData theme, {
    required String title,
    required String value,
    required IconData icon,
    bool fullWidth = false,
  }) {
    final scheme = theme.colorScheme;

    return SizedBox(
      width: fullWidth ? double.infinity : null,
      child: Card(
        elevation: 0,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _analyticsTeal.withOpacity(.10),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: _analyticsTeal, size: 21),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: scheme.onSurface.withOpacity(.60),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // TREND
  // ============================================================

  Widget _buildTrendCard(ThemeData theme, bool compact) {
    final direction = _trend['direction']?.toString() ?? 'insufficient_data';

    final changeAmount = _trend['change_amount'];

    final changePercentage = _trend['change_percentage'];

    final color = _directionColor(context, direction);

    return Card(
      elevation: 0,
      child: Padding(
        padding: EdgeInsets.all(compact ? 16 : 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(_directionIcon(direction), color: color),
                const SizedBox(width: 8),
                Text(
                  'Historical Spending Trend',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              decoration: BoxDecoration(
                color: color.withOpacity(.10),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(_directionIcon(direction), size: 18, color: color),
                  const SizedBox(width: 7),
                  Text(
                    _directionLabel(direction),
                    style: TextStyle(color: color, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            if (direction == 'insufficient_data')
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: _analyticsTeal.withOpacity(.07),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: _analyticsTeal.withOpacity(.12)),
                ),
                child: Text(
                  'More monthly spending history is needed before PesaPulse can identify a reliable historical trend.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(.68),
                    height: 1.45,
                  ),
                ),
              )
            else
              Row(
                children: [
                  Expanded(
                    child: _trendMetric(
                      theme,
                      title: 'Change amount',
                      value: _money(changeAmount),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _trendMetric(
                      theme,
                      title: 'Change percentage',
                      value: _percentage(changePercentage),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _trendMetric(
    ThemeData theme, {
    required String title,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withOpacity(.45),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(.60),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // MONTHLY CHART
  // ============================================================

  Widget _buildMonthlyHistory(ThemeData theme, bool compact) {
    final entries = _monthly
        .where((item) => _double(item['spent']) > 0)
        .toList();

    return Card(
      elevation: 0,
      child: Padding(
        padding: EdgeInsets.all(compact ? 14 : 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.show_chart_rounded,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Monthly Spending History',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 5),

            Text(
              'Spending recorded across the selected historical period.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(.62),
              ),
            ),

            const SizedBox(height: 18),

            SizedBox(
              height: compact ? 230 : 280,
              child: _monthly.isEmpty
                  ? Center(
                      child: Text(
                        'No historical data available.',
                        style: theme.textTheme.bodyMedium,
                      ),
                    )
                  : LineChart(_buildChartData(theme)),
            ),

            if (entries.isEmpty) ...[
              const SizedBox(height: 12),
              _infoMessage(
                theme,
                'No spending was recorded across the selected period.',
              ),
            ],
          ],
        ),
      ),
    );
  }

  LineChartData _buildChartData(ThemeData theme) {
    final spots = <FlSpot>[];

    for (int i = 0; i < _monthly.length; i++) {
      spots.add(FlSpot(i.toDouble(), _double(_monthly[i]['spent'])));
    }

    final values = _monthly.map((item) => _double(item['spent']));

    final maxValue = values.isEmpty
        ? 0.0
        : values.reduce((a, b) => a > b ? a : b);

    final maxY = maxValue <= 0 ? 100.0 : maxValue * 1.25;

    return LineChartData(
      minX: 0,
      maxX: _monthly.length > 1 ? (_monthly.length - 1).toDouble() : 1,
      minY: 0,
      maxY: maxY,

      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        horizontalInterval: maxY / 4,
      ),

      borderData: FlBorderData(show: false),

      titlesData: FlTitlesData(
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),

        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 52,
            getTitlesWidget: (value, meta) {
              return Text(
                value >= 1000
                    ? '${(value / 1000).toStringAsFixed(0)}k'
                    : value.toStringAsFixed(0),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(.55),
                ),
              );
            },
          ),
        ),

        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 28,
            interval: 1,
            getTitlesWidget: (value, meta) {
              final index = value.toInt();

              if (index < 0 || index >= _monthly.length) {
                return const SizedBox.shrink();
              }

              return Text(
                _monthShortLabel(_monthly[index]['month']?.toString()),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(.55),
                ),
              );
            },
          ),
        ),
      ),

      lineTouchData: LineTouchData(
        handleBuiltInTouches: true,
        touchTooltipData: LineTouchTooltipData(
          getTooltipItems: (touchedSpots) {
            return touchedSpots.map((spot) {
              final index = spot.x.toInt();

              final month = index >= 0 && index < _monthly.length
                  ? _monthly[index]['month']?.toString()
                  : null;

              return LineTooltipItem(
                '${_monthLabel(month)}\n'
                '${_money(spot.y)}',
                const TextStyle(fontWeight: FontWeight.bold),
              );
            }).toList();
          },
        ),
      ),

      lineBarsData: [
        LineChartBarData(
          spots: spots,
          isCurved: true,
          barWidth: 3,
          dotData: FlDotData(show: _monthly.length <= 12),
          belowBarData: BarAreaData(
            show: true,
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                _analyticsTeal.withOpacity(.25),
                _analyticsTeal.withOpacity(.05),
              ],
            ),
          ),
          color: _analyticsTeal, // teal line
        ),
      ],
    );
  }

  // ============================================================
  // HIGHEST / LOWEST
  // ============================================================

  Widget _buildHighestLowest(ThemeData theme, bool compact) {
    final highest = _map(_summary['highest_spending_month']);

    final lowest = _map(_summary['lowest_spending_month']);

    final highestCard = _periodCard(
      theme,
      title: 'Highest Spending Month',
      icon: Icons.arrow_upward_rounded,
      color: Colors.red,
      month: _monthLabel(highest['month']?.toString()),
      amount: _money(highest['amount']),
    );

    final lowestCard = _periodCard(
      theme,
      title: 'Lowest Spending Month',
      icon: Icons.arrow_downward_rounded,
      color: Colors.green,
      month: _monthLabel(lowest['month']?.toString()),
      amount: _money(lowest['amount']),
    );

    if (compact) {
      return Column(
        children: [highestCard, const SizedBox(height: 12), lowestCard],
      );
    }

    return Row(
      children: [
        Expanded(child: highestCard),
        const SizedBox(width: 12),
        Expanded(child: lowestCard),
      ],
    );
  }

  Widget _periodCard(
    ThemeData theme, {
    required String title,
    required IconData icon,
    required Color color,
    required String month,
    required String amount,
  }) {
    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withOpacity(.10),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(.60),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    month,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    amount,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: color,
                      fontWeight: FontWeight.w700,
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

  // ============================================================
  // CATEGORY
  // ============================================================

  Widget _buildCategorySection(ThemeData theme, bool compact) {
    if (_categoryBreakdown.isEmpty) {
      return _simpleSectionCard(
        theme,
        title: 'Historical Categories',
        icon: Icons.category_rounded,
        child: _infoMessage(
          theme,
          'No category spending history is available yet.',
        ),
      );
    }

    final topCategory = _categories['top_category']?.toString();

    return Card(
      elevation: 0,
      child: Padding(
        padding: EdgeInsets.all(compact ? 16 : 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.category_rounded, color: Colors.teal),
                const SizedBox(width: 8),
                Text(
                  'Historical Categories',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),

            if (topCategory != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: _analyticsTeal.withOpacity(.10),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Largest category: $topCategory',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: _analyticsTeal,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],

            const SizedBox(height: 16),

            ..._categoryBreakdown.map((item) {
              final category = item['category']?.toString() ?? 'Other';

              final amount = _double(item['amount']);

              final percentage = _double(item['percentage']);

              return Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            category,
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
                    const SizedBox(height: 7),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(99),
                      child: LinearProgressIndicator(
                        minHeight: 7,
                        value: (percentage / 100).clamp(0.0, 1.0),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        '${percentage.toStringAsFixed(1)}%',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(.55),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // INSIGHTS
  // ============================================================

  Widget _buildInsightsSection(ThemeData theme, bool compact) {
    if (_historicalInsights.isEmpty) {
      return _simpleSectionCard(
        theme,
        title: 'Historical Observations',
        icon: Icons.lightbulb_outline_rounded,
        child: _infoMessage(
          theme,
          'There are not enough historical observations yet.',
        ),
      );
    }

    return Card(
      elevation: 0,
      child: Padding(
        padding: EdgeInsets.all(compact ? 16 : 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.insights_rounded, color: _analyticsTeal),
                const SizedBox(width: 8),
                Text(
                  'Historical Observations',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            ..._historicalInsights.map((item) {
              final priority = item['priority']?.toString() ?? 'low';

              final color = priority == 'medium'
                  ? Colors.orange
                  : _analyticsTeal;

              return Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: _analyticsTeal.withOpacity(.08),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: color.withOpacity(.15)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: _analyticsTeal.withOpacity(.08),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        priority == 'medium'
                            ? Icons.priority_high_rounded
                            : Icons.insights_rounded,
                        size: 19,
                        color: color.withOpacity(.10),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item['title']?.toString() ?? 'Historical Insight',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            item['message']?.toString() ?? '',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface.withOpacity(
                                .68,
                              ),
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // DATA QUALITY
  // ============================================================

  Widget _buildDataQuality(ThemeData theme, bool compact) {
    final monthsAvailable = _int(_dataQuality['months_available']);

    final monthsWithSpending = _int(_dataQuality['months_with_spending']);

    final monthsWithBudget = _int(_dataQuality['months_with_budget']);

    final canAnalyze = _dataQuality['can_analyze_trend'] == true;

    final currentMonthPartial =
        _dataQuality['is_current_month_partial'] == true;

    return Card(
      elevation: 0,
      child: Padding(
        padding: EdgeInsets.all(compact ? 16 : 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.fact_check_outlined, color: _analyticsTeal),
                const SizedBox(width: 8),
                Text(
                  'Data Quality',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            _qualityRow(theme, 'Months analyzed', '$monthsAvailable'),

            _qualityRow(theme, 'Months with spending', '$monthsWithSpending'),

            _qualityRow(theme, 'Months with budget', '$monthsWithBudget'),

            _qualityRow(
              theme,
              'Trend analysis',
              canAnalyze ? 'Available' : 'Insufficient data',
            ),

            if (currentMonthPartial) ...[
              const SizedBox(height: 10),
              _infoMessage(
                theme,
                'The current month is still in progress, so its historical totals are partial.',
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _qualityRow(ThemeData theme, String label, String value) {
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
          Text(
            value,
            textAlign: TextAlign.right,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // SHARED UI
  // ============================================================

  Widget _simpleSectionCard(
    ThemeData theme, {
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: _analyticsTeal),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: theme.textTheme.titleLarge?.copyWith(
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

  Widget _infoMessage(ThemeData theme, String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withOpacity(.45),
        borderRadius: BorderRadius.circular(13),
      ),
      child: Text(
        message,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurface.withOpacity(.68),
          height: 1.4,
        ),
      ),
    );
  }

  // ============================================================
  // ERROR
  // ============================================================

  Widget _buildErrorState(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Card(
            elevation: 0,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.history_toggle_off_rounded,
                    size: 48,
                    color: theme.colorScheme.error,
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Unable to load historical insights',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _errorMessage ??
                        'Something went wrong while loading your historical insights.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(.68),
                    ),
                  ),
                  const SizedBox(height: 18),
                  FilledButton.icon(
                    onPressed: _loadHistoricalInsights,
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

  Widget _buildInlineError(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.error.withOpacity(.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.colorScheme.error.withOpacity(.20)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.error_outline_rounded, color: theme.colorScheme.error),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _errorMessage!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.error,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
