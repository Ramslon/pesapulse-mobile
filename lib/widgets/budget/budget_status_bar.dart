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
    final colorScheme = theme.colorScheme;

    final compact = ResponsiveHelper.useCompactLayout(context);
    final tablet = ResponsiveHelper.isTablet(context);
    final desktop = ResponsiveHelper.isDesktop(context);
    final landscape = ResponsiveHelper.isLandscape(context);

    final radius = desktop
        ? 16.0
        : compact
        ? 13.0
        : 15.0;

    final horizontalPadding = desktop
        ? 14.0
        : tablet
        ? 12.0
        : compact
        ? 9.0
        : 11.0;

    final verticalPadding = desktop
        ? 10.0
        : compact
        ? 7.0
        : landscape
        ? 8.0
        : 9.0;

    final labelSize = desktop
        ? 10.5
        : compact
        ? 8.0
        : 9.5;

    final statusSize = desktop
        ? 11.5
        : compact
        ? 9.0
        : 10.5;

    final iconBoxSize = desktop
        ? 32.0
        : compact
        ? 27.0
        : 30.0;

    final iconSize = desktop
        ? 17.0
        : compact
        ? 14.0
        : 16.0;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: horizontalPadding,
        vertical: verticalPadding,
      ),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(
          theme.brightness == Brightness.dark ? 0.08 : 0.045,
        ),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: statusColor.withOpacity(0.13)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: iconBoxSize,
            height: iconBoxSize,
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.10),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _statusIcon(statusText),
              color: statusColor,
              size: iconSize,
            ),
          ),

          SizedBox(width: compact ? 8 : 10),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'CURRENT BUDGET STATUS',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: colorScheme.onSurfaceVariant.withOpacity(0.62),
                    fontSize: labelSize,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.75,
                  ),
                ),

                const SizedBox(height: 2),

                Text(
                  'Monthly Budget',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: colorScheme.onSurface,
                    fontSize: compact ? 10.5 : 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 10),

          ConstrainedBox(
            constraints: BoxConstraints(maxWidth: compact ? 105 : 145),
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: compact ? 8 : 10,
                vertical: compact ? 5 : 6,
              ),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.10),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: statusColor.withOpacity(0.13)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: compact ? 5 : 6,
                    height: compact ? 5 : 6,
                    decoration: BoxDecoration(
                      color: statusColor,
                      shape: BoxShape.circle,
                    ),
                  ),

                  const SizedBox(width: 6),

                  Flexible(
                    child: Text(
                      statusText,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: statusColor,
                        fontSize: statusSize,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _statusIcon(String status) {
    final normalized = status.toLowerCase();

    if (normalized.contains('over') ||
        normalized.contains('exceed') ||
        normalized.contains('critical')) {
      return Icons.error_outline_rounded;
    }

    if (normalized.contains('warning') ||
        normalized.contains('caution') ||
        normalized.contains('high') ||
        normalized.contains('risk')) {
      return Icons.warning_amber_rounded;
    }

    if (normalized.contains('good') ||
        normalized.contains('healthy') ||
        normalized.contains('track') ||
        normalized.contains('safe')) {
      return Icons.check_circle_outline_rounded;
    }

    return Icons.account_balance_wallet_outlined;
  }
}
