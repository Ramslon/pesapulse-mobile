import 'package:flutter/material.dart';

import '../../utils/responsive_helper.dart';

class ExpenseDateHeader extends StatelessWidget {
  final String title;

  const ExpenseDateHeader({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    final compact = ResponsiveHelper.useCompactLayout(context);

    final horizontalPadding = ResponsiveHelper.horizontalPadding(context);

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final fontSize = compact ? 12.5 : 14.0;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        horizontalPadding,
        compact ? 13 : 17,
        horizontalPadding,
        compact ? 7 : 8,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Calendar identity
          Container(
            width: compact ? 30 : 33,
            height: compact ? 30 : 33,
            decoration: BoxDecoration(
              color: colorScheme.primary.withOpacity(0.09),
              borderRadius: BorderRadius.circular(compact ? 9 : 10),
            ),
            child: Icon(
              Icons.calendar_today_rounded,
              size: compact ? 14 : 15,
              color: colorScheme.primary,
            ),
          ),

          SizedBox(width: compact ? 8 : 10),

          Text(
            title,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w800,
              color: colorScheme.onSurface,
              letterSpacing: -0.1,
            ),
          ),

          SizedBox(width: compact ? 9 : 11),

          Expanded(
            child: Container(
              height: 1,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    colorScheme.outline.withOpacity(0.13),
                    colorScheme.outline.withOpacity(0.02),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
