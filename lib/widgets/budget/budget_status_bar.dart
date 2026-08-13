import 'package:flutter/material.dart';

import '../../utils/responsive_helper.dart';

class BudgetStatusBar extends StatelessWidget {
  final String statusText;
  final Color statusColor;

  const BudgetStatusBar({
    super.key,
    required this.statusText,
    required this.statusColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final compact = ResponsiveHelper.useCompactLayout(context);

    final tablet = ResponsiveHelper.isTablet(context);

    final desktop = ResponsiveHelper.isDesktop(context);

    final horizontalPadding = _horizontalPadding(
      compact: compact,
      tablet: tablet,
      desktop: desktop,
    );

    final verticalPadding = _verticalPadding(
      compact: compact,
      tablet: tablet,
      desktop: desktop,
    );

    final labelSize = _labelSize(
      compact: compact,
      tablet: tablet,
      desktop: desktop,
    );

    final statusSize = _statusSize(
      compact: compact,
      tablet: tablet,
      desktop: desktop,
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Text(
            "Monthly Budget",
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(.7),
              fontWeight: FontWeight.w600,
              fontSize: labelSize,
            ),
          ),
        ),

        const SizedBox(width: 12),

        Flexible(
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: horizontalPadding,
              vertical: verticalPadding,
            ),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(.12),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: statusColor.withOpacity(.18)),
            ),
            child: Text(
              statusText,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: statusColor,
                fontWeight: FontWeight.bold,
                fontSize: statusSize,
              ),
            ),
          ),
        ),
      ],
    );
  }

  double _horizontalPadding({
    required bool compact,
    required bool tablet,
    required bool desktop,
  }) {
    if (desktop) return 16;
    if (tablet) return 14;
    if (compact) return 10;
    return 12;
  }

  double _verticalPadding({
    required bool compact,
    required bool tablet,
    required bool desktop,
  }) {
    if (desktop) return 7;
    if (tablet) return 6;
    if (compact) return 4;
    return 6;
  }

  double _labelSize({
    required bool compact,
    required bool tablet,
    required bool desktop,
  }) {
    if (desktop) return 16;
    if (tablet) return 15;
    if (compact) return 13;
    return 15;
  }

  double _statusSize({
    required bool compact,
    required bool tablet,
    required bool desktop,
  }) {
    if (desktop) return 14;
    if (tablet) return 13;
    if (compact) return 12;
    return 14;
  }
}
