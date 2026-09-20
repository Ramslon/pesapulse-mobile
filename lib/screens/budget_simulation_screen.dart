import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../services/api_services.dart';
import '../utils/responsive_helper.dart';
import '../widgets/app/adaptive_app_bar.dart';
import '../widgets/app/app_scaffold.dart';

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
                  : '${word[0].toUpperCase()}${word.substring(1)}',
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
        return Theme.of(context).colorScheme.primary;
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
    final theme = Theme.of(context);

    return AppScaffold(
      appBar: const AdaptiveAppBar(title: 'Budget Simulation'),
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
      onRefresh: _loadInitialSimulation,
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

                _buildSimulationControls(theme, compact),

                const SizedBox(height: 16),

                _buildComparison(theme, compact),

                const SizedBox(height: 16),

                _buildImpactCard(theme, compact),

                const SizedBox(height: 16),

                _buildSimulationExplanation(theme),

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
    final scheme = theme.colorScheme;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(compact ? 20 : 24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [scheme.primaryContainer, scheme.surface],
        ),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: compact ? 46 : 52,
            height: compact ? 46 : 52,
            decoration: BoxDecoration(
              color: scheme.primary,
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(
              Icons.tune_rounded,
              color: scheme.onPrimary,
              size: compact ? 24 : 28,
            ),
          ),
          SizedBox(width: compact ? 12 : 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Budget Simulation',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  'Explore what could happen if you change your monthly budget or spending pace.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurface.withOpacity(.70),
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
  // CONTROLS
  // ============================================================

  Widget _buildSimulationControls(ThemeData theme, bool compact) {
    final scheme = theme.colorScheme;

    return Card(
      elevation: 0,
      child: Padding(
        padding: EdgeInsets.all(compact ? 16 : 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Simulation Inputs',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 6),

            Text(
              'These values are only used for the simulation. Your real budget and expenses will not be changed.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurface.withOpacity(.65),
                height: 1.4,
              ),
            ),

            const SizedBox(height: 18),

            TextField(
              controller: _budgetController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              textInputAction: TextInputAction.done,
              decoration: InputDecoration(
                labelText: 'Simulated Monthly Budget',
                hintText: 'e.g. 25000',
                prefixText: 'KES ',
                prefixIcon: const Icon(Icons.account_balance_wallet_rounded),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),

            const SizedBox(height: 22),

            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Spending Adjustment',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Change the expected spending pace for the remaining days.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurface.withOpacity(.65),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: scheme.primary.withOpacity(.10),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _spendingAdjustment > 0
                        ? '+${_percentage(_spendingAdjustment)}'
                        : _percentage(_spendingAdjustment),
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: scheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            Slider(
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

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('-100%', style: theme.textTheme.labelSmall),
                Text(
                  'No change',
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text('+200%', style: theme.textTheme.labelSmall),
              ],
            ),

            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton.icon(
                onPressed: _isSimulating ? null : _runSimulation,
                icon: _isSimulating
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.play_arrow_rounded),
                label: Text(
                  _isSimulating ? 'Running Simulation...' : 'Run Simulation',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // COMPARISON
  // ============================================================

  Widget _buildComparison(ThemeData theme, bool compact) {
    final baseline = Map<String, dynamic>.from(_data!['baseline'] ?? {});

    final simulation = Map<String, dynamic>.from(_data!['simulation'] ?? {});

    final status = simulation['status']?.toString() ?? 'no_budget';

    final statusColor = _statusColor(context, status);

    final statusIcon = _statusIcon(status);

    final statusLabel = _statusLabel(status);

    final baselineCard = _buildPositionCard(
      theme: theme,
      title: 'Current',
      subtitle: 'Based on your actual budget',
      color: Colors.grey.shade700,
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
      subtitle: 'What-if scenario',
      color: theme.colorScheme.primary,
      budget: simulation['budget'],
      projectedSpending: simulation['projected_month_end_spending'],
      remaining: simulation['projected_remaining'],
      usage: simulation['projected_usage_percentage'],
      dailySpending: simulation['daily_spending'],
      icon: Icons.auto_graph_rounded,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Current vs Simulation',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 12),

        if (compact)
          Column(
            children: [
              baselineCard,
              const SizedBox(height: 12),
              simulationCard,
            ],
          )
        else
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: baselineCard),
              const SizedBox(width: 14),
              Expanded(child: simulationCard),
            ],
          ),

        const SizedBox(height: 14),

        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: statusColor.withOpacity(.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: statusColor.withOpacity(.20)),
          ),
          child: Row(
            children: [
              Icon(statusIcon, color: statusColor, size: 21),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  statusLabel,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: statusColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Text(
                'Simulated',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: statusColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
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
    final scheme = theme.colorScheme;

    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: color.withOpacity(.10),
                    borderRadius: BorderRadius.circular(12),
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
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurface.withOpacity(.58),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 18),

            _metricRow(theme, 'Monthly budget', _money(budget)),

            _metricRow(theme, 'Daily spending', _money(dailySpending)),

            _metricRow(theme, 'Projected month-end', _money(projectedSpending)),

            _metricRow(theme, 'Projected remaining', _money(remaining)),

            _metricRow(
              theme,
              'Projected usage',
              _percentage(usage),
              isLast: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _metricRow(
    ThemeData theme,
    String label,
    String value, {
    bool isLast = false,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 11),
      child: Row(
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
                fontWeight: FontWeight.w700,
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

  Widget _buildImpactCard(ThemeData theme, bool compact) {
    final impact = Map<String, dynamic>.from(_data!['impact'] ?? {});

    final simulation = Map<String, dynamic>.from(_data!['simulation'] ?? {});

    final projectionChange = _double(impact['projected_spending_change']);

    final remainingChange = _double(impact['projected_remaining_change']);

    final adjustment = _double(simulation['spending_adjustment_percentage']);

    return Card(
      elevation: 0,
      color: theme.colorScheme.primary.withOpacity(.045),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: theme.colorScheme.primary.withOpacity(.10)),
      ),
      child: Padding(
        padding: EdgeInsets.all(compact ? 16 : 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.compare_arrows_rounded,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Simulation Impact',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 6),

            Text(
              adjustment == 0
                  ? 'No change in spending pace.'
                  : 'Spending pace adjusted by ${adjustment > 0 ? '+' : ''}${_percentage(adjustment)} for the remaining days.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(.65),
                height: 1.4,
              ),
            ),

            const SizedBox(height: 18),

            if (compact)
              Column(
                children: [
                  _impactMetric(
                    theme,
                    title: 'Projected spending change',
                    value: _signedMoney(projectionChange),
                    icon: Icons.trending_up_rounded,
                  ),
                  const SizedBox(height: 12),
                  _impactMetric(
                    theme,
                    title: 'Projected remaining change',
                    value: _signedMoney(remainingChange),
                    icon: Icons.savings_rounded,
                  ),
                ],
              )
            else
              Row(
                children: [
                  Expanded(
                    child: _impactMetric(
                      theme,
                      title: 'Projected spending change',
                      value: _signedMoney(projectionChange),
                      icon: Icons.trending_up_rounded,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _impactMetric(
                      theme,
                      title: 'Projected remaining change',
                      value: _signedMoney(remainingChange),
                      icon: Icons.savings_rounded,
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _impactMetric(
    ThemeData theme, {
    required String title,
    required String value,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(icon, size: 22, color: theme.colorScheme.primary),
          const SizedBox(width: 10),
          Expanded(
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
          ),
        ],
      ),
    );
  }

  // ============================================================
  // EXPLANATION
  // ============================================================

  Widget _buildSimulationExplanation(ThemeData theme) {
    final dataQuality = Map<String, dynamic>.from(_data!['data_quality'] ?? {});

    final basis =
        dataQuality['simulation_basis']?.toString() ??
        'Simulation uses current-month actual spending.';

    final daysRemaining = _int(
      Map<String, dynamic>.from(_data!['period'] ?? {})['days_remaining'],
    );

    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'How the simulation works',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            Text(
              basis,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(.68),
                height: 1.5,
              ),
            ),

            const SizedBox(height: 10),

            Text(
              '$daysRemaining days remaining in the current month are included in the projection.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(.68),
                height: 1.5,
              ),
            ),

            const SizedBox(height: 12),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withOpacity(
                  .45,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Simulation only • Your actual budget and recorded expenses remain unchanged.',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  height: 1.4,
                ),
              ),
            ),
          ],
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
                    Icons.cloud_off_rounded,
                    size: 48,
                    color: theme.colorScheme.error,
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Unable to load budget simulation',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _errorMessage ??
                        'Something went wrong while loading the simulation.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(.68),
                    ),
                  ),
                  const SizedBox(height: 18),
                  FilledButton.icon(
                    onPressed: _loadInitialSimulation,
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

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }
}
