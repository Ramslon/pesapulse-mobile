import 'package:flutter/material.dart';

import '../../utils/responsive_helper.dart';

class ForecastMetric extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const ForecastMetric({
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

    final double padding = isCompact
        ? 10
        : isLandscape
        ? 12
        : 14;

    final double iconBoxSize = isCompact ? 34 : 38;
    final double iconSize = isCompact ? 17 : 19;
    final double spacing = isCompact ? 8 : 11;

    final double titleFontSize = isCompact ? 11 : 12;
    final double valueFontSize = isCompact ? 13 : 14;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: color.withOpacity(.06),
        borderRadius: BorderRadius.circular(isCompact ? 14 : 16),
        border: Border.all(color: color.withOpacity(.12)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ─────────────────────────────────────────
          // Metric icon
          // ─────────────────────────────────────────
          Container(
            width: iconBoxSize,
            height: iconBoxSize,
            decoration: BoxDecoration(
              color: color.withOpacity(.10),
              borderRadius: BorderRadius.circular(isCompact ? 10 : 12),
            ),
            child: Icon(icon, color: color, size: iconSize),
          ),

          SizedBox(width: spacing),

          // ─────────────────────────────────────────
          // Metric information
          // ─────────────────────────────────────────
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: isCompact ? 2 : 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                    fontSize: titleFontSize,
                    height: 1.2,
                  ),
                ),

                SizedBox(height: isCompact ? 4 : 5),

                Text(
                  value,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.w800,
                    fontSize: valueFontSize,
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
