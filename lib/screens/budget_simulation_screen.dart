import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../services/api_services.dart';
import '../utils/responsive_helper.dart';
import '../widgets/app/adaptive_app_bar.dart';
import '../widgets/app/app_scaffold.dart';

const Color _premiumPurple = Color(0xFF6D3FD9);
const Color _premiumPurpleDark = Color(0xFF34205F);

const Color _budgetBlue = Color(0xFF3B82F6);
const Color _budgetBlueDark = Color(0xFF2563EB);

class BudgetSimulationScreen extends StatefulWidget {
  const BudgetSimulationScreen({super.key});

  @override
  State<BudgetSimulationScreen> createState() => _BudgetSimulationScreenState();
}

class _BudgetSimulationScreenState extends State<BudgetSimulationScreen> {
  final TextEditingController _budgetController = TextEditingController();

  final NumberFormat _currency = NumberFormat.currency(
    locale: 'en_KE',
    symbol: 'KES ',
    decimalDigits: 2,
  );

  bool _isLoading = true;
  bool _isSimulating = false;

  String? _errorMessage;

  Map<String, dynamic>? _data;

  double _spendingAdjustment = 0;

  @override
  void initState() {
    super.initState();
    _loadInitialSimulation();
  }

  @override
  void dispose() {
    _budgetController.dispose();
    super.dispose();
  }

  // ============================================================
  // DATA
  // ============================================================

  Future<void> _loadInitialSimulation() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await ApiService.simulateBudget();

      if (!mounted) return;

      final simulation = Map<String, dynamic>.from(
        response['simulation'] ?? {},
      );

      final budget = _double(simulation['budget']);

      _budgetController.text = budget > 0 ? _formatInputAmount(budget) : '';

      setState(() {
        _data = response;
        _spendingAdjustment = _double(
          simulation['spending_adjustment_percentage'],
        );
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _errorMessage = _cleanError(e);
      });

