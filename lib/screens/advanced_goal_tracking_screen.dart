import 'package:flutter/material.dart';

import '../utils/responsive_helper.dart';
import '../widgets/app/adaptive_app_bar.dart';
import '../widgets/app/app_scaffold.dart';

const Color _premiumPurple = Color(0xFF6D3FD9);
const Color _premiumPurpleDark = Color(0xFF34205F);

const Color _goalAmber = Color(0xFFFFC107);
const Color _goalAmberDark = Color(0xFFF59E0B);

class AdvancedGoalTrackingScreen extends StatelessWidget {
  final Map<String, dynamic> tracking;
  final String currencySymbol;

  const AdvancedGoalTrackingScreen({
    super.key,
    required this.tracking,
    this.currencySymbol = 'KES',
  });

  double _double(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  int _int(dynamic value) {
    if (value is int) {
      return value;
    }

    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  String _money(dynamic value) {
    final amount = _double(value);

    return '$currencySymbol '
        '${amount.toStringAsFixed(2)}';
  }

  String _moneyCompact(dynamic value) {
    final amount = _double(value);

    return '$currencySymbol '
        '${amount.toStringAsFixed(0)}';
  }

  @override
  Widget build(BuildContext context) {
    final compact = ResponsiveHelper.useCompactLayout(context);

    final horizontalPadding = ResponsiveHelper.horizontalPadding(context);

    final sectionSpacing = ResponsiveHelper.sectionSpacing(context);

    final summary = tracking['summary'] as Map<String, dynamic>? ?? {};

    final quality = tracking['data_quality'] as Map<String, dynamic>? ?? {};

    final goals = tracking['goals'] is List
        ? tracking['goals'] as List
        : <dynamic>[];

    return AppScaffold(
      appBar: const AdaptiveAppBar(title: 'Advanced Goal Tracking'),
      body: RefreshIndicator(
        onRefresh: () async {
          // Intentionally left to the parent if a refresh
          // callback is added later.
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          padding: EdgeInsets.fromLTRB(
            horizontalPadding,
            compact ? 12 : 20,
            horizontalPadding,
            compact ? 36 : 48,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: ResponsiveHelper.contentMaxWidth(context),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeroHeader(context),

                  SizedBox(height: sectionSpacing),

                  _buildPortfolioSummary(context, summary),

                  SizedBox(height: sectionSpacing),

                  if (goals.isEmpty) _buildNoGoalsCard(context),

                  ...goals.map(
                    (item) => Padding(
                      padding: EdgeInsets.only(bottom: sectionSpacing),
                      child: _buildGoalIntelligenceCard(
                        context,
                        item as Map<String, dynamic>,
                      ),
                    ),
                  ),

                  _buildDataQuality(context, quality),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeroHeader(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(ResponsiveHelper.cardPadding(context) + 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
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
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(.10),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.track_changes_rounded,
              color: Colors.white,
              size: 27,
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
                        'Premium Goal Intelligence',
                        style: theme.textTheme.titleLarge?.copyWith(
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
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: .5,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 7),

                Text(
                  'Understand your progress, saving pace, '
                  'deadline risk and projected completion.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.white.withOpacity(.72),
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

  Widget _buildPortfolioSummary(
    BuildContext context,
    Map<String, dynamic> summary,
  ) {
    final totalTarget = _moneyCompact(summary['total_target_amount']);

    final totalSaved = _moneyCompact(summary['total_saved_amount']);

    final totalRemaining = _moneyCompact(summary['total_remaining_amount']);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Portfolio Snapshot',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            final spacing = 10.0;
            final width = (constraints.maxWidth - spacing * 2) / 3;

            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: width,
                  child: _summaryTile(
                    context,
                    icon: Icons.flag_outlined,
                    label: 'Target',
                    value: totalTarget,
                  ),
                ),
                SizedBox(width: spacing),
                SizedBox(
                  width: width,
                  child: _summaryTile(
                    context,
                    icon: Icons.savings_outlined,
                    label: 'Saved',
                    value: totalSaved,
                    valueColor: _goalAmber,
                  ),
                ),
                SizedBox(width: spacing),
                SizedBox(
                  width: width,
                  child: _summaryTile(
                    context,
                    icon: Icons.account_balance_wallet_outlined,
                    label: 'Remaining',
                    value: totalRemaining,
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _summaryTile(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withOpacity(.45),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 19, color: _goalAmber),
          const SizedBox(height: 9),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurface.withOpacity(.65),
            ),
          ),
          const SizedBox(height: 3),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w800,
                color: valueColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGoalIntelligenceCard(
    BuildContext context,
    Map<String, dynamic> goal,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final progress = _double(goal['progress_percentage']).clamp(0.0, 100.0);

    final forecastStatus = goal['forecast_status']?.toString() ?? 'unknown';

    final deadlineRisk = goal['deadline_risk']?.toString() ?? 'unknown';

    final daysRemaining = goal['days_remaining'];

    final projectedDate = goal['projected_completion_date']?.toString();

    final milestones = goal['milestones'] is List
        ? goal['milestones'] as List
        : <dynamic>[];

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(ResponsiveHelper.cardPadding(context)),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colorScheme.outline.withOpacity(.10)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.04),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --------------------------------------------------
          // Goal title + status
          // --------------------------------------------------
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      goal['title']?.toString() ?? 'Goal',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'Advanced progress analysis',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurface.withOpacity(.60),
                      ),
                    ),
                  ],
                ),
              ),
              _statusChip(context, forecastStatus),
            ],
          ),

          const SizedBox(height: 22),

          // --------------------------------------------------
          // Progress hero
          // --------------------------------------------------
          Row(
            children: [
              _progressRing(context, progress),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Current Progress',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurface.withOpacity(.65),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${progress.toStringAsFixed(1)}%',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${_money(goal['saved_amount'])} saved',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${_money(goal['remaining_amount'])} remaining',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurface.withOpacity(.65),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 22),

          // --------------------------------------------------
          // Deadline strip
          // --------------------------------------------------
          _deadlinePanel(
            context,
            goal: goal,
            daysRemaining: daysRemaining,
            projectedDate: projectedDate,
            deadlineRisk: deadlineRisk,
          ),

          const SizedBox(height: 18),

          // --------------------------------------------------
          // Saving pace
          // --------------------------------------------------
          _paceComparison(context, goal),

          const SizedBox(height: 18),

          // --------------------------------------------------
          // Schedule comparison
          // --------------------------------------------------
          _scheduleComparison(context, goal),

          const SizedBox(height: 18),

          // --------------------------------------------------
          // Recommendation
          // --------------------------------------------------
          _recommendationPanel(
            context,
            goal['recommendation']?.toString() ??
                'No recommendation available.',
          ),

          const SizedBox(height: 20),

          // --------------------------------------------------
          // Milestones
          // --------------------------------------------------
          Text(
            'Milestones',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),

          const SizedBox(height: 14),

          _milestoneTimeline(context, milestones),
        ],
      ),
    );
  }

