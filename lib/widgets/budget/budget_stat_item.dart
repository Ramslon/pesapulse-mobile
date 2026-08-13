import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../utils/responsive_helper.dart';

class BudgetStatItem extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color backgroundColor;
  final String title;
  final double amount;

  const BudgetStatItem({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.backgroundColor,
    required this.title,
    required this.amount,
  });

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat("#,##0");

    final compact = ResponsiveHelper.useCompactLayout(context);

    final tablet = ResponsiveHelper.isTablet(context);

    final desktop = ResponsiveHelper.isDesktop(context);

    final landscape = ResponsiveHelper.isLandscape(context);

    final avatarRadius = compact
        ? 16.0
        : tablet
        ? 19.0
        : desktop
        ? 20.0
        : landscape
        ? 17.0
        : 20.0;

    final iconSize = compact
        ? 18.0
        : tablet
        ? 21.0
        : desktop
        ? 23.0
        : landscape
        ? 19.0
        : 24.0;

    final amountFontSize = compact
        ? 15.0
        : tablet
        ? 16.0
        : desktop
        ? 18.0
        : landscape
        ? 15.0
        : 17.0;

    final titleFontSize = compact
        ? 12.0
        : tablet
        ? 13.0
        : desktop
        ? 14.0
        : landscape
        ? 12.0
        : 14.0;

    final verticalSpacing = compact
        ? 6.0
        : landscape
        ? 7.0
        : 10.0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircleAvatar(
          radius: avatarRadius,
          backgroundColor: backgroundColor,
          child: Icon(icon, size: iconSize, color: iconColor),
        ),

        SizedBox(height: verticalSpacing),

        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: amount),
          duration: const Duration(milliseconds: 1000),
          curve: Curves.easeOutCubic,
          builder: (context, value, child) {
            return FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                "KES ${formatter.format(value)}",
                maxLines: 1,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: amountFontSize,
                  height: 1.1,
                ),
              ),
            );
          },
        ),

        SizedBox(
          height: compact
              ? 4
              : landscape
              ? 5
              : 8,
        ),

        Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: titleFontSize,
            fontWeight: FontWeight.w500,
            color: Theme.of(
              context,
            ).textTheme.bodyMedium?.color?.withOpacity(.75),
          ),
        ),
      ],
    );
  }
}
