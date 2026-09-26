import 'package:flutter/material.dart';

import '../../core/utils/currency_formatter.dart';
import 'budget_stat_item.dart';
import 'budget_progress_gauge.dart';
import '../../utils/responsive_helper.dart';

class BudgetOverviewCard extends StatelessWidget {
  final double budget;
  final double spent;
  final double remaining;
  final double percentageUsed;
  final Color statusColor;

  const BudgetOverviewCard({
    super.key,
    required this.budget,
    required this.spent,
    required this.remaining,
    required this.percentageUsed,
    required this.statusColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final compact = ResponsiveHelper.useCompactLayout(context);
    final tablet = ResponsiveHelper.isTablet(context);
    final desktop = ResponsiveHelper.isDesktop(context);
    final landscape = ResponsiveHelper.isLandscape(context);

    final cardPadding = ResponsiveHelper.cardPadding(context);

    final radius = desktop
        ? 24.0
        : compact
        ? 17.0
        : 21.0;

    final wideLayout = (landscape && !compact) || desktop;

    final gaugeSize = desktop
        ? 138.0
        : tablet
        ? 128.0
        : compact
        ? 104.0
        : landscape
        ? 112.0
        : 132.0;

    final amountSize = desktop
        ? 34.0
        : tablet
        ? 31.0
        : compact
        ? 24.0
        : landscape
        ? 27.0
        : 30.0;

    final titleSize = desktop
        ? 18.0
        : compact
        ? 14.0
        : 16.0;

    final subtitleSize = desktop
        ? 12.5
        : compact
        ? 10.0
        : 11.5;

    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOutCubic,
      tween: Tween(begin: 0.97, end: 1.0),
      builder: (_, scale, child) {
        return Transform.scale(scale: scale, child: child);
      },
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(color: colorScheme.outline.withOpacity(0.08)),
          boxShadow: [
            BoxShadow(
              color: statusColor.withOpacity(
                theme.brightness == Brightness.dark ? 0.08 : 0.055,
              ),
              blurRadius: desktop ? 22 : 16,
              offset: const Offset(0, 7),
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.all(cardPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(
                context,
                titleSize: titleSize,
                subtitleSize: subtitleSize,
                compact: compact,
                desktop: desktop,
              ),

              SizedBox(
                height: desktop
                    ? 22
                    : compact
                    ? 16
                    : landscape
                    ? 18
                    : 20,
              ),

              wideLayout
                  ? _buildWideMainContent(
                      context,
                      amountSize: amountSize,
                      gaugeSize: gaugeSize,
                      compact: compact,
                      desktop: desktop,
                    )
                  : _buildStackedMainContent(
                      context,
                      amountSize: amountSize,
                      gaugeSize: gaugeSize,
                    ),

              SizedBox(
                height: desktop
                    ? 20
                    : compact
                    ? 14
                    : 18,
              ),

              _buildStatistics(context, compact: compact, desktop: desktop),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context, {
    required double titleSize,
    required double subtitleSize,
    required bool compact,
    required bool desktop,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final iconBox = desktop
        ? 44.0
        : compact
        ? 34.0
        : 40.0;

    final iconSize = desktop
        ? 22.0
        : compact
        ? 17.0
        : 20.0;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: iconBox,
          height: iconBox,
          decoration: BoxDecoration(
            color: statusColor.withOpacity(0.09),
            borderRadius: BorderRadius.circular(compact ? 10 : 13),
            border: Border.all(color: statusColor.withOpacity(0.10)),
          ),
          child: Icon(
            Icons.account_balance_wallet_rounded,
            color: statusColor,
            size: iconSize,
          ),
        ),

        SizedBox(width: compact ? 9 : 11),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Monthly Budget',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: colorScheme.onSurface,
                  fontSize: titleSize,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.2,
                ),
              ),

              const SizedBox(height: 3),

              Text(
                'Your spending position for this budget',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: colorScheme.onSurfaceVariant.withOpacity(0.70),
                  fontSize: subtitleSize,
                  height: 1.25,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(width: 10),

        Container(
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 7 : 9,
            vertical: compact ? 4 : 5,
          ),
          decoration: BoxDecoration(
            color: statusColor.withOpacity(0.08),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            'BUDGET',
            style: TextStyle(
              color: statusColor,
              fontSize: compact ? 7.5 : 8.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.6,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWideMainContent(
    BuildContext context, {
    required double amountSize,
    required double gaugeSize,
    required bool compact,
    required bool desktop,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: _buildBudgetAmount(
            context,
            amountSize: amountSize,
            colorScheme: colorScheme,
          ),
        ),

        SizedBox(
          width: desktop
              ? 18
              : compact
              ? 10
              : 14,
        ),

        SizedBox(
          width: gaugeSize,
          height: gaugeSize,
          child: BudgetProgressGauge(
            budget: budget,
            spent: spent,
            percentageUsed: percentageUsed,
            statusColor: statusColor,
          ),
        ),
      ],
    );
  }

  Widget _buildStackedMainContent(
    BuildContext context, {
    required double amountSize,
    required double gaugeSize,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _buildBudgetAmount(
          context,
          amountSize: amountSize,
          colorScheme: Theme.of(context).colorScheme,
          centered: true,
        ),

        SizedBox(height: ResponsiveHelper.useCompactLayout(context) ? 12 : 16),

        SizedBox(
          width: gaugeSize,
          height: gaugeSize,
          child: BudgetProgressGauge(
            budget: budget,
            spent: spent,
            percentageUsed: percentageUsed,
            statusColor: statusColor,
          ),
        ),
      ],
    );
  }

  Widget _buildBudgetAmount(
    BuildContext context, {
    required double amountSize,
    required ColorScheme colorScheme,
    bool centered = false,
  }) {
    return Column(
      crossAxisAlignment: centered
          ? CrossAxisAlignment.center
          : CrossAxisAlignment.start,
      children: [
        Text(
          'BUDGET LIMIT',
          textAlign: centered ? TextAlign.center : TextAlign.start,
          style: TextStyle(
            color: colorScheme.onSurfaceVariant.withOpacity(0.62),
            fontSize: ResponsiveHelper.useCompactLayout(context) ? 9.0 : 10.0,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.8,
          ),
        ),

        const SizedBox(height: 6),

        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: budget),
          duration: const Duration(milliseconds: 1000),
          curve: Curves.easeOutCubic,
          builder: (context, value, child) {
            return SizedBox(
              width: double.infinity,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: centered ? Alignment.center : Alignment.centerLeft,
                child: Text(
                  CurrencyFormatter.format(value),
                  maxLines: 1,
                  style: TextStyle(
                    color: colorScheme.onSurface,
                    fontSize: amountSize,
                    fontWeight: FontWeight.w900,
                    height: 1.0,
                    letterSpacing: -0.8,
                  ),
                ),
              ),
            );
          },
        ),

        const SizedBox(height: 7),

        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: statusColor,
                shape: BoxShape.circle,
              ),
            ),

            const SizedBox(width: 7),

            Text(
              'Monthly spending limit',
              style: TextStyle(
                color: colorScheme.onSurfaceVariant.withOpacity(0.65),
                fontSize: ResponsiveHelper.useCompactLayout(context)
                    ? 9.5
                    : 10.5,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatistics(
    BuildContext context, {
    required bool compact,
    required bool desktop,
  }) {
    final spacing = ResponsiveHelper.spacing(context);

    return Row(
      children: [
        Expanded(
          child: _buildStatSurface(
            context,
            icon: Icons.arrow_upward_rounded,
            iconColor: const Color(0xFFE53935),
            backgroundColor: const Color(0xFFE53935).withOpacity(
              Theme.of(context).brightness == Brightness.dark ? 0.10 : 0.065,
            ),
            title: 'Spent',
            amount: spent,
            compact: compact,
            desktop: desktop,
          ),
        ),

        SizedBox(width: spacing),

        Expanded(
          child: _buildStatSurface(
            context,
            icon: Icons.savings_rounded,
            iconColor: const Color(0xFF16A34A),
            backgroundColor: const Color(0xFF16A34A).withOpacity(
              Theme.of(context).brightness == Brightness.dark ? 0.10 : 0.065,
            ),
            title: 'Remaining',
            amount: remaining,
            compact: compact,
            desktop: desktop,
          ),
        ),
      ],
    );
  }

  Widget _buildStatSurface(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required Color backgroundColor,
    required String title,
    required double amount,
    required bool compact,
    required bool desktop,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final iconBoxSize = desktop
        ? 36.0
        : compact
        ? 30.0
        : 34.0;

    final iconSize = desktop
        ? 18.0
        : compact
        ? 15.0
        : 17.0;

    final amountSize = desktop
        ? 14.0
        : compact
        ? 11.5
        : 13.0;

    final titleSize = desktop
        ? 10.5
        : compact
        ? 8.5
        : 9.5;

    return Container(
      padding: EdgeInsets.all(
        desktop
            ? 11
            : compact
            ? 9
            : 10,
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(compact ? 13 : 15),
        border: Border.all(color: iconColor.withOpacity(0.08)),
      ),
      child: Row(
        children: [
          Container(
            width: iconBoxSize,
            height: iconBoxSize,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.10),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: iconSize),
          ),

          SizedBox(width: compact ? 8 : 9),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: colorScheme.onSurfaceVariant.withOpacity(0.66),
                    fontSize: titleSize,
                    fontWeight: FontWeight.w700,
                  ),
                ),

                const SizedBox(height: 2),

                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    CurrencyFormatter.format(amount),
                    maxLines: 1,
                    style: TextStyle(
                      color: colorScheme.onSurface,
                      fontSize: amountSize,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.2,
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
}