  Widget _progressRing(BuildContext context, double progress) {
    final colorScheme = Theme.of(context).colorScheme;

    return SizedBox(
      width: 116,
      height: 116,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircularProgressIndicator(
            value: progress / 100,
            strokeWidth: 10,
            strokeCap: StrokeCap.round,
            backgroundColor: colorScheme.surfaceContainerHighest,
            color: _goalAmber,
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                progress.toStringAsFixed(0),
                style: const TextStyle(
                  fontSize: 25,
                  fontWeight: FontWeight.w900,
                  height: 1,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                '%',
                style: TextStyle(
                  fontSize: 12,
                  color: colorScheme.onSurface.withOpacity(.60),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _deadlinePanel(
    BuildContext context, {
    required Map<String, dynamic> goal,
    required dynamic daysRemaining,
    required String? projectedDate,
    required String deadlineRisk,
  }) {
    final theme = Theme.of(context);

    final riskColor = _riskColor(context, deadlineRisk);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: riskColor.withOpacity(.07),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: riskColor.withOpacity(.16)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.event_available_rounded, color: riskColor, size: 21),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Deadline Tracking',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              _riskChip(context, deadlineRisk),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _smallMetric(
                  context,
                  'Target',
                  goal['target_date']?.toString() ?? 'Not set',
                ),
              ),
              Expanded(
                child: _smallMetric(
                  context,
                  'Days Left',
                  daysRemaining == null ? '—' : '${_int(daysRemaining)}',
                ),
              ),
              Expanded(
                child: _smallMetric(context, 'Projected', projectedDate ?? '—'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _paceComparison(BuildContext context, Map<String, dynamic> goal) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final current = _double(goal['average_daily_saving_since_creation']);

    final required = _double(goal['required_daily_saving']);

    final maxValue = current > required ? current : required;

    final currentRatio = maxValue > 0 ? current / maxValue : 0;

    final requiredRatio = maxValue > 0 ? required / maxValue : 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withOpacity(.42),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.speed_rounded, size: 20, color: _goalAmber),
              const SizedBox(width: 9),
              Text(
                'Saving Pace',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          _paceRow(
            context,
            label: 'Current pace',
            value: _money(current),
            progress: currentRatio.toDouble(),
            color: _goalAmber,
          ),

          const SizedBox(height: 12),

          _paceRow(
            context,
            label: 'Required pace',
            value: _money(required),
            progress: requiredRatio.toDouble(),
            color: _goalAmberDark,
          ),

          const SizedBox(height: 10),

          Text(
            'Required monthly: '
            '${_money(goal['required_monthly_saving'])}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurface.withOpacity(.65),
            ),
          ),
        ],
      ),
    );
  }

