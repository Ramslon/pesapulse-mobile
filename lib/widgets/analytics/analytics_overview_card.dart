import 'package:flutter/material.dart';
import 'package:pesapulse_mobile/core/utils/currency_formatter.dart';

import '../../utils/responsive_helper.dart';

class AnalyticsOverviewCard extends StatelessWidget {
  final double totalSpending;

  const AnalyticsOverviewCard({super.key, required this.totalSpending});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final compact = ResponsiveHelper.useCompactLayout(context);
    final landscape = ResponsiveHelper.isLandscape(context);
    final tablet = ResponsiveHelper.isTablet(context);
    final desktop = ResponsiveHelper.isDesktop(context);

    final cardPadding = desktop
        ? 26.0
        : tablet
        ? 24.0
        : compact
        ? 14.0
        : landscape
        ? 16.0
        : 22.0;

    final radius = desktop
        ? 24.0
        : compact
        ? 17.0
        : 21.0;

    final iconBoxSize = desktop
        ? 48.0
        : tablet
        ? 46.0
        : compact
        ? 36.0
        : landscape
        ? 40.0
        : 44.0;

    final iconSize = desktop
        ? 24.0
        : tablet
        ? 23.0
        : compact
        ? 19.0
        : landscape
        ? 20.0
        : 22.0;

    final titleSize = desktop
        ? 19.0
        : tablet
        ? 17.5
        : compact
        ? 14.0
        : landscape
        ? 14.5
        : 16.5;

    final subtitleSize = desktop
        ? 12.5
        : tablet
        ? 12.0
        : compact
        ? 10.0
        : landscape
        ? 10.5
        : 11.5;

    final amountSize = desktop
        ? 34.0
        : tablet
        ? 31.0
        : compact
        ? 23.0
        : landscape
        ? 25.0
        : 29.0;

    final labelSize = desktop
        ? 12.5
        : compact
        ? 10.0
        : 11.5;

    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 500),
      tween: Tween(begin: 0.97, end: 1),
      curve: Curves.easeOutCubic,
      builder: (_, scale, child) {
        return Transform.scale(scale: scale, child: child);
      },
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(cardPadding),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(color: colorScheme.outline.withOpacity(0.08)),
          boxShadow: [
            BoxShadow(
              color: colorScheme.primary.withOpacity(
                theme.brightness == Brightness.dark ? 0.07 : 0.05,
              ),
              blurRadius: desktop ? 22 : 16,
              offset: const Offset(0, 7),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(
              context,
              colorScheme: colorScheme,
              compact: compact,
              desktop: desktop,
              iconBoxSize: iconBoxSize,
              iconSize: iconSize,
              titleSize: titleSize,
              subtitleSize: subtitleSize,
            ),

            SizedBox(
              height: desktop
                  ? 24
                  : compact
                  ? 16
                  : landscape
                  ? 18
                  : 21,
            ),

            _buildSpendingMetric(
              context,
              colorScheme: colorScheme,
              compact: compact,
              desktop: desktop,
              amountSize: amountSize,
              labelSize: labelSize,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context, {
    required ColorScheme colorScheme,
    required bool compact,
    required bool desktop,
    required double iconBoxSize,
    required double iconSize,
    required double titleSize,
    required double subtitleSize,
  }) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: iconBoxSize,
          height: iconBoxSize,
          decoration: BoxDecoration(
            color: colorScheme.primary.withOpacity(0.09),
            borderRadius: BorderRadius.circular(compact ? 11 : 14),
            border: Border.all(color: colorScheme.primary.withOpacity(0.10)),
          ),
          child: Icon(
            Icons.insights_rounded,
            color: colorScheme.primary,
            size: iconSize,
          ),
        ),

        SizedBox(width: compact ? 10 : 12),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Analytics Overview',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontSize: titleSize,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.2,
                ),
              ),

              const SizedBox(height: 3),

              Text(
                'Your spending snapshot',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontSize: subtitleSize,
                  height: 1.25,
                  color: colorScheme.onSurfaceVariant.withOpacity(0.72),
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
            color: colorScheme.surfaceContainerHighest.withOpacity(0.60),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            'OVERVIEW',
            style: TextStyle(
              color: colorScheme.onSurfaceVariant.withOpacity(0.75),
              fontSize: compact ? 7.5 : 8.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.6,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSpendingMetric(
    BuildContext context, {
    required ColorScheme colorScheme,
    required bool compact,
    required bool desktop,
    required double amountSize,
    required double labelSize,
  }) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: desktop
            ? 16
            : compact
            ? 11
            : 14,
        vertical: desktop
            ? 16
            : compact
            ? 12
            : 14,
      ),
      decoration: BoxDecoration(
        color: colorScheme.primary.withOpacity(
          theme.brightness == Brightness.dark ? 0.08 : 0.045,
        ),
        borderRadius: BorderRadius.circular(compact ? 14 : 16),
        border: Border.all(color: colorScheme.primary.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'TOTAL SPENDING',
            style: TextStyle(
              color: colorScheme.primary.withOpacity(0.82),
              fontSize: labelSize,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
            ),
          ),

          SizedBox(height: compact ? 5 : 7),

          TweenAnimationBuilder<double>(
            duration: const Duration(milliseconds: 900),
            curve: Curves.easeOutCubic,
            tween: Tween(begin: 0, end: totalSpending),
            builder: (_, value, __) {
              return SizedBox(
                width: double.infinity,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    CurrencyFormatter.format(value),
                    maxLines: 1,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontSize: amountSize,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -1.0,
                      height: 1.0,
                    ),
                  ),
                ),
              );
            },
          ),

          SizedBox(height: compact ? 5 : 7),

          Row(
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: colorScheme.primary,
                  shape: BoxShape.circle,
                ),
              ),

              const SizedBox(width: 7),

              Expanded(
                child: Text(
                  'Total expenses recorded for the current analytics period',
                  maxLines: compact ? 2 : 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontSize: compact ? 9.5 : 10.5,
                    color: colorScheme.onSurfaceVariant.withOpacity(0.68),
                    height: 1.3,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
