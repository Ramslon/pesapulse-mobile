import 'package:flutter/material.dart';
import '../utils/responsive_helper.dart';

class DashboardCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String value;
  final IconData icon;
  final Color iconColor;

  const DashboardCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.icon,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final compact = ResponsiveHelper.useCompactLayout(context);
    final landscape = ResponsiveHelper.isLandscape(context);

    final horizontalPadding = compact
        ? 12.0
        : landscape
        ? 14.0
        : 16.0;

    final verticalPadding = compact
        ? 12.0
        : landscape
        ? 13.0
        : 16.0;

    final iconContainerSize = compact
        ? 34.0
        : landscape
        ? 38.0
        : 40.0;

    final iconSize = compact
        ? 18.0
        : landscape
        ? 20.0
        : 21.0;

    final titleSize = compact
        ? 12.0
        : landscape
        ? 12.5
        : 13.0;

    final subtitleSize = compact
        ? 10.0
        : landscape
        ? 10.5
        : 11.0;

    final valueSize = compact
        ? 19.0
        : landscape
        ? 20.0
        : 22.0;

    final radius = compact ? 16.0 : 18.0;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.08),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.035),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: horizontalPadding,
          vertical: verticalPadding,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: iconContainerSize,
                  height: iconContainerSize,
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(compact ? 10 : 12),
                  ),
                  child: Icon(icon, color: iconColor, size: iconSize),
                ),

                SizedBox(width: compact ? 9 : 10),

                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: titleSize,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.1,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ),
              ],
            ),

            SizedBox(height: compact ? 10 : 12),

            // Supporting label
            Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: subtitleSize,
                fontWeight: FontWeight.w500,
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withOpacity(0.55),
              ),
            ),

            SizedBox(height: compact ? 3 : 4),

            // Main value
            Expanded(
              child: Align(
                alignment: Alignment.bottomLeft,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    value,
                    maxLines: 1,
                    style: TextStyle(
                      fontSize: valueSize,
                      fontWeight: FontWeight.w800,
                      height: 1.05,
                      letterSpacing: -0.3,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ),
              ),
            ),

            SizedBox(height: compact ? 9 : 11),

            // Semantic accent
            Container(
              height: 3,
              width: compact ? 30 : 36,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.75),
                borderRadius: BorderRadius.circular(100),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
