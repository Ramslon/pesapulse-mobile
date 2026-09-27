import 'package:flutter/material.dart';
import 'package:pesapulse_mobile/utils/responsive_helper.dart';

class ExpenseListHeader extends StatelessWidget {
  final double horizontalPadding;

  const ExpenseListHeader({super.key, required this.horizontalPadding});

  @override
  Widget build(BuildContext context) {
    final compact = ResponsiveHelper.useCompactLayout(context);
    final landscape = ResponsiveHelper.isLandscape(context);

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final titleSize = compact
        ? 28.0
        : landscape
        ? 29.0
        : 32.0;

    final subtitleSize = compact
        ? 12.5
        : landscape
        ? 13.0
        : 14.0;

    final topPadding = compact
        ? 16.0
        : landscape
        ? 18.0
        : 20.0;

    final iconSize = compact
        ? 40.0
        : landscape
        ? 42.0
        : 46.0;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        horizontalPadding,
        topPadding,
        horizontalPadding,
        compact ? 10 : 12,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Section overline
                Row(
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: colorScheme.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 7),
                    Text(
                      'EXPENSES',
                      style: TextStyle(
                        fontSize: compact ? 10 : 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.15,
                        color: colorScheme.primary,
                      ),
                    ),
                  ],
                ),

                SizedBox(height: compact ? 7 : 9),

                // Main title
                Text(
                  'Your spending',
                  style: TextStyle(
                    fontSize: titleSize,
                    height: 1.05,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.6,
                    color: colorScheme.onSurface,
                  ),
                ),

                const SizedBox(height: 7),

                // Description
                Text(
                  'Track, search and manage your transactions.',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: subtitleSize,
                    height: 1.35,
                    fontWeight: FontWeight.w500,
                    color: colorScheme.onSurface.withOpacity(0.58),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 12),

          // Expense workspace icon
          Container(
            width: iconSize,
            height: iconSize,
            decoration: BoxDecoration(
              color: colorScheme.primary.withOpacity(0.10),
              borderRadius: BorderRadius.circular(compact ? 13 : 15),
              border: Border.all(color: colorScheme.primary.withOpacity(0.08)),
            ),
            child: Icon(
              Icons.receipt_long_rounded,
              color: Colors.green,
              size: compact ? 21 : 23,
            ),
          ),
        ],
      ),
    );
  }
}
