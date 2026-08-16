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

    final iconBoxSize = desktop
        ? 48.0
        : tablet
        ? 46.0
        : compact
        ? 34.0
        : landscape
        ? 38.0
        : 44.0;

    final iconSize = desktop
        ? 24.0
        : tablet
        ? 23.0
        : compact
        ? 18.0
        : landscape
        ? 20.0
        : 22.0;

    final titleSize = desktop
        ? 18.0
        : tablet
        ? 17.0
        : compact
        ? 13.0
        : landscape
        ? 14.0
        : 16.0;

    final subtitleSize = desktop
        ? 14.0
        : tablet
        ? 13.0
        : compact
        ? 10.0
        : landscape
        ? 10.5
        : 12.0;

    final amountSize = desktop
        ? 32.0
        : tablet
        ? 30.0
        : compact
        ? 22.0
        : landscape
        ? 24.0
        : 28.0;

    final headerSpacing = compact
        ? 8.0
        : landscape
        ? 10.0
        : 14.0;

    final headerBottomSpacing = compact
        ? 14.0
        : landscape
        ? 16.0
        : 22.0;

    final amountLabelSpacing = compact ? 4.0 : 6.0;

    final borderRadius = compact ? 15.0 : 20.0;
    final iconRadius = compact ? 10.0 : 14.0;

    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 500),
      tween: Tween(begin: 0.96, end: 1),
      curve: Curves.easeOutCubic,
      builder: (_, scale, child) {
        return Transform.scale(scale: scale, child: child);
      },
      child: Card(
        elevation: compact ? 1 : 2,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        child: Padding(
          padding: EdgeInsets.all(cardPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ─────────────────────────────────────
              // Header
              // ─────────────────────────────────────
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: iconBoxSize,
                    height: iconBoxSize,
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withOpacity(0.10),
                      borderRadius: BorderRadius.circular(iconRadius),
                    ),
                    child: Icon(
                      Icons.analytics_outlined,
                      color: colorScheme.primary,
                      size: iconSize,
                    ),
                  ),

                  SizedBox(width: headerSpacing),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Analytics Overview',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontSize: titleSize,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 3),

                        Text(
                          'Track your spending and financial progress',
                          maxLines: compact ? 2 : 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontSize: subtitleSize,
                            height: 1.25,
                            color: theme.textTheme.bodySmall?.color
                                ?.withOpacity(0.65),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              SizedBox(height: headerBottomSpacing),

              // ─────────────────────────────────────
              // Total spending
              // ─────────────────────────────────────
              TweenAnimationBuilder<double>(
                duration: const Duration(milliseconds: 900),
                curve: Curves.easeOutCubic,
                tween: Tween(begin: 0, end: totalSpending),
                builder: (_, value, __) {
                  return FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      CurrencyFormatter.format(value),
                      maxLines: 1,
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontSize: amountSize,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.5,
                      ),
                    ),
                  );
                },
              ),

              SizedBox(height: amountLabelSpacing),

              Text(
                'Total Spending',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontSize: compact ? 10.0 : 12.0,
                  color: theme.textTheme.bodySmall?.color?.withOpacity(0.65),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
