import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../services/api_services.dart';
import '../utils/responsive_helper.dart';

import '../widgets/app/adaptive_app_bar.dart';
import '../widgets/app/app_scaffold.dart';

const Color _premiumPurple = Color(0xFF6D3FD9);
const Color _premiumPurpleDark = Color(0xFF34205F);

const Color _goalAmber = Color(0xFFFFC107);
const Color _goalAmberDark = Color(0xFFF59E0B);

class GoalForecastScreen extends StatefulWidget {
  const GoalForecastScreen({super.key});

  @override
  State<GoalForecastScreen> createState() => _GoalForecastScreenState();
}

class _GoalForecastScreenState extends State<GoalForecastScreen> {
  bool _isLoading = true;
  bool _isRefreshing = false;

  String? _errorMessage;

  Map<String, dynamic> _data = {};

  final NumberFormat _currency = NumberFormat.currency(
    locale: 'en_KE',
    symbol: 'KES ',
    decimalDigits: 2,
  );

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
      final response = await ApiService.getAdvancedGoalForecast();

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

    if (value is int) return value;

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(value.toString()) ?? 0;
  }

  String _money(dynamic value) {
    return _currency.format(_toDouble(value));
  }

  String _date(dynamic value) {
    if (value == null || value.toString().trim().isEmpty) {
      return '—';
    }

    try {
      return DateFormat('dd MMM yyyy').format(DateTime.parse(value.toString()));
    } catch (_) {
      return value.toString();
    }
  }

  String _daysLabel(dynamic value) {
    final days = _toInt(value);

    if (days < 0) {
      return '${days.abs()} days ago';
    }

    if (days == 0) {
      return 'Today';
    }

    if (days == 1) {
      return '1 day';
    }

    return '$days days';
  }

  List<Map<String, dynamic>> get _goals {
    final value = _data['goals'];

    if (value is! List) {
      return [];
    }

    return value
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  Map<String, dynamic> get _summary {
    final value = _data['summary'];

    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }

    return {};
  }

  Map<String, dynamic> get _dataQuality {
    final value = _data['data_quality'];

    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }

    return {};
  }

  // ============================================================
  // STATUS / COLORS
  // ============================================================

  Color _statusColor(BuildContext context, String status) {
    final scheme = Theme.of(context).colorScheme;

    switch (status) {
      case 'completed':
        return Colors.green;

      case 'ahead':
        return Colors.green;

      case 'on_track':
        return _goalAmber;

      case 'behind':
        return Colors.orange;

      case 'overdue':
        return Colors.red;

      default:
        return scheme.onSurfaceVariant;
    }
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case 'completed':
        return Icons.check_circle_rounded;

      case 'ahead':
        return Icons.trending_up_rounded;

      case 'on_track':
        return Icons.track_changes_rounded;

      case 'behind':
        return Icons.warning_amber_rounded;

      case 'overdue':
        return Icons.event_busy_rounded;

      default:
        return Icons.hourglass_empty_rounded;
    }
  }

  String _statusTitle(String status) {
    switch (status) {
      case 'completed':
        return 'Completed';

      case 'ahead':
        return 'Ahead';

      case 'on_track':
        return 'On track';

      case 'behind':
        return 'Behind';

      case 'overdue':
        return 'Overdue';

      case 'no_target_date':
        return 'No target date';

      default:
        return 'Forecast pending';
    }
  }

  Color _confidenceColor(BuildContext context, String confidence) {
    final scheme = Theme.of(context).colorScheme;

    switch (confidence) {
      case 'high':
        return Colors.green;

      case 'medium':
        return _goalAmber;

      case 'low':
        return Colors.orange;

      default:
        return scheme.onSurfaceVariant;
    }
  }

  String _confidenceTitle(String confidence) {
    switch (confidence) {
      case 'high':
        return 'High confidence';

      case 'medium':
        return 'Medium confidence';

      case 'low':
        return 'Low confidence';

      default:
        return 'Building history';
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
            Icon(icon, size: 21, color: _goalAmber),
            const SizedBox(width: 9),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    letterSpacing: -.2,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 5),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(.65),
                      height: 1.45,
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

  Widget _statusChip(
    BuildContext context, {
    required String label,
    required Color color,
    IconData? icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(.09),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: color.withOpacity(.12)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 5),
          ],
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // HERO
  // ============================================================

  Widget _buildHero(BuildContext context) {
    final theme = Theme.of(context);

    final asOf = _data['as_of']?.toString();

    final compact = ResponsiveHelper.useCompactLayout(context);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(ResponsiveHelper.cardPadding(context)),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(compact ? 22 : 26),
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
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: compact ? 48 : 56,
                height: compact ? 48 : 56,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(.10),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.auto_awesome_rounded,
                  color: Colors.white,
                  size: compact ? 25 : 30,
                ),
              ),

              const SizedBox(width: 14),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            'Goal Forecast',
                            style: theme.textTheme.headlineSmall?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -.5,
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

                    const SizedBox(height: 7),

                    Text(
                      'Understand when your goals may be completed and how your saving pace affects the outcome.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withOpacity(.72),
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _heroChip(
                icon: Icons.auto_graph_rounded,
                label: 'Predictive insights',
              ),
              if (asOf != null)
                _heroChip(
                  icon: Icons.schedule_rounded,
                  label: 'Updated ${_date(asOf)}',
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _heroChip({required IconData icon, required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(.20),
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
    final totalGoals = _toInt(_summary['goals_available']);
    final forecasted = _toInt(_summary['goals_forecasted']);
    final completed = _toInt(_summary['completed_goals']);
    final attention =
        _toInt(_summary['behind_goals']) + _toInt(_summary['overdue_goals']);

    final items = [
      ('Goals', '$totalGoals', Icons.flag_outlined, _goalAmber),
      ('Forecasted', '$forecasted', Icons.auto_graph_rounded, _goalAmberDark),
      (
        'Completed',
        '$completed',
        Icons.check_circle_outline_rounded,
        Colors.green,
      ),
      (
        'Need attention',
        '$attention',
        Icons.warning_amber_rounded,
        attention > 0
            ? Colors.orange
            : Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = ResponsiveHelper.useCompactLayout(context);

        // Adaptive column count
        final crossAxisCount = compact
            ? 2
            : constraints.maxWidth >= 1200
            ? 4
            : constraints.maxWidth >= 800
            ? 3
            : 2;

        final spacing = ResponsiveHelper.spacing(context);

        // Adaptive aspect ratio
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
            final theme = Theme.of(context);

            return Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: theme.colorScheme.outline.withOpacity(.08),
                ),
              ),
              child: Padding(
                padding: EdgeInsets.all(ResponsiveHelper.cardPadding(context)),
                child: Column(
                  mainAxisAlignment:
                      MainAxisAlignment.spaceBetween, // ✅ avoids overflow
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: item.$4.withOpacity(.10),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(item.$3, color: item.$4, size: 20),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.$1,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(.60),
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          item.$2,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
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

  // ============================================================
  // GOAL CARD
  // ============================================================

  Widget _buildGoalCard(BuildContext context, Map<String, dynamic> goal) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final status = goal['forecast_status']?.toString() ?? 'insufficient_data';

    final confidence = goal['confidence']?.toString() ?? 'insufficient_data';

    final title = goal['title']?.toString() ?? 'Goal';

    final target = _toDouble(goal['target_amount']);

    final saved = _toDouble(goal['saved_amount']);

    final remaining = _toDouble(goal['remaining_amount']);

    final progress = (_toDouble(goal['progress_percentage']) / 100).clamp(
      0.0,
      1.0,
    );

    final targetDate = goal['target_date'];

    final projectedDate = goal['projected_completion_date'];

    final daysRemaining = goal['days_remaining'];

    final averageDailySaving = _toDouble(
      goal['average_daily_saving_to_date'] ?? goal['current_daily_saving'],
    );

    final requiredDailySaving = _toDouble(goal['required_daily_saving']);

    final requiredMonthlySaving = _toDouble(goal['required_monthly_saving']);

    final statusColor = _statusColor(context, status);

    final confidenceColor = _confidenceColor(context, confidence);

    final canForecast = goal['data_quality']?['can_forecast'] == true;

    final daysElapsed = _toInt(
      goal['data_quality']?['elapsed_days'] ?? goal['days_elapsed'],
    );

    final minimumDays = _toInt(_dataQuality['minimum_forecast_history_days']);

    final readiness = minimumDays > 0
        ? (daysElapsed / minimumDays).clamp(0.0, 1.0)
        : canForecast
        ? 1.0
        : 0.0;

    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(
          ResponsiveHelper.useCompactLayout(context) ? 20 : 24,
        ),
        border: Border.all(color: statusColor.withOpacity(.12)),
      ),
      child: Padding(
        padding: EdgeInsets.all(ResponsiveHelper.cardPadding(context)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(.10),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(_statusIcon(status), color: statusColor),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 7),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          _statusChip(
                            context,
                            label: _statusTitle(status),
                            color: statusColor,
                            icon: _statusIcon(status),
                          ),
                          _statusChip(
                            context,
                            label: _confidenceTitle(confidence),
                            color: confidenceColor,
                            icon: Icons.analytics_outlined,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 22),

            // Progress + target
            LayoutBuilder(
              builder: (context, constraints) {
                final compact = ResponsiveHelper.useCompactLayout(context);

                final progressPercentage = _toDouble(
                  goal['progress_percentage'],
                );

                if (compact || constraints.maxWidth < 600) {
                  return Column(
                    children: [
                      _buildProgressIndicator(
                        context,
                        percentage: progressPercentage,
                        progress: progress,
                        statusColor: _goalAmber,
                      ),
                      const SizedBox(height: 14),
                      _buildTargetSummary(
                        context,
                        saved: saved,
                        target: target,
                        remaining: remaining,
                      ),
                    ],
                  );
                }

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    _buildProgressIndicator(
                      context,
                      percentage: progressPercentage,
                      progress: progress,
                      statusColor: _goalAmber,
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: _buildTargetSummary(
                        context,
                        saved: saved,
                        target: target,
                        remaining: remaining,
                      ),
                    ),
                  ],
                );
              },
            ),

            const SizedBox(height: 22),
            const Divider(),
            const SizedBox(height: 18),

            // Timeline metrics
            _sectionMiniTitle(context, 'Timeline', Icons.timeline_rounded),

            const SizedBox(height: 12),

            LayoutBuilder(
              builder: (context, constraints) {
                final compact = ResponsiveHelper.useCompactLayout(context);

                if (compact || constraints.maxWidth < 700) {
                  return Column(
                    children: [
                      _buildMetric(
                        context,
                        'Target date',
                        targetDate == null ? 'No deadline' : _date(targetDate),
                        Icons.event_outlined,
                      ),
                      const SizedBox(height: 13),
                      _buildMetric(
                        context,
                        'Days remaining',
                        targetDate == null ? '—' : _daysLabel(daysRemaining),
                        Icons.schedule_outlined,
                      ),
                      const SizedBox(height: 13),
                      _buildMetric(
                        context,
                        'Projected completion',
                        projectedDate == null
                            ? 'Not available yet'
                            : _date(projectedDate),
                        Icons.auto_graph_outlined,
                      ),
                    ],
                  );
                }

                return Row(
                  children: [
                    Expanded(
                      child: _buildMetric(
                        context,
                        'Target date',
                        targetDate == null ? 'No deadline' : _date(targetDate),
                        Icons.event_outlined,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildMetric(
                        context,
                        'Days remaining',
                        targetDate == null ? '—' : _daysLabel(daysRemaining),
                        Icons.schedule_outlined,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildMetric(
                        context,
                        'Projected completion',
                        projectedDate == null
                            ? 'Not available yet'
                            : _date(projectedDate),
                        Icons.auto_graph_outlined,
                      ),
                    ),
                  ],
                );
              },
            ),

            const SizedBox(height: 22),

            // Forecast readiness
            if (!canForecast)
              _buildReadinessCard(
                context,
                daysElapsed: daysElapsed,
                minimumDays: minimumDays,
                readiness: readiness,
              ),

            if (canForecast) ...[
              _buildConfidenceCard(
                context,
                confidence: confidence,
                message: goal['confidence_message']?.toString(),
                color: confidenceColor,
              ),
            ],

            const SizedBox(height: 18),

            // Saving pace
            _buildSavingPaceSection(
              context,
              averageDailySaving: averageDailySaving,
              requiredDailySaving: requiredDailySaving,
              requiredMonthlySaving: requiredMonthlySaving,
              canForecast: canForecast,
            ),

            const SizedBox(height: 18),

            // Guidance
            _buildForecastGuidance(
              context,
              goal,
              canForecast: canForecast,
              statusColor: statusColor,
            ),

            // Scenarios
            if (canForecast) _buildScenarioSection(context, goal),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressIndicator(
    BuildContext context, {
    required double percentage,
    required double progress,
    required Color statusColor,
  }) {
    final theme = Theme.of(context);

    return SizedBox(
      width: 104,
      height: 104,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 104,
            height: 104,
            child: CircularProgressIndicator(
              value: 1,
              strokeWidth: 8,
              color: theme.colorScheme.surfaceContainerHighest,
            ),
          ),
          SizedBox(
            width: 104,
            height: 104,
            child: CircularProgressIndicator(
              value: progress,
              strokeWidth: 8,
              strokeCap: StrokeCap.round,
              color: statusColor,
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${percentage.toStringAsFixed(0)}%',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                'complete',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(.55),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTargetSummary(
    BuildContext context, {
    required double saved,
    required double target,
    required double remaining,
  }) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Current progress',
          style: theme.textTheme.labelLarge?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(.58),
          ),
        ),
        const SizedBox(height: 5),
        Text(
          _money(saved),
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w800,
            letterSpacing: -.5,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          'of ${_money(target)} target',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(.60),
          ),
        ),
        const SizedBox(height: 13),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
          decoration: BoxDecoration(
            color: _goalAmber.withOpacity(.10),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '${_money(remaining)} remaining',
            style: theme.textTheme.labelLarge?.copyWith(
              color: _goalAmberDark,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMetric(
    BuildContext context,
    String label,
    String value,
    IconData icon,
  ) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: _goalAmber.withOpacity(.10),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: _goalAmber),
        ),
        const SizedBox(width: 9),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(.58),
                ),
              ),
              const SizedBox(height: 3),
              Text(
                value,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _sectionMiniTitle(BuildContext context, String title, IconData icon) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Icon(icon, size: 19, color: _goalAmber),
        const SizedBox(width: 8),
        Text(
          title,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // READINESS
  // ============================================================

  Widget _buildReadinessCard(
    BuildContext context, {
    required int daysElapsed,
    required int minimumDays,
    required double readiness,
  }) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final remainingDays = (minimumDays - daysElapsed).clamp(0, minimumDays);

    final title = minimumDays > 0
        ? 'Building forecast confidence'
        : 'More saving history needed';

    final description = minimumDays > 0
        ? remainingDays > 0
              ? 'PesaPulse needs more saving history before it can estimate a reliable completion date.'
              : 'Your goal has enough history for forecasting.'
        : 'Continue recording savings to build enough history for a forecast.';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _goalAmber.withOpacity(.07),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _goalAmber.withOpacity(.14)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: _goalAmber.withOpacity(.10),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: const Icon(
                  Icons.hourglass_top_rounded,
                  size: 20,
                  color: _goalAmber,
                ),
              ),
              const SizedBox(width: 11),
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
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurface.withOpacity(.67),
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (minimumDays > 0) ...[
            const SizedBox(height: 15),
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(99),
                    child: LinearProgressIndicator(
                      value: readiness,
                      minHeight: 8,
                      backgroundColor: scheme.surfaceContainerHighest,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        _goalAmber,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '$daysElapsed / $minimumDays days',
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: _goalAmberDark,
                  ),
                ),
              ],
            ),
            if (remainingDays > 0) ...[
              const SizedBox(height: 8),
              Text(
                '$remainingDays more ${remainingDays == 1 ? 'day' : 'days'} of history will improve forecast readiness.',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: scheme.onSurface.withOpacity(.58),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildConfidenceCard(
    BuildContext context, {
    required String confidence,
    required String? message,
    required Color color,
  }) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(.07),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withOpacity(.15)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(.10),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.analytics_rounded, color: color, size: 20),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _confidenceTitle(confidence),
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  message ??
                      'The current forecast is based on the available saving history.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurface.withOpacity(.67),
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
  // SAVING PACE
  // ============================================================

  Widget _buildSavingPaceSection(
    BuildContext context, {
    required double averageDailySaving,
    required double requiredDailySaving,
    required double requiredMonthlySaving,
    required bool canForecast,
  }) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionMiniTitle(context, 'Saving pace', Icons.speed_rounded),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            final compact = ResponsiveHelper.useCompactLayout(context);

            final items = [
              (
                'Recorded average',
                _money(averageDailySaving),
                Icons.savings_outlined,
              ),
              (
                'Needed per day',
                requiredDailySaving > 0 ? _money(requiredDailySaving) : '—',
                Icons.today_outlined,
              ),
              (
                'Needed per month',
                requiredMonthlySaving > 0 ? _money(requiredMonthlySaving) : '—',
                Icons.calendar_month_outlined,
              ),
            ];

            if (compact || constraints.maxWidth < 720) {
              return Column(
                children: [
                  for (var i = 0; i < items.length; i++) ...[
                    if (i > 0) const SizedBox(height: 9),
                    _buildPaceItem(
                      context,
                      title: items[i].$1,
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
                  if (i > 0) const SizedBox(width: 10),
                  Expanded(
                    child: _buildPaceItem(
                      context,
                      title: items[i].$1,
                      value: items[i].$2,
                      icon: items[i].$3,
                    ),
                  ),
                ],
              ],
            );
          },
        ),
        if (!canForecast) ...[
          const SizedBox(height: 10),
          Text(
            'The recorded average is shown for context only. PesaPulse will use it for forecasting after enough history is available.',
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(.58),
              height: 1.4,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildPaceItem(
    BuildContext context, {
    required String title,
    required String value,
    required IconData icon,
  }) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withOpacity(.40),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 35,
            height: 35,
            decoration: BoxDecoration(
              color: _goalAmber.withOpacity(.10),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: _goalAmber),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(.58),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall?.copyWith(
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

  // ============================================================
  // GUIDANCE
  // ============================================================

  Widget _buildForecastGuidance(
    BuildContext context,
    Map<String, dynamic> goal, {
    required bool canForecast,
    required Color statusColor,
  }) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final message =
        goal['confidence_message']?.toString() ??
        goal['recommendation']?.toString() ??
        'More saving history is needed before a reliable forecast can be produced.';

    final recommendation = goal['recommendation']?.toString() ?? message;

    if (!canForecast) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _goalAmber.withOpacity(.07),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: _goalAmber.withOpacity(.12)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.lightbulb_outline_rounded, color: _goalAmber),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'What happens next?',
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: _goalAmberDark,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    message,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurface.withOpacity(.72),
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

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(.07),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: statusColor.withOpacity(.14)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: statusColor.withOpacity(.10),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.lightbulb_outline_rounded,
              color: statusColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Forecast guidance',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  recommendation,
                  style: theme.textTheme.bodySmall?.copyWith(
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
  // SCENARIOS
  // ============================================================

  Widget _buildScenarioSection(
    BuildContext context,
    Map<String, dynamic> goal,
  ) {
    final scenarios = goal['scenarios'];

    if (scenarios is! Map) {
      return const SizedBox.shrink();
    }

    final scenarioMap = Map<String, dynamic>.from(scenarios);

    if (scenarioMap.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionMiniTitle(
            context,
            'Saving pace scenarios',
            Icons.compare_arrows_rounded,
          ),
          const SizedBox(height: 6),
          Text(
            'See how different saving paces could affect your completion date.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(.60),
            ),
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final compact = ResponsiveHelper.useCompactLayout(context);

              final names = [
                ('slower', '10% slower'),
                ('current', 'Current pace'),
                ('faster', '10% faster'),
              ];

              if (compact || constraints.maxWidth < 720) {
                return Column(
                  children: [
                    for (var i = 0; i < names.length; i++) ...[
                      if (i > 0) const SizedBox(height: 10),
                      _buildScenarioCard(
                        context,
                        name: names[i].$1,
                        label: names[i].$2,
                        data: scenarioMap[names[i].$1] is Map
                            ? Map<String, dynamic>.from(
                                scenarioMap[names[i].$1],
                              )
                            : {},
                      ),
                    ],
                  ],
                );
              }

              return Row(
                children: [
                  for (var i = 0; i < names.length; i++) ...[
                    if (i > 0) const SizedBox(width: 10),
                    Expanded(
                      child: _buildScenarioCard(
                        context,
                        name: names[i].$1,
                        label: names[i].$2,
                        data: scenarioMap[names[i].$1] is Map
                            ? Map<String, dynamic>.from(
                                scenarioMap[names[i].$1],
                              )
                            : {},
                      ),
                    ),
                  ],
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildScenarioCard(
    BuildContext context, {
    required String name,
    required String label,
    required Map<String, dynamic> data,
  }) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final saving = _toDouble(data['daily_saving']);

    final completionDate = data['completion_date'];

    final meetsTarget = data['meets_target_date'];

    final Color accent;

    final IconData icon;

    switch (name) {
      case 'faster':
        accent = Colors.green;
        icon = Icons.keyboard_double_arrow_up_rounded;
        break;

      case 'slower':
        accent = Colors.orange;
        icon = Icons.keyboard_double_arrow_down_rounded;
        break;

      default:
        accent = _goalAmber;
        icon = Icons.sync_rounded;
    }

    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accent.withOpacity(.14)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: accent.withOpacity(.09),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 18, color: accent),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  label,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 13),
          Text(
            _money(saving),
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'per day',
            style: theme.textTheme.labelSmall?.copyWith(
              color: scheme.onSurface.withOpacity(.55),
            ),
          ),
          const SizedBox(height: 11),
          Text(
            completionDate == null
                ? 'Completion date unavailable'
                : 'Completion: ${_date(completionDate)}',
            style: theme.textTheme.bodySmall?.copyWith(height: 1.35),
          ),
          if (meetsTarget != null) ...[
            const SizedBox(height: 8),
            _statusChip(
              context,
              label: meetsTarget == true
                  ? 'Meets target date'
                  : 'Misses target date',
              color: meetsTarget == true ? Colors.green : scheme.error,
              icon: meetsTarget == true
                  ? Icons.check_circle_outline_rounded
                  : Icons.warning_amber_rounded,
            ),
          ],
        ],
      ),
    );
  }

  // ============================================================
  // DATA QUALITY
  // ============================================================

  Widget _buildDataQuality(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final goalsAvailable = _toInt(_dataQuality['goals_available']);

    final withTargetDates = _toInt(_dataQuality['goals_with_target_dates']);

    final withSavings = _toInt(_dataQuality['goals_with_savings']);

    final withHistory = _toInt(_dataQuality['goals_with_sufficient_history']);

    final canForecast = _dataQuality['can_forecast'] == true;

    final minimumDays = _toInt(_dataQuality['minimum_forecast_history_days']);

    final paceBasis = _dataQuality['pace_basis']?.toString() ?? '';

    final note = _dataQuality['note']?.toString() ?? '';

    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: scheme.outline.withOpacity(.08)),
      ),
      child: Padding(
        padding: EdgeInsets.all(ResponsiveHelper.cardPadding(context)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: _goalAmber.withOpacity(.10),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Icon(
                    Icons.fact_check_outlined,
                    color: _goalAmber,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Forecast data',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'How much information PesaPulse has available.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurface.withOpacity(.58),
                        ),
                      ),
                    ],
                  ),
                ),
                _statusChip(
                  context,
                  label: canForecast ? 'Ready' : 'Building',
                  color: canForecast ? Colors.green : _goalAmber,
                  icon: canForecast
                      ? Icons.check_circle_outline_rounded
                      : Icons.hourglass_top_rounded,
                ),
              ],
            ),
            const SizedBox(height: 18),
            _buildQualityRow(context, 'Active goals', '$goalsAvailable'),
            _buildQualityRow(context, 'With target dates', '$withTargetDates'),
            _buildQualityRow(context, 'With savings', '$withSavings'),
            _buildQualityRow(context, 'Enough history', '$withHistory'),
            _buildQualityRow(context, 'Minimum history', '$minimumDays days'),
            if (paceBasis.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                'Forecast basis',
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                paceBasis,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: scheme.onSurface.withOpacity(.62),
                  height: 1.4,
                ),
              ),
            ],
            if (note.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(13),
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHighest.withOpacity(.45),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      size: 18,
                      color: scheme.onSurface.withOpacity(.60),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        note,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurface.withOpacity(.66),
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
                color: theme.colorScheme.onSurface.withOpacity(.58),
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
  // ERROR
  // ============================================================

  Widget _buildErrorState(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Padding(
          padding: EdgeInsets.all(ResponsiveHelper.cardPadding(context)),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: scheme.surface,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: scheme.error.withOpacity(.12)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: scheme.error.withOpacity(.08),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Icon(
                    Icons.cloud_off_rounded,
                    size: 30,
                    color: scheme.error,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Unable to load goal forecast',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _errorMessage ??
                      'Something went wrong while loading the forecast.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurface.withOpacity(.66),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: _loadForecast,
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
  // EMPTY STATE
  // ============================================================

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Container(
      padding: EdgeInsets.all(ResponsiveHelper.cardPadding(context)),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: scheme.outline.withOpacity(.08)),
      ),
      child: Column(
        children: [
          Container(
            width: 62,
            height: 62,
            decoration: BoxDecoration(
              color: _goalAmber.withOpacity(.10),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(Icons.flag_outlined, size: 30, color: _goalAmber),
          ),
          const SizedBox(height: 14),
          Text(
            'No active goals yet',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Create a savings goal and PesaPulse will begin building forecasting insights as you make progress.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: scheme.onSurface.withOpacity(.62),
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // CONTENT
  // ============================================================

  Widget _buildContent(BuildContext context) {
    final goals = _goals;

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
                  _buildHero(context),

                  SizedBox(height: ResponsiveHelper.sectionSpacing(context)),

                  _sectionTitle(
                    context,
                    'At a glance',
                    subtitle:
                        'A quick view of your current goal forecast status.',
                    icon: Icons.insights_rounded,
                  ),

                  _buildSummaryGrid(context),

                  SizedBox(height: ResponsiveHelper.sectionSpacing(context)),

                  _sectionTitle(
                    context,
                    'Goal forecasts',
                    subtitle:
                        'Future estimates are generated from the saving history available for each goal.',
                    icon: Icons.auto_graph_rounded,
                  ),

                  if (goals.isEmpty)
                    _buildEmptyState(context)
                  else
                    Column(
                      children: [
                        for (var i = 0; i < goals.length; i++) ...[
                          _buildGoalCard(context, goals[i]),
                          if (i < goals.length - 1)
                            SizedBox(
                              height: ResponsiveHelper.sectionSpacing(context),
                            ),
                        ],
                      ],
                    ),

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

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: AdaptiveAppBar(
        title: 'Goal Forecast',
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
