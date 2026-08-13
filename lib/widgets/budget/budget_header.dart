import 'package:flutter/material.dart';

import '../../utils/responsive_helper.dart';

class BudgetHeader extends StatelessWidget {
  const BudgetHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final compact = ResponsiveHelper.useCompactLayout(context);

    final tablet = ResponsiveHelper.isTablet(context);

    final desktop = ResponsiveHelper.isDesktop(context);

    final landscape = ResponsiveHelper.isLandscape(context);

    final titleSize = compact
        ? 24.0
        : tablet
        ? 28.0
        : desktop
        ? 32.0
        : landscape
        ? 26.0
        : 30.0;

    final subtitleSize = compact
        ? 13.0
        : tablet
        ? 14.0
        : desktop
        ? 15.0
        : 15.0;

    final titleBottomSpacing = compact
        ? 4.0
        : landscape
        ? 5.0
        : 8.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Budget Overview",
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            letterSpacing: .2,
            fontSize: titleSize,
          ),
        ),

        SizedBox(height: titleBottomSpacing),

        Text(
          "Track your spending and stay within budget",
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: theme.textTheme.bodyMedium?.color?.withOpacity(.7),
            fontSize: subtitleSize,
            height: compact ? 1.25 : 1.35,
          ),
        ),
      ],
    );
  }
}
