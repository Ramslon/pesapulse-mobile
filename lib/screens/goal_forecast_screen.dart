import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../services/api_services.dart';
import '../utils/responsive_helper.dart';

import '../widgets/app/adaptive_app_bar.dart';
import '../widgets/app/app_scaffold.dart';
import '../widgets/premium/premium_state_widgets.dart';

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

  // ===========================================================================
  // LIFECYCLE
  // ===========================================================================

  @override
  void initState() {
    super.initState();
    _loadForecast();
  }

  // ===========================================================================
  // DATA
  // ===========================================================================

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

  // ===========================================================================
  // STATUS / COLORS
  // ===========================================================================

  Color _statusColor(BuildContext context, String status) {
    final scheme = Theme.of(context).colorScheme;

    switch (status) {
      case 'completed':
        return Colors.green;

      case 'ahead':
        return Colors.green;

      case 'on_track':
        return _goalAmberDark;

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
        return _goalAmberDark;

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

  // ===========================================================================
  // COMMON UI
  // ===========================================================================

  Widget _card(
    BuildContext context, {
    required Widget child,
    EdgeInsetsGeometry? padding,
  }) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: padding ?? EdgeInsets.all(ResponsiveHelper.cardPadding(context)),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.dividerColor.withOpacity(.70)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.025),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _sectionTitle(
    BuildContext context,
    String title, {
    String? subtitle,
    IconData? icon,
  }) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (icon != null) ...[
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: _premiumPurple.withOpacity(.09),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, size: 20, color: _premiumPurple),
          ),
          const SizedBox(width: 11),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: -.2,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 4),
                Text(
                  subtitle,
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
    );
  }

  Widget _miniSectionTitle(BuildContext context, String title, IconData icon) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Icon(icon, size: 19, color: _goalAmberDark),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }

  Widget _statusChip(
    BuildContext context, {
    required String label,
    required Color color,
    IconData? icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(.09),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: color.withOpacity(.14)),
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
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // HERO
  // ===========================================================================

  Widget _buildHero(BuildContext context) {
    final theme = Theme.of(context);

    final asOf = _data['as_of']?.toString();

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(ResponsiveHelper.cardPadding(context)),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(
          ResponsiveHelper.useCompactLayout(context) ? 22 : 26,
        ),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_premiumPurple, _premiumPurpleDark],
        ),
        boxShadow: [
          BoxShadow(
            color: _premiumPurple.withOpacity(.18),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 650;

          final mainContent = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 9,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    'Goal Forecast',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -.6,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: _goalAmber,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'PREMIUM',
                      style: TextStyle(
                        color: _premiumPurpleDark,
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                        letterSpacing: .6,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              Text(
                'See when your goals may be completed and understand how your saving pace affects the forecast.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.white.withOpacity(.76),
                  height: 1.5,
                ),
              ),

              const SizedBox(height: 16),

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
          );

          if (!wide) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(.10),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.auto_awesome_rounded,
                    color: Colors.white,
                    size: 25,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(child: mainContent),
              ],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: mainContent),
              const SizedBox(width: 24),
              Container(
                width: 92,
                height: 92,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(.08),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white.withOpacity(.12)),
                ),
                child: const Icon(
                  Icons.auto_graph_rounded,
                  color: _goalAmber,
                  size: 42,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _heroChip({required IconData icon, required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(.18),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(.08)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: Colors.white.withOpacity(.90)),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // SUMMARY
  // ===========================================================================

  Widget _buildSummaryGrid(BuildContext context) {
    final theme = Theme.of(context);

    final totalGoals = _toInt(_summary['goals_available']);

    final forecasted = _toInt(_summary['goals_forecasted']);

    final completed = _toInt(_summary['completed_goals']);

    final attention =
        _toInt(_summary['behind_goals']) + _toInt(_summary['overdue_goals']);

    final items = [
      ('Goals', '$totalGoals', Icons.flag_rounded, _goalAmber),
      ('Forecasted', '$forecasted', Icons.auto_graph_rounded, _premiumPurple),
      ('Completed', '$completed', Icons.check_circle_rounded, Colors.green),
      (
        'Need attention',
        '$attention',
        Icons.warning_amber_rounded,
        attention > 0 ? Colors.orange : theme.colorScheme.onSurfaceVariant,
      ),
    ];

    final columns = ResponsiveHelper.gridColumns(
      context,
      mobilePortrait: 2,
      mobileLandscape: 4,
      tabletPortrait: 4,
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
        mainAxisExtent: _summaryCardHeight(context),
      ),
      itemBuilder: (context, index) {
        final item = items[index];

        return _buildSummaryMetric(
          context,
          title: item.$1,
          value: item.$2,
          icon: item.$3,
          color: item.$4,
        );
      },
    );
  }

  double _summaryCardHeight(BuildContext context) {
    if (ResponsiveHelper.isMobilePortrait(context)) {
      return 105;
    }

    if (ResponsiveHelper.isMobileLandscape(context)) {
      return 92;
    }

    if (ResponsiveHelper.isTabletPortrait(context)) {
      return 105;
    }

    return 112;
  }

  Widget _buildSummaryMetric(
    BuildContext context, {
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    final theme = Theme.of(context);

    return _card(
      context,
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 39,
            height: 39,
            decoration: BoxDecoration(
              color: color.withOpacity(.10),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 20),
          ),

          const SizedBox(width: 10),

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
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 4),

                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    value,
                    maxLines: 1,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
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

  // ===========================================================================
  // GOAL CARD
  // ===========================================================================

  Widget _buildGoalCard(BuildContext context, Map<String, dynamic> goal) {
    final status = goal['forecast_status']?.toString() ?? 'insufficient_data';

    final confidence = goal['confidence']?.toString() ?? 'insufficient_data';

    final title = goal['title']?.toString() ?? 'Goal';

    final target = _toDouble(goal['target_amount']);

    final saved = _toDouble(goal['saved_amount']);

    final remaining = _toDouble(goal['remaining_amount']);

    final progressPercentage = _toDouble(goal['progress_percentage']);

    final progress = (progressPercentage / 100).clamp(0.0, 1.0);

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

    return _card(
      context,
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildGoalHeader(
            context,
            title: title,
            status: status,
            confidence: confidence,
            statusColor: statusColor,
            confidenceColor: confidenceColor,
          ),

          Padding(
            padding: EdgeInsets.all(ResponsiveHelper.cardPadding(context)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildProgressOverview(
                  context,
                  progressPercentage: progressPercentage,
                  progress: progress,
                  saved: saved,
                  target: target,
                  remaining: remaining,
                ),

                SizedBox(height: ResponsiveHelper.sectionSpacing(context)),

                _buildForecastTimeline(
                  context,
                  targetDate: targetDate,
                  projectedDate: projectedDate,
                  daysRemaining: daysRemaining,
                ),

                SizedBox(height: ResponsiveHelper.sectionSpacing(context)),

                if (!canForecast)
                  _buildReadinessCard(
                    context,
                    daysElapsed: daysElapsed,
                    minimumDays: minimumDays,
                    readiness: readiness,
                  )
                else
                  _buildConfidenceCard(
                    context,
                    confidence: confidence,
                    message: goal['confidence_message']?.toString(),
                    color: confidenceColor,
                  ),

                SizedBox(height: ResponsiveHelper.sectionSpacing(context)),

                _buildSavingPaceSection(
                  context,
                  averageDailySaving: averageDailySaving,
                  requiredDailySaving: requiredDailySaving,
                  requiredMonthlySaving: requiredMonthlySaving,
                  canForecast: canForecast,
                ),

                SizedBox(height: ResponsiveHelper.sectionSpacing(context)),

                _buildForecastGuidance(
                  context,
                  goal,
                  canForecast: canForecast,
                  statusColor: statusColor,
                ),

                if (canForecast) _buildScenarioSection(context, goal),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGoalHeader(
    BuildContext context, {
    required String title,
    required String status,
    required String confidence,
    required Color statusColor,
    required Color confidenceColor,
  }) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(ResponsiveHelper.cardPadding(context)),
      decoration: BoxDecoration(
        color: _premiumPurple.withOpacity(.045),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        border: Border(
          bottom: BorderSide(color: theme.dividerColor.withOpacity(.65)),
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final narrow = constraints.maxWidth < 520;

          final titleSection = Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(.10),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(_statusIcon(status), color: statusColor, size: 22),
              ),

              const SizedBox(width: 11),

              Expanded(
                child: Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                    letterSpacing: -.3,
                  ),
                ),
              ),
            ],
          );

          final chips = Wrap(
            spacing: 7,
            runSpacing: 7,
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
          );

          if (narrow) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [titleSection, const SizedBox(height: 12), chips],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(child: titleSection),
              const SizedBox(width: 16),
              Flexible(child: chips),
            ],
          );
        },
      ),
    );
  }

  // ===========================================================================
  // PROGRESS
  // ===========================================================================

  Widget _buildProgressOverview(
    BuildContext context, {
    required double progressPercentage,
    required double progress,
    required double saved,
    required double target,
    required double remaining,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact =
            ResponsiveHelper.useCompactLayout(context) ||
            constraints.maxWidth < 600;

        final ring = _buildProgressRing(
          context,
          percentage: progressPercentage,
          progress: progress,
        );

        final summary = _buildTargetSummary(
          context,
          saved: saved,
          target: target,
          remaining: remaining,
        );

        if (compact) {
          return Column(children: [ring, const SizedBox(height: 18), summary]);
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(width: 145, child: Center(child: ring)),
            const SizedBox(width: 24),
            Expanded(child: summary),
          ],
        );
      },
    );
  }

  Widget _buildProgressRing(
    BuildContext context, {
    required double percentage,
    required double progress,
  }) {
    final theme = Theme.of(context);

    return SizedBox(
      width: 126,
      height: 126,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 126,
            height: 126,
            child: CircularProgressIndicator(
              value: 1,
              strokeWidth: 10,
              color: theme.colorScheme.surfaceContainerHighest,
            ),
          ),

          SizedBox(
            width: 126,
            height: 126,
            child: CircularProgressIndicator(
              value: progress,
              strokeWidth: 10,
              strokeCap: StrokeCap.round,
              color: _goalAmber,
            ),
          ),

          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  '${percentage.toStringAsFixed(0)}%',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: _goalAmberDark,
                  ),
                ),
              ),
              Text(
                'complete',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
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
            color: theme.colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w600,
          ),
        ),

        const SizedBox(height: 5),

        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            _money(saved),
            maxLines: 1,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w900,
              letterSpacing: -.5,
            ),
          ),
        ),

        const SizedBox(height: 3),

        Text(
          'of ${_money(target)} target',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),

        const SizedBox(height: 14),

        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          decoration: BoxDecoration(
            color: _goalAmber.withOpacity(.09),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.account_balance_wallet_rounded,
                size: 16,
                color: _goalAmberDark,
              ),
              const SizedBox(width: 7),
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '${_money(remaining)} remaining',
                    maxLines: 1,
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: _goalAmberDark,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // TIMELINE
  // ===========================================================================

  Widget _buildForecastTimeline(
    BuildContext context, {
    required dynamic targetDate,
    required dynamic projectedDate,
    required dynamic daysRemaining,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _miniSectionTitle(context, 'Forecast timeline', Icons.timeline_rounded),

        const SizedBox(height: 12),

        LayoutBuilder(
          builder: (context, constraints) {
            final compact =
                ResponsiveHelper.useCompactLayout(context) ||
                constraints.maxWidth < 700;

            final items = [
              (
                'Target date',
                targetDate == null ? 'No deadline' : _date(targetDate),
                Icons.event_rounded,
                _goalAmber,
              ),
              (
                'Days remaining',
                targetDate == null ? '—' : _daysLabel(daysRemaining),
                Icons.schedule_rounded,
                _premiumPurple,
              ),
              (
                'Projected completion',
                projectedDate == null
                    ? 'Not available yet'
                    : _date(projectedDate),
                Icons.auto_graph_rounded,
                Colors.green,
              ),
            ];

            if (compact) {
              return Column(
                children: [
                  for (var i = 0; i < items.length; i++) ...[
                    if (i > 0) const SizedBox(height: 9),
                    _timelineMetric(
                      context,
                      label: items[i].$1,
                      value: items[i].$2,
                      icon: items[i].$3,
                      color: items[i].$4,
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
                    child: _timelineMetric(
                      context,
                      label: items[i].$1,
                      value: items[i].$2,
                      icon: items[i].$3,
                      color: items[i].$4,
                    ),
                  ),
                ],
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _timelineMetric(
    BuildContext context, {
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: color.withOpacity(.055),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: color.withOpacity(.10)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: color.withOpacity(.10),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 17, color: color),
          ),

          const SizedBox(width: 9),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  value,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // READINESS
  // ===========================================================================

  Widget _buildReadinessCard(
    BuildContext context, {
    required int daysElapsed,
    required int minimumDays,
    required double readiness,
  }) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final remainingDays = (minimumDays - daysElapsed).clamp(0, minimumDays);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _goalAmber.withOpacity(.065),
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
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _goalAmber.withOpacity(.10),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.hourglass_top_rounded,
                  color: _goalAmberDark,
                  size: 21,
                ),
              ),

              const SizedBox(width: 11),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Building forecast confidence',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),

                    const SizedBox(height: 4),

                    Text(
                      'More saving history is needed before PesaPulse can estimate a reliable completion date.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
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
                    borderRadius: BorderRadius.circular(30),
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

                const SizedBox(width: 11),

                Text(
                  '$daysElapsed / $minimumDays days',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: _goalAmberDark,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),

            if (remainingDays > 0) ...[
              const SizedBox(height: 8),

              Text(
                '$remainingDays more ${remainingDays == 1 ? 'day' : 'days'} of history will improve forecast readiness.',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: scheme.onSurfaceVariant,
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

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(.065),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withOpacity(.14)),
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
            child: Icon(Icons.analytics_rounded, color: color, size: 21),
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
                    color: theme.colorScheme.onSurfaceVariant,
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

  // ===========================================================================
  // SAVING PACE
  // ===========================================================================

  Widget _buildSavingPaceSection(
    BuildContext context, {
    required double averageDailySaving,
    required double requiredDailySaving,
    required double requiredMonthlySaving,
    required bool canForecast,
  }) {
    final theme = Theme.of(context);

    final items = [
      ('Recorded average', _money(averageDailySaving), Icons.savings_rounded),
      (
        'Needed per day',
        requiredDailySaving > 0 ? _money(requiredDailySaving) : '—',
        Icons.today_rounded,
      ),
      (
        'Needed per month',
        requiredMonthlySaving > 0 ? _money(requiredMonthlySaving) : '—',
        Icons.calendar_month_rounded,
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _miniSectionTitle(context, 'Saving pace', Icons.speed_rounded),

        const SizedBox(height: 12),

        LayoutBuilder(
          builder: (context, constraints) {
            final compact =
                ResponsiveHelper.useCompactLayout(context) ||
                constraints.maxWidth < 720;

            if (compact) {
              return Column(
                children: [
                  for (var i = 0; i < items.length; i++) ...[
                    if (i > 0) const SizedBox(height: 9),
                    _paceItem(
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
                    child: _paceItem(
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
          const SizedBox(height: 9),

          Text(
            'The recorded average is shown for context. Forecasting will become more reliable as saving history grows.',
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.4,
            ),
          ),
        ],
      ],
    );
  }

  Widget _paceItem(
    BuildContext context, {
    required String title,
    required String value,
    required IconData icon,
  }) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withOpacity(.35),
        borderRadius: BorderRadius.circular(15),
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
            child: Icon(icon, color: _goalAmberDark, size: 18),
          ),

          const SizedBox(width: 9),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
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
                    value,
                    maxLines: 1,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w900,
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

  // ===========================================================================
  // GUIDANCE
  // ===========================================================================

  Widget _buildForecastGuidance(
    BuildContext context,
    Map<String, dynamic> goal, {
    required bool canForecast,
    required Color statusColor,
  }) {
    final theme = Theme.of(context);

    final message =
        goal['confidence_message']?.toString() ??
        goal['recommendation']?.toString() ??
        'More saving history is needed before a reliable forecast can be produced.';

    final recommendation = goal['recommendation']?.toString() ?? message;

    final color = canForecast ? statusColor : _goalAmberDark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(.065),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withOpacity(.13)),
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
            child: Icon(Icons.lightbulb_rounded, color: color, size: 20),
          ),

          const SizedBox(width: 11),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  canForecast ? 'Forecast guidance' : 'What happens next?',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),

                const SizedBox(height: 5),

                Text(
                  recommendation,
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

  // ===========================================================================
  // SCENARIOS
  // ===========================================================================

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

    final names = [
      (
        'slower',
        '10% slower',
        Icons.keyboard_double_arrow_down_rounded,
        Colors.orange,
      ),
      ('current', 'Current pace', Icons.sync_rounded, _goalAmberDark),
      (
        'faster',
        '10% faster',
        Icons.keyboard_double_arrow_up_rounded,
        Colors.green,
      ),
    ];

    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _miniSectionTitle(
            context,
            'Saving pace scenarios',
            Icons.compare_arrows_rounded,
          ),

          const SizedBox(height: 5),

          Text(
            'See how different saving paces could affect your completion date.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              height: 1.4,
            ),
          ),

          const SizedBox(height: 12),

          LayoutBuilder(
            builder: (context, constraints) {
              final compact =
                  ResponsiveHelper.useCompactLayout(context) ||
                  constraints.maxWidth < 720;

              if (compact) {
                return Column(
                  children: [
                    for (var i = 0; i < names.length; i++) ...[
                      if (i > 0) const SizedBox(height: 10),
                      _scenarioCard(
                        context,
                        name: names[i].$1,
                        label: names[i].$2,
                        icon: names[i].$3,
                        accent: names[i].$4,
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
                      child: _scenarioCard(
                        context,
                        name: names[i].$1,
                        label: names[i].$2,
                        icon: names[i].$3,
                        accent: names[i].$4,
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

  Widget _scenarioCard(
    BuildContext context, {
    required String name,
    required String label,
    required IconData icon,
    required Color accent,
    required Map<String, dynamic> data,
  }) {
    final theme = Theme.of(context);

    final saving = _toDouble(data['daily_saving']);

    final completionDate = data['completion_date'];

    final meetsTarget = data['meets_target_date'];

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: accent.withOpacity(.14)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 35,
                height: 35,
                decoration: BoxDecoration(
                  color: accent.withOpacity(.09),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: accent, size: 18),
              ),

              const SizedBox(width: 9),

              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 13),

          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              _money(saving),
              maxLines: 1,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w900,
              ),
            ),
          ),

          const SizedBox(height: 2),

          Text(
            'per day',
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),

          const SizedBox(height: 10),

          Text(
            completionDate == null
                ? 'Completion date unavailable'
                : 'Completion: ${_date(completionDate)}',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(height: 1.35),
          ),

          if (meetsTarget != null) ...[
            const SizedBox(height: 9),

            _statusChip(
              context,
              label: meetsTarget == true
                  ? 'Meets target date'
                  : 'Misses target date',
              color: meetsTarget == true
                  ? Colors.green
                  : theme.colorScheme.error,
              icon: meetsTarget == true
                  ? Icons.check_circle_outline_rounded
                  : Icons.warning_amber_rounded,
            ),
          ],
        ],
      ),
    );
  }

  // ===========================================================================
  // DATA QUALITY
  // ===========================================================================

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

    return _card(
      context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 39,
                height: 39,
                decoration: BoxDecoration(
                  color: _premiumPurple.withOpacity(.09),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: const Icon(
                  Icons.fact_check_rounded,
                  color: _premiumPurple,
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

                    const SizedBox(height: 3),

                    Text(
                      'How much information PesaPulse has available for forecasting.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 10),

              _statusChip(
                context,
                label: canForecast ? 'Ready' : 'Building',
                color: canForecast ? Colors.green : _goalAmberDark,
                icon: canForecast
                    ? Icons.check_circle_outline_rounded
                    : Icons.hourglass_top_rounded,
              ),
            ],
          ),

          const SizedBox(height: 18),

          _qualityRow(context, 'Active goals', '$goalsAvailable'),

          _qualityRow(context, 'With target dates', '$withTargetDates'),

          _qualityRow(context, 'With savings', '$withSavings'),

          _qualityRow(context, 'Enough history', '$withHistory'),

          _qualityRow(context, 'Minimum history', '$minimumDays days'),

          if (paceBasis.isNotEmpty) ...[
            const SizedBox(height: 8),

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
                color: scheme.onSurfaceVariant,
                height: 1.4,
              ),
            ),
          ],

          if (note.isNotEmpty) ...[
            const SizedBox(height: 12),

            Container(
              padding: const EdgeInsets.all(13),
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHighest.withOpacity(.40),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    size: 18,
                    color: scheme.onSurfaceVariant,
                  ),

                  const SizedBox(width: 8),

                  Expanded(
                    child: Text(
                      note,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
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

  Widget _qualityRow(BuildContext context, String label, String value) {
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
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),

          const SizedBox(width: 12),

          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // EMPTY STATE
  // ===========================================================================

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);

    return _card(
      context,
      child: Column(
        children: [
          Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              color: _goalAmber.withOpacity(.10),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.flag_outlined,
              color: _goalAmberDark,
              size: 32,
            ),
          ),

          const SizedBox(height: 16),

          Text(
            'No active goals yet',
            textAlign: TextAlign.center,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),

          const SizedBox(height: 7),

          Text(
            'Create a savings goal and PesaPulse will begin building forecasting insights as you make progress.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // ERROR
  // ===========================================================================

  Widget _buildErrorState(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Padding(
          padding: EdgeInsets.all(ResponsiveHelper.cardPadding(context)),
          child: _card(
            context,
            padding: const EdgeInsets.all(24),
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
                    color: scheme.error,
                    size: 30,
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
                    color: scheme.onSurfaceVariant,
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

  // ===========================================================================
  // CONTENT
  // ===========================================================================

  Widget _buildContent(BuildContext context) {
    final goals = _goals;

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
                16,
                ResponsiveHelper.horizontalPadding(context),
                sectionSpacing * 2,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildHero(context),

                  SizedBox(height: sectionSpacing),

                  _sectionTitle(
                    context,
                    'At a glance',
                    subtitle:
                        'A quick view of your current goal forecast status.',
                    icon: Icons.insights_rounded,
                  ),

                  const SizedBox(height: 14),

                  _buildSummaryGrid(context),

                  SizedBox(height: sectionSpacing),

                  _sectionTitle(
                    context,
                    'Goal forecasts',
                    subtitle:
                        'Forecasts are based on the saving history available for each goal.',
                    icon: Icons.auto_graph_rounded,
                  ),

                  const SizedBox(height: 14),

                  if (goals.isEmpty)
                    _buildEmptyState(context)
                  else
                    Column(
                      children: [
                        for (var i = 0; i < goals.length; i++) ...[
                          _buildGoalCard(context, goals[i]),
                          if (i < goals.length - 1)
                            SizedBox(height: sectionSpacing),
                        ],
                      ],
                    ),

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

  // ===========================================================================
  // BUILD
  // ===========================================================================

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
