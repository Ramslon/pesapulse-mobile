import 'package:flutter/material.dart';

import '../../utils/responsive_helper.dart';

class GoalStatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const GoalStatCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final isCompact = ResponsiveHelper.useCompactLayout(context);
    final isLandscape = ResponsiveHelper.isLandscape(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final availableHeight = constraints.maxHeight;

        // The card adapts to the actual grid tile height.
        final isShort = availableHeight < 145;
        final isVeryShort = availableHeight < 125;

        final double padding;

        if (isVeryShort) {
          padding = 10;
        } else if (isShort) {
          padding = 12;
        } else if (isCompact) {
          padding = 14;
        } else if (isLandscape) {
          padding = 15;
        } else {
          padding = 18;
        }

        final double iconContainerSize;

        if (isVeryShort) {
          iconContainerSize = 32;
        } else if (isShort) {
          iconContainerSize = 36;
        } else if (isCompact) {
          iconContainerSize = 38;
        } else {
          iconContainerSize = 44;
        }

        final double iconSize;

        if (isVeryShort) {
          iconSize = 17;
        } else if (isShort) {
          iconSize = 19;
        } else if (isCompact) {
          iconSize = 20;
        } else {
          iconSize = 23;
        }

        final double accentHeight;

        if (isVeryShort) {
          accentHeight = 18;
        } else if (isShort) {
          accentHeight = 21;
        } else if (isCompact) {
          accentHeight = 23;
        } else {
          accentHeight = 28;
        }

        final double topSpacing;

        if (isVeryShort) {
          topSpacing = 7;
        } else if (isShort) {
          topSpacing = 9;
        } else if (isCompact) {
          topSpacing = 12;
        } else {
          topSpacing = 18;
        }

        final double valueFontSize;

        if (isVeryShort) {
          valueFontSize = 18;
        } else if (isShort) {
          valueFontSize = 20;
        } else if (isCompact) {
          valueFontSize = 21;
        } else {
          valueFontSize = 24;
        }

        final double labelFontSize;

        if (isVeryShort) {
          labelFontSize = 10;
        } else if (isShort) {
          labelFontSize = 11;
        } else if (isCompact) {
          labelFontSize = 12;
        } else {
          labelFontSize = 14;
        }

        return Card(
          elevation: 0,
          margin: EdgeInsets.zero,
          color: colorScheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(isCompact ? 17 : 20),
            side: BorderSide(color: colorScheme.outline.withOpacity(.10)),
          ),
          child: Padding(
            padding: EdgeInsets.all(padding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ─────────────────────────────────────────
                // Icon + accent
                // ─────────────────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: iconContainerSize,
                      height: iconContainerSize,
                      decoration: BoxDecoration(
                        color: color.withOpacity(.10),
                        borderRadius: BorderRadius.circular(
                          isCompact ? 12 : 14,
                        ),
                      ),
                      child: Icon(icon, color: color, size: iconSize),
                    ),

                    Container(
                      width: 4,
                      height: accentHeight,
                      decoration: BoxDecoration(
                        color: color.withOpacity(.75),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ],
                ),

                SizedBox(height: topSpacing),

                // ─────────────────────────────────────────
                // Value
                // ─────────────────────────────────────────
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontSize: valueFontSize,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -.5,
                    height: 1.0,
                  ),
                ),

                SizedBox(height: isVeryShort ? 2 : 4),

                // ─────────────────────────────────────────
                // Label
                // ─────────────────────────────────────────
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontSize: labelFontSize,
                    color: colorScheme.onSurface.withOpacity(.60),
                    fontWeight: FontWeight.w500,
                    height: 1.0,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
