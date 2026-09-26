import 'package:flutter/material.dart';

import '../../utils/responsive_helper.dart';

class BudgetHeader extends StatelessWidget {
  const BudgetHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final compact = ResponsiveHelper.useCompactLayout(context);
    final tablet = ResponsiveHelper.isTablet(context);
    final desktop = ResponsiveHelper.isDesktop(context);
    final landscape = ResponsiveHelper.isLandscape(context);

    final titleSize = desktop
        ? 32.0
        : tablet
        ? 29.0
        : landscape
        ? 26.0
        : compact
        ? 24.0
        : 30.0;

    final subtitleSize = desktop
        ? 14.5
        : tablet
        ? 13.5
        : compact
        ? 11.5
        : 13.0;

    final labelSize = desktop
        ? 9.5
        : compact
        ? 7.5
        : 8.5;

    final accentWidth = desktop
        ? 42.0
        : compact
        ? 28.0
        : 34.0;

    final accentHeight = desktop
        ? 4.0
        : compact
        ? 3.0
        : 3.5;

    final titleBottomSpacing = compact
        ? 5.0
        : landscape
        ? 6.0
        : 7.0;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: accentWidth,
                    height: accentHeight,
                    decoration: BoxDecoration(
                      color: colorScheme.primary,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),

                  const SizedBox(width: 7),

                  Text(
                    'BUDGET PLANNING',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: colorScheme.primary.withOpacity(0.78),
                      fontSize: labelSize,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.0,
                      height: 1.0,
                    ),
                  ),
                ],
              ),

              SizedBox(height: compact ? 7 : 9),

              Text(
                'Budget Overview',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.headlineMedium?.copyWith(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.7,
                  fontSize: titleSize,
                  height: 1.0,
                ),
              ),

              SizedBox(height: titleBottomSpacing),

              Text(
                'Track your spending and stay within budget',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant.withOpacity(0.70),
                  fontSize: subtitleSize,
                  height: compact ? 1.3 : 1.4,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(width: 12),

        Container(
          width: desktop
              ? 42.0
              : compact
              ? 34.0
              : 38.0,
          height: desktop
              ? 42.0
              : compact
              ? 34.0
              : 38.0,
          decoration: BoxDecoration(
            color: colorScheme.primary.withOpacity(0.08),
            borderRadius: BorderRadius.circular(compact ? 10 : 12),
            border: Border.all(color: colorScheme.primary.withOpacity(0.10)),
          ),
          child: Icon(
            Icons.account_balance_wallet_rounded,
            color: colorScheme.primary,
            size: desktop
                ? 22
                : compact
                ? 17
                : 20,
          ),
        ),
      ],
    );
  }
}