      debugPrint('Budget Simulation Error: $e');
    }
  }

  Future<void> _runSimulation() async {
    if (_isSimulating) return;

    final text = _budgetController.text.trim();

    double? budgetAmount;

    if (text.isNotEmpty) {
      budgetAmount = double.tryParse(text.replaceAll(',', ''));

      if (budgetAmount == null) {
        _showError('Please enter a valid budget amount.');
        return;
      }

      if (budgetAmount < 0) {
        _showError('Budget cannot be negative.');
        return;
      }

      if (budgetAmount > 999999999.99) {
        _showError('Budget amount is too large.');
        return;
      }
    }

    FocusScope.of(context).unfocus();

    setState(() {
      _isSimulating = true;
      _errorMessage = null;
    });

    try {
      final response = await ApiService.simulateBudget(
        budgetAmount: budgetAmount,
        spendingAdjustmentPercentage: _spendingAdjustment,
      );

      if (!mounted) return;

      setState(() {
        _data = response;
        _isSimulating = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isSimulating = false;
        _errorMessage = _cleanError(e);
      });

      debugPrint('Budget Simulation Error: $e');
    }
  }

  // ============================================================
  // HELPERS
  // ============================================================

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

  String _cleanError(Object error) {
    final message = error.toString();

    if (message.startsWith('Exception: ')) {
      return message.substring('Exception: '.length);
    }

    return message;
  }

  String _formatInputAmount(double value) {
    if (value == value.roundToDouble()) {
      return value.toStringAsFixed(0);
    }

    return value.toStringAsFixed(2);
  }

  String _money(dynamic value) {
    return _currency.format(_double(value));
  }

  String _signedMoney(dynamic value) {
    final amount = _double(value);

    if (amount > 0) {
      return '+${_money(amount)}';
    }

    if (amount < 0) {
      return '-${_money(amount.abs())}';
    }

    return _money(0);
  }

  String _percentage(dynamic value) {
    final amount = _double(value);

    if (amount == amount.roundToDouble()) {
      return '${amount.toStringAsFixed(0)}%';
    }

    return '${amount.toStringAsFixed(1)}%';
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'under_budget':
        return 'Under Budget';

      case 'near_limit':
        return 'Near Budget Limit';

      case 'projected_over_budget':
        return 'Projected Over Budget';

      case 'no_budget':
        return 'No Budget';

      default:
        return status
            .replaceAll('_', ' ')
            .split(' ')
            .map(
              (word) => word.isEmpty
                  ? word
                  : '${word[0].toUpperCase()}'
                        '${word.substring(1)}',
            )
            .join(' ');
    }
  }

  Color _statusColor(BuildContext context, String status) {
    switch (status) {
      case 'under_budget':
        return Colors.green;

      case 'near_limit':
        return Colors.orange;

      case 'projected_over_budget':
        return Colors.red;

      case 'no_budget':
        return Colors.grey;

      default:
        return _budgetBlue;
    }
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case 'under_budget':
        return Icons.check_circle_rounded;

      case 'near_limit':
        return Icons.warning_amber_rounded;

      case 'projected_over_budget':
        return Icons.error_rounded;

      case 'no_budget':
        return Icons.account_balance_wallet_outlined;

      default:
        return Icons.analytics_rounded;
    }
  }

  // ============================================================
  // BODY
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      showOfflineBanner: true,
      showSyncIcon: true,
      appBar: const AdaptiveAppBar(title: 'Budget Simulation'),
      body: _buildBody(Theme.of(context)),
    );
  }

  Widget _buildBody(ThemeData theme) {
    if (_isLoading && _data == null) {
      return _buildLoadingState(theme);
    }

    if (_data == null) {
      return _buildErrorState(theme);
    }

    final compact = ResponsiveHelper.useCompactLayout(context);

    final landscape = ResponsiveHelper.isLandscape(context);

    final desktop = ResponsiveHelper.isDesktop(context);

    final horizontalPadding = ResponsiveHelper.horizontalPadding(context);

    final contentMaxWidth = ResponsiveHelper.contentMaxWidth(context);

    final sectionSpacing = ResponsiveHelper.sectionSpacing(context);

    final bottomPadding = landscape && !desktop
        ? 40.0
        : compact
        ? 28.0
        : 36.0;

    return RefreshIndicator(
      color: _premiumPurple,
      onRefresh: _loadInitialSimulation,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: EdgeInsets.fromLTRB(
          horizontalPadding,
          compact ? 8 : 14,
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
                  _buildHero(theme, compact),

                  SizedBox(height: sectionSpacing),

                  _buildSimulationControls(theme, compact, landscape),

                  SizedBox(height: sectionSpacing),

                  _buildScenarioSummary(theme, compact),

                  SizedBox(height: sectionSpacing),

                  _buildComparison(theme, compact, landscape),

                  SizedBox(height: sectionSpacing),

                  _buildImpactCard(theme, compact, landscape),

                  SizedBox(height: sectionSpacing),

                  _buildSimulationExplanation(theme, compact),

                  if (_errorMessage != null) ...[
                    const SizedBox(height: 16),
                    _buildInlineError(theme),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // HERO
  // ============================================================

  Widget _buildHero(ThemeData theme, bool compact) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(compact ? 18 : 23),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(compact ? 22 : 26),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_premiumPurple, _premiumPurpleDark],
        ),
        border: Border.all(color: Colors.white.withOpacity(0.10)),
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
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withOpacity(0.10)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.workspace_premium_rounded,
                      size: 14,
                      color: Colors.white,
                    ),
                    SizedBox(width: 6),
                    Text(
                      'PREMIUM',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.65,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Icon(
                Icons.science_outlined,
                size: compact ? 20 : 22,
                color: Colors.white.withOpacity(0.45),
              ),
            ],
          ),

          SizedBox(height: compact ? 17 : 20),

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: compact ? 48 : 54,
                height: compact ? 48 : 54,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.11),
                  borderRadius: BorderRadius.circular(compact ? 14 : 16),
                  border: Border.all(color: Colors.white.withOpacity(0.10)),
                ),
                child: Icon(
                  Icons.tune_rounded,
                  color: Colors.white,
                  size: compact ? 24 : 28,
                ),
              ),

              SizedBox(width: compact ? 11 : 14),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Budget Simulation',
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

                    const SizedBox(height: 6),

                    Text(
                      'Explore what could happen when you change your monthly budget or spending pace.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withOpacity(0.76),
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          SizedBox(height: compact ? 15 : 18),

          Container(
            width: double.infinity,
            padding: EdgeInsets.all(compact ? 11 : 13),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.07),
              borderRadius: BorderRadius.circular(compact ? 13 : 15),
              border: Border.all(color: Colors.white.withOpacity(0.08)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  size: compact ? 17 : 18,
                  color: Colors.white.withOpacity(0.85),
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: Text(
                    'Run what-if scenarios without changing your actual budget or recorded expenses.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.white.withOpacity(0.76),
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

  // ============================================================
  // CONTROLS
  // ============================================================

  Widget _buildSimulationControls(
    ThemeData theme,
    bool compact,
    bool landscape,
  ) {
    final scheme = theme.colorScheme;

    return _sectionCard(
      theme,
      compact: compact,
      eyebrow: 'SCENARIO BUILDER',
      title: 'Simulation Inputs',
      subtitle: 'Adjust the assumptions used for this what-if scenario.',
      icon: Icons.tune_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(compact ? 11 : 13),
            decoration: BoxDecoration(
              color: _budgetBlue.withOpacity(0.055),
              borderRadius: BorderRadius.circular(compact ? 14 : 16),
              border: Border.all(color: _budgetBlue.withOpacity(0.09)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: compact ? 32 : 36,
                  height: compact ? 32 : 36,
                  decoration: BoxDecoration(
                    color: _budgetBlue.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(compact ? 9 : 10),
                  ),
                  child: Icon(
                    Icons.shield_outlined,
                    color: _budgetBlue,
                    size: compact ? 16 : 18,
                  ),
                ),
                SizedBox(width: compact ? 9 : 11),
                Expanded(
                  child: Text(
                    'Simulation changes are temporary and do not modify your saved financial data.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurface.withOpacity(0.66),
                      height: 1.4,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: compact ? 16 : 18),

          TextField(
            controller: _budgetController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            textInputAction: TextInputAction.done,
            style: TextStyle(
              fontSize: compact ? 13 : 14.5,
              fontWeight: FontWeight.w600,
            ),
            decoration: InputDecoration(
              labelText: 'Simulated Monthly Budget',
              hintText: 'e.g. 25000',
              prefixText: 'KES ',
              prefixStyle: TextStyle(
                fontSize: compact ? 13 : 14,
                fontWeight: FontWeight.w800,
                color: scheme.onSurface.withOpacity(0.70),
              ),
              prefixIcon: Container(
                margin: const EdgeInsets.only(
                  left: 8,
                  top: 7,
                  bottom: 7,
                  right: 5,
                ),
                width: compact ? 31 : 35,
                decoration: BoxDecoration(
                  color: _budgetBlue.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(
                  Icons.account_balance_wallet_rounded,
                  color: _budgetBlue,
                  size: compact ? 16 : 18,
                ),
              ),
              filled: true,
              fillColor: scheme.surfaceContainerHighest.withOpacity(0.48),
              contentPadding: EdgeInsets.symmetric(
                horizontal: compact ? 11 : 14,
                vertical: compact ? 13 : 15,
              ),
              border: _inputBorder(context),
              enabledBorder: _inputBorder(context),
              focusedBorder: _inputBorder(context, focused: true),
            ),
          ),

          SizedBox(height: compact ? 19 : 22),

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Spending Adjustment',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Adjust the expected spending pace for the remaining days.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurface.withOpacity(0.60),
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 10),

              _adjustmentBadge(theme, compact),
            ],
          ),

          SizedBox(height: compact ? 7 : 9),

          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: _budgetBlue,
              inactiveTrackColor: _budgetBlue.withOpacity(0.12),
              thumbColor: _budgetBlueDark,
              overlayColor: _budgetBlue.withOpacity(0.10),
              trackHeight: compact ? 5 : 6,
              thumbShape: RoundSliderThumbShape(
                enabledThumbRadius: compact ? 8 : 9,
              ),
            ),
            child: Slider(
              value: _spendingAdjustment,
              min: -100,
              max: 200,
              divisions: 60,
              label: _spendingAdjustment > 0
                  ? '+${_percentage(_spendingAdjustment)}'
                  : _percentage(_spendingAdjustment),
              onChanged: _isSimulating
                  ? null
                  : (value) {
                      setState(() {
                        _spendingAdjustment = value;
                      });
                    },
            ),
          ),

          Row(
            children: [
              _sliderLabel(theme, '-100%', alignStart: true),
              Expanded(
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: scheme.surfaceContainerHighest.withOpacity(0.50),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'No change',
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
              _sliderLabel(theme, '+200%', alignStart: false),
            ],
          ),

          SizedBox(height: compact ? 18 : 21),

          SizedBox(
            width: double.infinity,
            height: compact
                ? 49
                : landscape
                ? 51
                : 54,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: _budgetBlue,
                disabledBackgroundColor: _budgetBlue.withOpacity(0.50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(compact ? 14 : 16),
                ),
              ),
              onPressed: _isSimulating ? null : _runSimulation,
              icon: _isSimulating
                  ? SizedBox(
                      width: compact ? 18 : 20,
                      height: compact ? 18 : 20,
                      child: const CircularProgressIndicator(
                        strokeWidth: 2.2,
                        color: Colors.white,
                      ),
                    )
                  : Icon(Icons.play_arrow_rounded, size: compact ? 19 : 21),
              label: Text(
                _isSimulating ? 'Running Simulation...' : 'Run Simulation',
                style: TextStyle(
                  fontSize: compact ? 13 : 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _adjustmentBadge(ThemeData theme, bool compact) {
    final value = _spendingAdjustment;

    final color = value > 0
        ? Colors.orange
        : value < 0
        ? Colors.green
        : _budgetBlue;

    final text = value > 0 ? '+${_percentage(value)}' : _percentage(value);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 9 : 10,
        vertical: compact ? 6 : 7,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.09),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.10)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: compact ? 11 : 12,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  Widget _sliderLabel(
    ThemeData theme,
    String text, {
    required bool alignStart,
  }) {
    return Text(
      text,
      textAlign: alignStart ? TextAlign.left : TextAlign.right,
      style: theme.textTheme.labelSmall?.copyWith(
        color: theme.colorScheme.onSurface.withOpacity(0.50),
        fontWeight: FontWeight.w600,
      ),
    );
  }

  // ============================================================
  // SCENARIO SUMMARY
  // ============================================================

  Widget _buildScenarioSummary(ThemeData theme, bool compact) {
    final simulation = Map<String, dynamic>.from(_data!['simulation'] ?? {});

    final status = simulation['status']?.toString() ?? 'no_budget';

    final statusColor = _statusColor(context, status);

    final statusIcon = _statusIcon(status);

    final statusLabel = _statusLabel(status);

    return _sectionCard(
      theme,
      compact: compact,
      eyebrow: 'SCENARIO RESULT',
      title: 'Simulation Outlook',
      subtitle: 'The current what-if scenario at a glance.',
      icon: Icons.insights_rounded,
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(compact ? 12 : 14),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.07),
              borderRadius: BorderRadius.circular(compact ? 15 : 17),
              border: Border.all(color: statusColor.withOpacity(0.12)),
            ),
            child: Row(
              children: [
                Container(
                  width: compact ? 37 : 41,
                  height: compact ? 37 : 41,
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Icon(
                    statusIcon,
                    color: statusColor,
                    size: compact ? 18 : 20,
                  ),
                ),

                SizedBox(width: compact ? 10 : 12),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        statusLabel,
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: statusColor,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Projected simulation status',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: compact ? 14 : 16),

          _buildSummaryMetrics(theme, compact, simulation),
        ],
      ),
    );
  }

  Widget _buildSummaryMetrics(
    ThemeData theme,
    bool compact,
    Map<String, dynamic> simulation,
  ) {
    final metrics = [
      _SummaryMetric(
        label: 'Simulated budget',
        value: _money(simulation['budget']),
        icon: Icons.account_balance_wallet_rounded,
      ),
      _SummaryMetric(
        label: 'Projected spending',
        value: _money(simulation['projected_month_end_spending']),
        icon: Icons.auto_graph_rounded,
      ),
      _SummaryMetric(
        label: 'Projected remaining',
        value: _money(simulation['projected_remaining']),
        icon: Icons.savings_rounded,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final vertical = constraints.maxWidth < 520;

        if (vertical) {
          return Column(
            children: metrics
                .map(
                  (metric) => Padding(
                    padding: const EdgeInsets.only(bottom: 9),
                    child: _summaryMetricTile(theme, compact, metric),
                  ),
                )
                .toList(),
          );
        }

        return Row(
          children: [
            for (int i = 0; i < metrics.length; i++) ...[
              Expanded(child: _summaryMetricTile(theme, compact, metrics[i])),
              if (i != metrics.length - 1) const SizedBox(width: 9),
            ],
          ],
        );
      },
    );
  }

  Widget _summaryMetricTile(
    ThemeData theme,
    bool compact,
    _SummaryMetric metric,
  ) {
    return Container(
      padding: EdgeInsets.all(compact ? 10 : 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.36),
        borderRadius: BorderRadius.circular(compact ? 14 : 16),
      ),
      child: Row(
        children: [
          Container(
            width: compact ? 32 : 35,
            height: compact ? 32 : 35,
            decoration: BoxDecoration(
              color: _budgetBlue.withOpacity(0.09),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              metric.icon,
              size: compact ? 16 : 18,
              color: _budgetBlue,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  metric.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 3),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    metric.value,
                    maxLines: 1,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
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

  Widget _buildComparison(ThemeData theme, bool compact, bool landscape) {
    final baseline = Map<String, dynamic>.from(_data!['baseline'] ?? {});

    final simulation = Map<String, dynamic>.from(_data!['simulation'] ?? {});

    final currentCard = _buildPositionCard(
      theme: theme,
      title: 'Current Budget',
      subtitle: 'Based on your actual budget',
      color: theme.colorScheme.onSurfaceVariant,
      budget: baseline['budget'],
      projectedSpending: baseline['projected_month_end_spending'],
      remaining: baseline['projected_remaining'],
      usage: baseline['projected_usage_percentage'],
      dailySpending: baseline['daily_spending'],
      icon: Icons.account_balance_wallet_outlined,
    );

    final simulationCard = _buildPositionCard(
      theme: theme,
      title: 'Simulation',
      subtitle: 'Based on your what-if scenario',
      color: _budgetBlue,
      budget: simulation['budget'],
      projectedSpending: simulation['projected_month_end_spending'],
      remaining: simulation['projected_remaining'],
      usage: simulation['projected_usage_percentage'],
      dailySpending: simulation['daily_spending'],
      icon: Icons.auto_graph_rounded,
    );

    return _sectionCard(
      theme,
      compact: compact,
      eyebrow: 'SIDE-BY-SIDE',
      title: 'Current vs Simulation',
      subtitle: 'See how the scenario changes your budget position.',
      icon: Icons.compare_arrows_rounded,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final stacked = compact || constraints.maxWidth < 640;

          if (stacked) {
            return Column(
              children: [
                currentCard,
                const SizedBox(height: 10),
                simulationCard,
              ],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: currentCard),
              const SizedBox(width: 12),
              Expanded(child: simulationCard),
            ],
          );
        },
      ),
    );
  }

  Widget _buildPositionCard({
    required ThemeData theme,
    required String title,
    required String subtitle,
    required Color color,
    required dynamic budget,
    required dynamic projectedSpending,
    required dynamic remaining,
    required dynamic usage,
    required dynamic dailySpending,
    required IconData icon,
  }) {
    final compact = ResponsiveHelper.useCompactLayout(context);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(compact ? 13 : 16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.32),
        borderRadius: BorderRadius.circular(compact ? 16 : 18),
        border: Border.all(color: color.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: compact ? 38 : 42,
                height: compact ? 38 : 42,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.09),
                  borderRadius: BorderRadius.circular(compact ? 11 : 12),
                ),
                child: Icon(icon, color: color, size: compact ? 18 : 20),
              ),

              SizedBox(width: compact ? 9 : 11),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          SizedBox(height: compact ? 14 : 17),

          _metricRow(theme, 'Monthly budget', _money(budget)),

          _metricRow(theme, 'Daily spending', _money(dailySpending)),

          _metricRow(theme, 'Projected month-end', _money(projectedSpending)),

          _metricRow(theme, 'Projected remaining', _money(remaining)),

          _metricRow(
            theme,
            'Projected usage',
            _percentage(usage),
            isLast: true,
            highlightColor: color,
          ),
        ],
      ),
    );
  }

  Widget _metricRow(
    ThemeData theme,
    String label,
    String value, {
    bool isLast = false,
    Color? highlightColor,
  }) {
    final compact = ResponsiveHelper.useCompactLayout(context);

    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 9),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                fontSize: compact ? 10.5 : 11.5,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: theme.textTheme.bodySmall?.copyWith(
                fontSize: compact ? 10.5 : 11.5,
                fontWeight: FontWeight.w800,
                color: highlightColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // IMPACT
  // ============================================================

  Widget _buildImpactCard(ThemeData theme, bool compact, bool landscape) {
    final impact = Map<String, dynamic>.from(_data!['impact'] ?? {});

    final simulation = Map<String, dynamic>.from(_data!['simulation'] ?? {});

    final projectionChange = _double(impact['projected_spending_change']);

    final remainingChange = _double(impact['projected_remaining_change']);

    final adjustment = _double(simulation['spending_adjustment_percentage']);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(compact ? 15 : 19),
      decoration: BoxDecoration(
        color: _budgetBlue.withOpacity(0.045),
        borderRadius: BorderRadius.circular(compact ? 18 : 21),
        border: Border.all(color: _budgetBlue.withOpacity(0.11)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: compact ? 36 : 40,
                height: compact ? 36 : 40,
                decoration: BoxDecoration(
                  color: _budgetBlue.withOpacity(0.09),
                  borderRadius: BorderRadius.circular(compact ? 10 : 11),
                ),
                child: Icon(
                  Icons.compare_arrows_rounded,
                  color: _budgetBlue,
                  size: compact ? 18 : 20,
                ),
              ),

              SizedBox(width: compact ? 10 : 12),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'SIMULATION IMPACT',
                      style: TextStyle(
                        fontSize: compact ? 9 : 9.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.85,
                        color: _budgetBlue,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'What changed?',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          SizedBox(height: compact ? 7 : 9),

          Text(
            adjustment == 0
                ? 'No change in spending pace.'
                : 'Spending pace adjusted by '
                      '${adjustment > 0 ? '+' : ''}'
                      '${_percentage(adjustment)} '
                      'for the remaining days.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.4,
            ),
          ),

          SizedBox(height: compact ? 15 : 18),

          LayoutBuilder(
            builder: (context, constraints) {
              final stacked = compact || constraints.maxWidth < 520;

              if (stacked) {
                return Column(
                  children: [
                    _impactMetric(
                      theme,
                      title: 'Projected spending change',
                      value: _signedMoney(projectionChange),
                      icon: Icons.trending_up_rounded,
                      positive: projectionChange <= 0,
                    ),
                    const SizedBox(height: 9),
                    _impactMetric(
                      theme,
                      title: 'Projected remaining change',
                      value: _signedMoney(remainingChange),
                      icon: Icons.savings_rounded,
                      positive: remainingChange >= 0,
                    ),
                  ],
                );
              }

              return Row(
                children: [
                  Expanded(
                    child: _impactMetric(
                      theme,
                      title: 'Projected spending change',
                      value: _signedMoney(projectionChange),
                      icon: Icons.trending_up_rounded,
                      positive: projectionChange <= 0,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _impactMetric(
                      theme,
                      title: 'Projected remaining change',
                      value: _signedMoney(remainingChange),
                      icon: Icons.savings_rounded,
                      positive: remainingChange >= 0,
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _impactMetric(
    ThemeData theme, {
    required String title,
    required String value,
    required IconData icon,
    required bool positive,
  }) {
    final compact = ResponsiveHelper.useCompactLayout(context);

    final accent = positive ? Colors.green : Colors.red;

    return Container(
      padding: EdgeInsets.all(compact ? 11 : 13),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(compact ? 14 : 16),
        border: Border.all(color: accent.withOpacity(0.07)),
      ),
      child: Row(
        children: [
          Container(
            width: compact ? 33 : 36,
            height: compact ? 33 : 36,
            decoration: BoxDecoration(
              color: accent.withOpacity(0.09),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: compact ? 16 : 18, color: accent),
          ),

          SizedBox(width: compact ? 8 : 10),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    height: 1.25,
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
                      color: accent,
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
  // EXPLANATION
  // ============================================================

  Widget _buildSimulationExplanation(ThemeData theme, bool compact) {
    final dataQuality = Map<String, dynamic>.from(_data!['data_quality'] ?? {});

    final basis =
        dataQuality['simulation_basis']?.toString() ??
        'Simulation uses current-month actual spending.';

    final period = Map<String, dynamic>.from(_data!['period'] ?? {});

    final daysRemaining = _int(period['days_remaining']);

    return _sectionCard(
      theme,
      compact: compact,
      eyebrow: 'METHODOLOGY',
      title: 'How the Simulation Works',
      subtitle:
          'Understand what the scenario is using to produce its projection.',
      icon: Icons.info_outline_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            basis,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.5,
            ),
          ),

          const SizedBox(height: 10),

          Text(
            '$daysRemaining days remaining in the current month are included in the projection.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.5,
            ),
          ),

          SizedBox(height: compact ? 12 : 14),

          Container(
            width: double.infinity,
            padding: EdgeInsets.all(compact ? 11 : 13),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withOpacity(
                0.40,
              ),
              borderRadius: BorderRadius.circular(compact ? 13 : 15),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.lock_outline_rounded,
                  size: compact ? 16 : 17,
                  color: _budgetBlue,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Simulation only • Your actual budget and recorded expenses remain unchanged.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w700,
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

  // ============================================================
  // SHARED SECTION CARD
  // ============================================================

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

          SizedBox(height: compact ? 15 : 18),

          child,
        ],
      ),
    );
  }

  InputBorder _inputBorder(BuildContext context, {bool focused = false}) {
    final scheme = Theme.of(context).colorScheme;

    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(15),
      borderSide: BorderSide(
        color: focused
            ? scheme.primary.withOpacity(0.60)
            : scheme.outline.withOpacity(0.08),
        width: focused ? 1.4 : 1,
      ),
    );
  }

  // ============================================================
  // ERROR / LOADING
  // ============================================================

  Widget _buildLoadingState(ThemeData theme) {
    final compact = ResponsiveHelper.useCompactLayout(context);

    return Center(
      child: Padding(
        padding: EdgeInsets.all(compact ? 24 : 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: compact ? 66 : 74,
              height: compact ? 66 : 74,
              decoration: BoxDecoration(
                color: _premiumPurple.withOpacity(0.09),
                borderRadius: BorderRadius.circular(compact ? 19 : 21),
              ),
              child: CircularProgressIndicator(
                strokeWidth: compact ? 3 : 3.2,
                color: _premiumPurple,
              ),
            ),

            SizedBox(height: compact ? 15 : 18),

            Text(
              'Preparing budget simulation',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),

            const SizedBox(height: 5),

            Text(
              'Loading your current budget position...',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(ThemeData theme) {
    final compact = ResponsiveHelper.useCompactLayout(context);

    return Center(
      child: Padding(
        padding: EdgeInsets.all(compact ? 20 : 28),
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
                'Unable to load budget simulation',
                textAlign: TextAlign.center,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),

              const SizedBox(height: 8),

              Text(
                _errorMessage ??
                    'Something went wrong while loading the simulation.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  height: 1.4,
                ),
              ),

              SizedBox(height: compact ? 16 : 20),

              FilledButton.icon(
                onPressed: _loadInitialSimulation,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Try Again'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInlineError(ThemeData theme) {
    final compact = ResponsiveHelper.useCompactLayout(context);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(compact ? 12 : 14),
      decoration: BoxDecoration(
        color: theme.colorScheme.error.withOpacity(0.07),
        borderRadius: BorderRadius.circular(compact ? 14 : 16),
        border: Border.all(color: theme.colorScheme.error.withOpacity(0.16)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.error_outline_rounded,
            color: theme.colorScheme.error,
            size: compact ? 18 : 20,
          ),
          const SizedBox(width: 9),
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

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }
}

class _SummaryMetric {
  final String label;
  final String value;
  final IconData icon;

  const _SummaryMetric({
    required this.label,
    required this.value,
    required this.icon,
  });
}
