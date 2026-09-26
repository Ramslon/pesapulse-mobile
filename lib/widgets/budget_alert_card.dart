import 'package:flutter/material.dart';

import '../../utils/responsive_helper.dart';

class BudgetAlertCard extends StatelessWidget {
  final String budgetStatus;
  final double budget;
  final double percentageUsed;
  final String recommendation;

  const BudgetAlertCard({
    super.key,
    required this.budgetStatus,
    required this.budget,
    required this.percentageUsed,
    required this.recommendation,
  });

  _AlertConfig _config() {
    switch (budgetStatus.toLowerCase()) {
      case 'healthy':
        return const _AlertConfig(
          icon: Icons.check_circle_rounded,
          color: Color(0xFF16A34A),
          title: 'Budget Healthy',
          description:
              'Your current spending is within a comfortable budget range.',
        );

      case 'warning':
        return const _AlertConfig(
          icon: Icons.warning_amber_rounded,
          color: Color(0xFFF59E0B),
          title: 'Budget Warning',
          description: 'You are approaching your monthly spending limit.',
        );

      case 'overspent':
        return const _AlertConfig(
          icon: Icons.error_outline_rounded,
          color: Color(0xFFF97316),
          title: 'Budget Exceeded',
          description: 'Your spending has moved beyond the monthly budget.',
        );

      case 'critical':
        return const _AlertConfig(
          icon: Icons.dangerous_rounded,
          color: Color(0xFFDC2626),
          title: 'Critical Budget Alert',
          description:
              'Your budget is under significant pressure and needs attention.',
        );

      default:
        return const _AlertConfig(
          icon: Icons.account_balance_wallet_outlined,
          color: Color(0xFF64748B),
          title: 'Budget Status',
          description: 'Review your current spending and budget position.',
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final compact = ResponsiveHelper.useCompactLayout(context);

    final tablet = ResponsiveHelper.isTablet(context);

    final desktop = ResponsiveHelper.isDesktop(context);

    final landscape = ResponsiveHelper.isLandscape(context);

    final config = _config();

    final displayedPercentage = percentageUsed.isFinite
        ? percentageUsed.clamp(0.0, double.infinity)
        : 0.0;

    final progressValue = displayedPercentage.clamp(0.0, 100.0) / 100.0;

    final radius = desktop
        ? 18.0
        : compact
        ? 14.0
        : 16.0;

    final padding = desktop
        ? 16.0
        : tablet
        ? 14.0
        : compact
        ? 10.0
        : landscape
        ? 11.0
        : 14.0;

    final descriptionSize = desktop
        ? 12.5
        : compact
        ? 9.5
        : 10.5;

    final recommendationSize = desktop
        ? 12.5
        : compact
        ? 9.5
        : 10.5;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: config.color.withOpacity(
          theme.brightness == Brightness.dark ? 0.09 : 0.055,
        ),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: config.color.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(
            context,
            config: config,
            percentage: displayedPercentage,
            compact: compact,
            desktop: desktop,
          ),

          SizedBox(height: compact ? 8 : 10),

          Text(
            budget > 0
                ? config.description
                : 'No monthly budget has been set yet.',
            maxLines: compact ? 3 : 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: colorScheme.onSurfaceVariant.withOpacity(0.72),
              fontSize: descriptionSize,
              height: 1.4,
              fontWeight: FontWeight.w500,
            ),
          ),

          if (budget > 0) ...[
            SizedBox(height: compact ? 9 : 11),

            _buildUsageBar(
              context,
              color: config.color,
              progress: progressValue,
              percentage: displayedPercentage,
              compact: compact,
            ),
          ],

          if (recommendation.trim().isNotEmpty) ...[
            SizedBox(height: compact ? 10 : 12),

            _buildRecommendation(
              context,
              config: config,
              recommendation: recommendation.trim(),
              compact: compact,
              desktop: desktop,
              fontSize: recommendationSize,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context, {
    required _AlertConfig config,
    required double percentage,
    required bool compact,
    required bool desktop,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: compact
              ? 31
              : desktop
              ? 40
              : 36,
          height: compact
              ? 31
              : desktop
              ? 40
              : 36,
          decoration: BoxDecoration(
            color: config.color.withOpacity(0.10),
            borderRadius: BorderRadius.circular(compact ? 9 : 11),
          ),
          child: Icon(
            config.icon,
            color: config.color,
            size: compact
                ? 16
                : desktop
                ? 20
                : 18,
          ),
        ),

        SizedBox(width: compact ? 9 : 11),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                config.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: colorScheme.onSurface,
                  fontSize: desktop
                      ? 14
                      : compact
                      ? 10.5
                      : 12.5,
                  fontWeight: FontWeight.w800,
                ),
              ),

              const SizedBox(height: 2),

              Text(
                'CURRENT BUDGET STATE',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: colorScheme.onSurfaceVariant.withOpacity(0.55),
                  fontSize: compact ? 7.0 : 8.0,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.7,
                ),
              ),
            ],
          ),
        ),

        if (budget > 0) ...[
          const SizedBox(width: 8),

          Container(
            padding: EdgeInsets.symmetric(
              horizontal: compact ? 7 : 8,
              vertical: compact ? 4 : 5,
            ),
            decoration: BoxDecoration(
              color: config.color.withOpacity(0.09),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${percentage.toStringAsFixed(0)}%',
              style: TextStyle(
                color: config.color,
                fontSize: compact ? 8.5 : 9.5,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildUsageBar(
    BuildContext context, {
    required Color color,
    required double progress,
    required double percentage,
    required bool compact,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: TweenAnimationBuilder<double>(
              duration: const Duration(milliseconds: 800),
              curve: Curves.easeOutCubic,
              tween: Tween(begin: 0, end: progress),
              builder: (_, value, __) {
                return LinearProgressIndicator(
                  value: value,
                  minHeight: compact ? 5 : 6,
                  backgroundColor: colorScheme.outline.withOpacity(0.08),
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                );
              },
            ),
          ),
        ),

        SizedBox(width: compact ? 7 : 9),

        Text(
          percentage >= 100 ? 'Limit reached' : 'of budget',
          style: TextStyle(
            color: colorScheme.onSurfaceVariant.withOpacity(0.55),
            fontSize: compact ? 8 : 9,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildRecommendation(
    BuildContext context, {
    required _AlertConfig config,
    required String recommendation,
    required bool compact,
    required bool desktop,
    required double fontSize,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 9 : 11,
        vertical: compact ? 8 : 9,
      ),
      decoration: BoxDecoration(
        color: theme.cardColor.withOpacity(
          theme.brightness == Brightness.dark ? 0.30 : 0.55,
        ),
        borderRadius: BorderRadius.circular(compact ? 11 : 13),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.arrow_forward_rounded,
            color: config.color,
            size: compact ? 14 : 16,
          ),

          SizedBox(width: compact ? 6 : 8),

          Expanded(
            child: Text(
              recommendation,
              style: TextStyle(
                color: colorScheme.onSurfaceVariant.withOpacity(0.78),
                fontSize: fontSize,
                height: 1.4,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AlertConfig {
  final IconData icon;
  final Color color;
  final String title;
  final String description;

  const _AlertConfig({
    required this.icon,
    required this.color,
    required this.title,
    required this.description,
  });
}