  Widget _paceRow(
    BuildContext context, {
    required String label,
    required String value,
    required double progress,
    required Color color,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: Theme.of(context).textTheme.bodySmall),
            Text(value, style: const TextStyle(fontWeight: FontWeight.w800)),
          ],
        ),
        const SizedBox(height: 7),
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: LinearProgressIndicator(
            value: progress.clamp(0.0, 1.0),
            minHeight: 7,
            backgroundColor: colorScheme.surfaceContainerHighest,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _scheduleComparison(BuildContext context, Map<String, dynamic> goal) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final expected = _double(goal['expected_progress_percentage']);

    final variance = _double(goal['progress_variance_percentage']);

    final days = goal['days_ahead_behind'] == null
        ? null
        : _int(goal['days_ahead_behind']);

    final varianceColor = variance >= 0 ? Colors.green : Colors.orange;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outline.withOpacity(.10)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.timeline_rounded, size: 20, color: _goalAmber),
              const SizedBox(width: 9),
              Text(
                'Schedule Position',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _smallMetric(
                  context,
                  'Expected',
                  '${expected.toStringAsFixed(1)}%',
                ),
              ),
              Expanded(
                child: _smallMetric(
                  context,
                  'Actual',
                  '${_double(goal['progress_percentage']).toStringAsFixed(1)}%',
                ),
              ),
              Expanded(
                child: _smallMetric(
                  context,
                  'Variance',
                  '${variance >= 0 ? '+' : ''}'
                      '${variance.toStringAsFixed(1)}%',
                  valueColor: varianceColor,
                ),
              ),
            ],
          ),
          if (days != null) ...[
            const SizedBox(height: 12),
            Text(
              _formatDays(days),
              style: TextStyle(
                color: varianceColor,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _recommendationPanel(BuildContext context, String recommendation) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: _goalAmber.withOpacity(.07),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _goalAmber.withOpacity(.16)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.auto_awesome_rounded, color: _goalAmber, size: 21),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              recommendation,
              style: TextStyle(
                color: colorScheme.onSurface.withOpacity(.78),
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _milestoneTimeline(BuildContext context, List milestones) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      children: milestones.map((item) {
        final milestone = item as Map<String, dynamic>;

        final reached = milestone['reached'] == true;

        final percentage = _int(milestone['percentage']);

        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: reached
                      ? _goalAmber
                      : colorScheme.surfaceContainerHighest,
                ),
                child: Icon(
                  reached ? Icons.check_rounded : Icons.circle_outlined,
                  size: 17,
                  color: reached
                      ? Colors.black87
                      : colorScheme.onSurfaceVariant,
                ),
              ),

              const SizedBox(width: 10),

              Expanded(
                child: Text(
                  '$percentage% milestone',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),

              Text(
                reached ? 'Reached' : 'Not reached',
                style: TextStyle(
                  color: reached
                      ? _goalAmberDark
                      : colorScheme.onSurfaceVariant,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _smallMetric(
    BuildContext context,
    String label,
    String value, {
    Color? valueColor,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: colorScheme.onSurface.withOpacity(.60),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w800,
            color: valueColor,
          ),
        ),
      ],
    );
  }

  Widget _statusChip(BuildContext context, String status) {
    final color = _statusColor(context, status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(.10),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        _formatStatus(status),
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _riskChip(BuildContext context, String risk) {
    final color = _riskColor(context, risk);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(.10),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        _formatStatus(risk),
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _buildDataQuality(BuildContext context, Map<String, dynamic> quality) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withOpacity(.30),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded, size: 19, color: _goalAmber),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              quality['pace_basis']?.toString() ??
                  'Advanced tracking is based on your available goal data.',
              style: TextStyle(
                color: colorScheme.onSurface.withOpacity(.65),
                fontSize: 12,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoGoalsCard(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withOpacity(.35),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Icon(Icons.flag_outlined, color: _goalAmber),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Create an active goal to unlock '
              'advanced tracking insights.',
            ),
          ),
        ],
      ),
    );
  }

  Color _statusColor(BuildContext context, String status) {
    final colorScheme = Theme.of(context).colorScheme;

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
        return colorScheme.onSurfaceVariant;
    }
  }

  Color _riskColor(BuildContext context, String risk) {
    switch (risk) {
      case 'none':
      case 'low':
        return Colors.green;
      case 'medium':
        return Colors.orange;
      case 'high':
        return Theme.of(context).colorScheme.error;
      default:
        return Theme.of(context).colorScheme.onSurfaceVariant;
    }
  }

  String _formatStatus(String value) {
    switch (value) {
      case 'on_track':
        return 'On Track';
      case 'no_target_date':
        return 'No Target Date';
      case 'low':
        return 'Low';
      case 'medium':
        return 'Medium';
      case 'high':
        return 'High';
      default:
        if (value.isEmpty) {
          return 'Unknown';
        }

        return value[0].toUpperCase() + value.substring(1);
    }
  }

  String _formatDays(int days) {
    if (days == 0) {
      return 'You are right on schedule.';
    }

    if (days > 0) {
      return '$days days ahead of the expected pace.';
    }

    return '${days.abs()} days behind the expected pace.';
  }
}
