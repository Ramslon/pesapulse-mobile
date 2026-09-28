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

  // ---------------------------------------------------------------------------
  // SAFE PARSING
  // ---------------------------------------------------------------------------

  double _double(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  int _int(dynamic value) {
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  String _money(dynamic value) {
    return '$currencySymbol ${_double(value).toStringAsFixed(2)}';
  }

  String _moneyCompact(dynamic value) {
    final amount = _double(value);

    if (amount.abs() >= 1000000) {
      return '$currencySymbol ${(amount / 1000000).toStringAsFixed(1)}M';
    }

    if (amount.abs() >= 1000) {
      return '$currencySymbol ${(amount / 1000).toStringAsFixed(1)}K';
    }

    return '$currencySymbol ${amount.toStringAsFixed(0)}';
  }

  String _percentage(dynamic value) {
    return '${_double(value).toStringAsFixed(1)}%';
  }

  // ---------------------------------------------------------------------------
  // BUILD
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final summary =
        (tracking['summary'] as Map?)?.cast<String, dynamic>() ??
        <String, dynamic>{};

    final dataQuality =
        (tracking['data_quality'] as Map?)?.cast<String, dynamic>() ??
        <String, dynamic>{};

    final goals = tracking['goals'] is List
        ? List<Map<String, dynamic>>.from(
            (tracking['goals'] as List).map(
              (goal) => goal is Map
                  ? goal.cast<String, dynamic>()
                  : <String, dynamic>{},
            ),
          )
        : <Map<String, dynamic>>[];

    final sectionSpacing = ResponsiveHelper.sectionSpacing(context);
    final horizontalPadding = ResponsiveHelper.horizontalPadding(context);

    return AppScaffold(
      appBar: const AdaptiveAppBar(title: 'Advanced Goal Tracking'),
      body: RefreshIndicator(
        onRefresh: () async {},
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.fromLTRB(
            horizontalPadding,
            16,
            horizontalPadding,
            32,
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

                  if (goals.isEmpty)
                    _buildNoGoalsCard(context)
                  else ...[
                    _buildSectionHeading(
                      context,
                      icon: Icons.track_changes_rounded,
                      title: 'Goal intelligence',
                      subtitle: 'Detailed progress, pace and schedule analysis',
                    ),

                    SizedBox(height: 14),

                    ...goals.asMap().entries.map((entry) {
                      return Padding(
                        padding: EdgeInsets.only(bottom: sectionSpacing),
                        child: _buildGoalIntelligenceCard(
                          context,
                          entry.value,
                          entry.key,
                        ),
                      );
                    }),
                  ],

                  SizedBox(height: sectionSpacing),

                  _buildDataQuality(context, dataQuality),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // HERO
  // ---------------------------------------------------------------------------

  Widget _buildHeroHeader(BuildContext context) {
    final theme = Theme.of(context);
    final compact = ResponsiveHelper.useCompactLayout(context);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(compact ? 20 : 26),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_premiumPurple, _premiumPurpleDark],
        ),
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: _premiumPurple.withOpacity(0.18),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 650;

          final content = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.14),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withOpacity(0.12)),
                ),
                child: const Icon(
                  Icons.auto_graph_rounded,
                  color: Colors.white,
                  size: 27,
                ),
              ),

              const SizedBox(height: 18),

              Wrap(
                spacing: 10,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    'Premium Goal Intelligence',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.4,
                    ),
                  ),
                  _premiumChip(),
                ],
              ),

              const SizedBox(height: 9),

              Text(
                'Understand your goal progress, saving pace, '
                'deadline risk and projected schedule in one place.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.white.withOpacity(0.78),
                  height: 1.5,
                ),
              ),
            ],
          );

          if (!isWide) {
            return content;
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: content),

              const SizedBox(width: 24),

              Container(
                width: 92,
                height: 92,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.08),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white.withOpacity(0.12)),
                ),
                child: const Icon(
                  Icons.flag_rounded,
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

  Widget _premiumChip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: _goalAmber,
        borderRadius: BorderRadius.circular(30),
      ),
      child: const Text(
        'PREMIUM',
        style: TextStyle(
          color: _premiumPurpleDark,
          fontSize: 10,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.7,
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // PORTFOLIO SUMMARY
  // ---------------------------------------------------------------------------

  Widget _buildPortfolioSummary(
    BuildContext context,
    Map<String, dynamic> summary,
  ) {
    final theme = Theme.of(context);

    final target = _double(summary['total_target']);
    final saved = _double(summary['total_saved']);
    final remaining = _double(summary['total_remaining']);

    final items = [
      ('Total target', _moneyCompact(target), Icons.flag_rounded, _goalAmber),
      ('Total saved', _moneyCompact(saved), Icons.savings_rounded, _goalAmber),
      (
        'Remaining',
        _moneyCompact(remaining),
        Icons.account_balance_wallet_rounded,
        _premiumPurple,
      ),
    ];

    final columns = ResponsiveHelper.gridColumns(
      context,
      mobilePortrait: 1,
      mobileLandscape: 3,
      tabletPortrait: 3,
      tabletLandscape: 3,
      desktop: 3,
    );

    final spacing = ResponsiveHelper.spacing(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeading(
          context,
          icon: Icons.dashboard_customize_rounded,
          title: 'Goal portfolio',
          subtitle: 'Your overall savings position',
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
            mainAxisExtent: _portfolioCardHeight(context),
          ),
          itemBuilder: (context, index) {
            final item = items[index];

            return _buildPortfolioMetric(
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

  double _portfolioCardHeight(BuildContext context) {
    if (ResponsiveHelper.isMobilePortrait(context)) {
      return 92;
    }

    if (ResponsiveHelper.isMobileLandscape(context)) {
      return 94;
    }

    if (ResponsiveHelper.isTabletPortrait(context)) {
      return 100;
    }

    return 104;
  }

  Widget _buildPortfolioMetric(
    BuildContext context, {
    required ThemeData theme,
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return _card(
      context: context,
      padding: const EdgeInsets.all(15),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color.withOpacity(0.10),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(icon, color: color, size: 21),
          ),

          const SizedBox(width: 12),

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

                const SizedBox(height: 4),

                FittedBox(
                  alignment: Alignment.centerLeft,
                  fit: BoxFit.scaleDown,
                  child: Text(
                    value,
                    maxLines: 1,
                    style: theme.textTheme.titleMedium?.copyWith(
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

  // ---------------------------------------------------------------------------
  // GOAL INTELLIGENCE CARD
  // ---------------------------------------------------------------------------

  Widget _buildGoalIntelligenceCard(
    BuildContext context,
    Map<String, dynamic> goal,
    int index,
  ) {
    final title = goal['title']?.toString() ?? 'Untitled Goal';
    final status = goal['status']?.toString() ?? '';
    final progress = _double(goal['progress_percentage']);

    final saved = _double(goal['saved']);
    final remaining = _double(goal['remaining']);

    return _card(
      context: context,
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildGoalHeader(context, goal, title, status),

          Padding(
            padding: EdgeInsets.all(ResponsiveHelper.cardPadding(context)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildGoalOverview(context, goal, progress, saved, remaining),

                SizedBox(height: ResponsiveHelper.sectionSpacing(context)),

                _buildAnalysisGrid(context, goal),

                SizedBox(height: ResponsiveHelper.sectionSpacing(context)),

                _buildRecommendationPanel(context, goal),

                SizedBox(height: ResponsiveHelper.sectionSpacing(context)),

                _buildMilestoneTimeline(context, goal),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGoalHeader(
    BuildContext context,
    Map<String, dynamic> goal,
    String title,
    String status,
  ) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(ResponsiveHelper.cardPadding(context)),
      decoration: BoxDecoration(
        color: _premiumPurple.withOpacity(0.045),
        border: Border(
          bottom: BorderSide(color: theme.dividerColor.withOpacity(0.7)),
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 480;

          final titleSection = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.2,
                ),
              ),

              const SizedBox(height: 6),

              Text(
                'Goal #${goal['id'] ?? goal['goal_id'] ?? '—'}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          );

          final statusWidget = _statusChip(context, status);

          if (isNarrow) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                titleSection,
                const SizedBox(height: 12),
                statusWidget,
              ],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(child: titleSection),
              const SizedBox(width: 16),
              statusWidget,
            ],
          );
        },
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // GOAL OVERVIEW
  // ---------------------------------------------------------------------------

  Widget _buildGoalOverview(
    BuildContext context,
    Map<String, dynamic> goal,
    double progress,
    double saved,
    double remaining,
  ) {
    final compact = ResponsiveHelper.isMobilePortrait(context);

    final progressSection = _buildProgressRing(context, progress);

    final metrics = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Progress overview',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
        ),

        const SizedBox(height: 14),

        Row(
          children: [
            Expanded(
              child: _smallMetric(
                context,
                label: 'Saved',
                value: _moneyCompact(saved),
                icon: Icons.savings_rounded,
                color: _goalAmber,
              ),
            ),

            const SizedBox(width: 10),

            Expanded(
              child: _smallMetric(
                context,
                label: 'Remaining',
                value: _moneyCompact(remaining),
                icon: Icons.account_balance_wallet_rounded,
                color: _premiumPurple,
              ),
            ),
          ],
        ),

        const SizedBox(height: 14),

        _progressStatusBanner(context, progress),
      ],
    );

    if (compact) {
      return Column(
        children: [progressSection, const SizedBox(height: 20), metrics],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(width: 150, child: Center(child: progressSection)),

        const SizedBox(width: 24),

        Expanded(child: metrics),
      ],
    );
  }

  Widget _buildProgressRing(BuildContext context, double progress) {
    final clamped = progress.clamp(0, 100).toDouble();

    return SizedBox(
      width: 128,
      height: 128,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox.expand(
            child: CircularProgressIndicator(
              value: clamped / 100,
              strokeWidth: 10,
              backgroundColor: _goalAmber.withOpacity(0.10),
              valueColor: const AlwaysStoppedAnimation<Color>(_goalAmber),
            ),
          ),

          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  '${clamped.toStringAsFixed(0)}%',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: _goalAmberDark,
                  ),
                ),
              ),

              const SizedBox(height: 2),

              Text(
                'complete',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _progressStatusBanner(BuildContext context, double progress) {
    final theme = Theme.of(context);

    final message = progress >= 100
        ? 'Goal target reached.'
        : progress >= 75
        ? 'You are in the final stretch.'
        : progress >= 50
        ? 'You are more than halfway there.'
        : 'Keep building your savings momentum.';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
      decoration: BoxDecoration(
        color: _goalAmber.withOpacity(0.075),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: _goalAmber.withOpacity(0.16)),
      ),
      child: Row(
        children: [
          const Icon(Icons.insights_rounded, size: 18, color: _goalAmberDark),

          const SizedBox(width: 9),

          Expanded(
            child: Text(
              message,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // ANALYSIS GRID
  // ---------------------------------------------------------------------------

  Widget _buildAnalysisGrid(BuildContext context, Map<String, dynamic> goal) {
    final columns = ResponsiveHelper.gridColumns(
      context,
      mobilePortrait: 1,
      mobileLandscape: 2,
      tabletPortrait: 2,
      tabletLandscape: 2,
      desktop: 2,
    );

    final spacing = ResponsiveHelper.spacing(context);

    final cards = [
      _deadlinePanel(context, goal),
      _paceComparison(context, goal),
      _scheduleComparison(context, goal),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: cards.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        crossAxisSpacing: spacing,
        mainAxisSpacing: spacing,
        mainAxisExtent: _analysisCardHeight(context),
      ),
      itemBuilder: (context, index) {
        return cards[index];
      },
    );
  }

  double _analysisCardHeight(BuildContext context) {
    if (ResponsiveHelper.isMobilePortrait(context)) {
      return 196;
    }

    if (ResponsiveHelper.isMobileLandscape(context)) {
      return 190;
    }

    if (ResponsiveHelper.isTabletPortrait(context)) {
      return 205;
    }

    return 210;
  }

  // ---------------------------------------------------------------------------
  // DEADLINE
  // ---------------------------------------------------------------------------

  Widget _deadlinePanel(BuildContext context, Map<String, dynamic> goal) {
    final risk = goal['deadline_risk']?.toString() ?? 'none';
    final riskColor = _riskColor(risk);

    final daysLeft = _int(goal['days_remaining'] ?? goal['days_left']);

    final targetDate = goal['target_date']?.toString() ?? 'No target date';

    final projectedDate =
        goal['projected_completion_date']?.toString() ?? 'Not available';

    return _analysisCard(
      context,
      icon: Icons.event_available_rounded,
      title: 'Deadline',
      accent: riskColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _analysisValue(context, _formatDays(daysLeft)),

          const SizedBox(height: 14),

          _detailRow(context, 'Target date', targetDate),

          const SizedBox(height: 8),

          _detailRow(context, 'Projected', projectedDate),

          const Spacer(),

          Align(
            alignment: Alignment.centerLeft,
            child: _riskChip(context, risk),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // PACE
  // ---------------------------------------------------------------------------

  Widget _paceComparison(BuildContext context, Map<String, dynamic> goal) {
    final currentDaily = _double(
      goal['current_daily_saving'] ?? goal['current_daily_rate'],
    );

    final requiredDaily = _double(
      goal['required_daily_saving'] ?? goal['required_daily_rate'],
    );

    final requiredMonthly = _double(
      goal['required_monthly_saving'] ?? goal['required_monthly_rate'],
    );

    final ratio = requiredDaily <= 0
        ? 0.0
        : (currentDaily / requiredDaily).clamp(0.0, 1.0);

    return _analysisCard(
      context,
      icon: Icons.speed_rounded,
      title: 'Saving pace',
      accent: _goalAmber,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _paceRow(
            context,
            label: 'Current daily',
            value: _money(currentDaily),
            progress: ratio,
            color: _goalAmber,
          ),

          const SizedBox(height: 12),

          _paceRow(
            context,
            label: 'Required daily',
            value: _money(requiredDaily),
            progress: 1,
            color: _premiumPurple,
          ),

          const Spacer(),

          _detailRow(
            context,
            'Required monthly',
            _moneyCompact(requiredMonthly),
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
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),

            const SizedBox(width: 8),

            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerRight,
                child: Text(
                  value,
                  maxLines: 1,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 7),

        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: LinearProgressIndicator(
            value: progress.clamp(0, 1),
            minHeight: 7,
            backgroundColor: color.withOpacity(0.10),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // SCHEDULE
  // ---------------------------------------------------------------------------

  Widget _scheduleComparison(BuildContext context, Map<String, dynamic> goal) {
    final expected = _double(
      goal['expected_progress_percentage'] ?? goal['expected_progress'],
    );

    final actual = _double(goal['progress_percentage']);

    final variance = _double(
      goal['progress_variance'] ??
          goal['variance_percentage'] ??
          (actual - expected),
    );

    final daysAhead = _int(
      goal['days_ahead_behind'] ?? goal['schedule_variance_days'],
    );

    final variancePositive = variance >= 0;

    return _analysisCard(
      context,
      icon: Icons.compare_arrows_rounded,
      title: 'Schedule',
      accent: _premiumPurple,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _scheduleMetric(
                  context,
                  'Expected',
                  _percentage(expected),
                ),
              ),

              const SizedBox(width: 10),

              Expanded(
                child: _scheduleMetric(context, 'Actual', _percentage(actual)),
              ),
            ],
          ),

          const SizedBox(height: 14),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(11),
            decoration: BoxDecoration(
              color: (variancePositive ? Colors.green : Colors.orange)
                  .withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  variancePositive
                      ? Icons.trending_up_rounded
                      : Icons.trending_down_rounded,
                  size: 18,
                  color: variancePositive ? Colors.green : Colors.orange,
                ),

                const SizedBox(width: 8),

                Expanded(
                  child: Text(
                    'Variance ${variance >= 0 ? '+' : ''}${variance.toStringAsFixed(1)}%',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const Spacer(),

          _detailRow(context, 'Schedule', _formatDays(daysAhead)),
        ],
      ),
    );
  }

  Widget _scheduleMetric(BuildContext context, String label, String value) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.45),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontSize: 11,
            ),
          ),

          const SizedBox(height: 4),

          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // ANALYSIS CARD
  // ---------------------------------------------------------------------------

  Widget _analysisCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required Color accent,
    required Widget child,
  }) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: theme.dividerColor.withOpacity(0.7)),
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
                  color: accent.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 18, color: accent),
              ),

              const SizedBox(width: 10),

              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          Expanded(child: child),
        ],
      ),
    );
  }

  Widget _analysisValue(BuildContext context, String value) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerLeft,
      child: Text(
        value,
        maxLines: 1,
        style: Theme.of(
          context,
        ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
      ),
    );
  }

  Widget _detailRow(BuildContext context, String label, String value) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),

        const SizedBox(width: 10),

        Flexible(
          child: Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.right,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // RECOMMENDATION
  // ---------------------------------------------------------------------------

  Widget _buildRecommendationPanel(
    BuildContext context,
    Map<String, dynamic> goal,
  ) {
    final theme = Theme.of(context);

    final recommendation =
        goal['recommendation']?.toString() ??
        goal['recommendation_text']?.toString() ??
        'Continue monitoring your progress and maintain your current saving routine.';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_goalAmber.withOpacity(0.11), _goalAmber.withOpacity(0.045)],
        ),
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: _goalAmber.withOpacity(0.16)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _goalAmber.withOpacity(0.14),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.auto_awesome_rounded,
              color: _goalAmberDark,
              size: 21,
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Smart recommendation',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),

                const SizedBox(height: 5),

                Text(
                  recommendation,
                  style: theme.textTheme.bodySmall?.copyWith(
                    height: 1.45,
                    color: theme.colorScheme.onSurfaceVariant,
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
  // MILESTONES
  // ---------------------------------------------------------------------------

  Widget _buildMilestoneTimeline(
    BuildContext context,
    Map<String, dynamic> goal,
  ) {
    final theme = Theme.of(context);

    final milestones = goal['milestones'] is List
        ? List<dynamic>.from(goal['milestones'])
        : <dynamic>[];

    if (milestones.isEmpty) {
      return _emptySection(
        context,
        icon: Icons.flag_outlined,
        title: 'Milestones',
        message: 'No milestone data available for this goal.',
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSubsectionHeading(
          context,
          icon: Icons.timeline_rounded,
          title: 'Milestones',
          subtitle: 'Progress checkpoints for this goal',
        ),

        const SizedBox(height: 12),

        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.30),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: List.generate(milestones.length, (index) {
              final milestone = milestones[index];

              final data = milestone is Map
                  ? milestone.cast<String, dynamic>()
                  : <String, dynamic>{};

              final reached =
                  data['reached'] == true ||
                  data['completed'] == true ||
                  data['is_reached'] == true;

              final title =
                  data['title']?.toString() ??
                  data['name']?.toString() ??
                  'Milestone ${index + 1}';

              final target =
                  data['target'] ?? data['target_amount'] ?? data['amount'];

              final percentage =
                  data['percentage'] ?? data['progress_percentage'];

              return _milestoneItem(
                context,
                title: title,
                target: target,
                percentage: percentage,
                reached: reached,
                isLast: index == milestones.length - 1,
              );
            }),
          ),
        ),
      ],
    );
  }

  Widget _milestoneItem(
    BuildContext context, {
    required String title,
    required dynamic target,
    required dynamic percentage,
    required bool reached,
    required bool isLast,
  }) {
    final theme = Theme.of(context);

    final color = reached
        ? _goalAmberDark
        : theme.colorScheme.onSurfaceVariant.withOpacity(0.55);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 30,
            child: Column(
              children: [
                Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    color: reached ? _goalAmber : theme.colorScheme.surface,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: reached ? _goalAmber : theme.dividerColor,
                    ),
                  ),
                  child: Icon(
                    reached ? Icons.check_rounded : Icons.circle_outlined,
                    size: 15,
                    color: reached
                        ? _premiumPurpleDark
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                ),

                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      color: theme.dividerColor,
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(width: 10),

          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: reached ? theme.colorScheme.onSurface : color,
                    ),
                  ),

                  const SizedBox(height: 4),

                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      if (target != null)
                        Text(
                          _moneyCompact(target),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),

                      if (percentage != null)
                        Text(
                          _percentage(percentage),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: reached
                                ? _goalAmberDark
                                : theme.colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // DATA QUALITY
  // ---------------------------------------------------------------------------

  Widget _buildDataQuality(
    BuildContext context,
    Map<String, dynamic> dataQuality,
  ) {
    final theme = Theme.of(context);

    final score = dataQuality['score'];
    final completeness = dataQuality['completeness'];
    final message =
        dataQuality['message']?.toString() ??
        dataQuality['description']?.toString();

    return _card(
      context: context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSubsectionHeading(
            context,
            icon: Icons.verified_rounded,
            title: 'Data quality',
            subtitle: 'How complete and reliable the goal analysis is',
          ),

          const SizedBox(height: 16),

          LayoutBuilder(
            builder: (context, constraints) {
              final narrow = constraints.maxWidth < 480;

              final scoreWidget = _qualityScore(context, score);

              final details = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (completeness != null)
                    _detailRow(
                      context,
                      'Completeness',
                      _percentage(completeness),
                    ),

                  if (completeness != null) const SizedBox(height: 8),

                  if (message != null)
                    Text(
                      message,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        height: 1.45,
                      ),
                    ),
                ],
              );

              if (narrow) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [scoreWidget, const SizedBox(height: 14), details],
                );
              }

              return Row(
                children: [
                  scoreWidget,
                  const SizedBox(width: 20),
                  Expanded(child: details),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _qualityScore(BuildContext context, dynamic score) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: _premiumPurple.withOpacity(0.07),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.shield_rounded, color: _premiumPurple, size: 20),

          const SizedBox(width: 8),

          Text(
            score == null ? 'Available' : 'Score ${_percentage(score)}',
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // NO GOALS
  // ---------------------------------------------------------------------------

  Widget _buildNoGoalsCard(BuildContext context) {
    final theme = Theme.of(context);

    return _card(
      context: context,
      child: Column(
        children: [
          Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              color: _goalAmber.withOpacity(0.10),
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
            'Create a savings goal to unlock detailed '
            'progress tracking, saving pace analysis, '
            'deadline insights and milestones.',
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

  // ---------------------------------------------------------------------------
  // SHARED UI
  // ---------------------------------------------------------------------------

  Widget _card({
    required BuildContext context,
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
        border: Border.all(color: theme.dividerColor.withOpacity(0.75)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.025),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildSectionHeading(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: _premiumPurple.withOpacity(0.09),
            borderRadius: BorderRadius.circular(11),
          ),
          child: Icon(icon, size: 20, color: _premiumPurple),
        ),

        const SizedBox(width: 11),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
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

  Widget _buildSubsectionHeading(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 19, color: _goalAmberDark),

        const SizedBox(width: 8),

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
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _smallMetric(
    BuildContext context, {
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.055),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.10)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),

          const SizedBox(width: 8),

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
                    fontSize: 10.5,
                  ),
                ),

                const SizedBox(height: 3),

                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    value,
                    maxLines: 1,
                    style: theme.textTheme.bodySmall?.copyWith(
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

  Widget _emptySection(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String message,
  }) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.30),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: theme.colorScheme.onSurfaceVariant, size: 20),

          const SizedBox(width: 10),

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

                const SizedBox(height: 3),

                Text(
                  message,
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

  // ---------------------------------------------------------------------------
  // CHIPS
  // ---------------------------------------------------------------------------

  Widget _statusChip(BuildContext context, String status) {
    final color = _statusColor(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: color.withOpacity(0.16)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),

          const SizedBox(width: 7),

          Text(
            _formatStatus(status),
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _riskChip(BuildContext context, String risk) {
    final color = _riskColor(risk);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Text(
        '${_formatStatus(risk)} risk',
        style: TextStyle(
          color: color,
          fontSize: 10.5,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // COLORS / FORMATTING
  // ---------------------------------------------------------------------------

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
      case 'ahead':
        return Colors.green;

      case 'on_track':
      case 'on track':
        return _goalAmberDark;

      case 'behind':
        return Colors.orange;

      case 'overdue':
        return Colors.red;

      default:
        return Colors.blueGrey;
    }
  }

  Color _riskColor(String risk) {
    switch (risk.toLowerCase()) {
      case 'none':
      case 'low':
        return Colors.green;

      case 'medium':
        return Colors.orange;

      case 'high':
        return Colors.red;

      default:
        return Colors.blueGrey;
    }
  }

  String _formatStatus(String value) {
    if (value.isEmpty) return 'Unknown';

    return value
        .replaceAll('_', ' ')
        .split(' ')
        .map(
          (word) => word.isEmpty
              ? word
              : '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}',
        )
        .join(' ');
  }

  String _formatDays(int days) {
    if (days == 0) {
      return 'Right on schedule';
    }

    if (days > 0) {
      return '$days days ahead';
    }

    return '${days.abs()} days behind';
  }
}
