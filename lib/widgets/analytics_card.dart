import 'package:flutter/material.dart';

import '../../utils/responsive_helper.dart';

class AnalyticsCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final Color color;

  const AnalyticsCard({
    super.key,
    required this.icon,
    required this.title,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final isTablet = ResponsiveHelper.isTablet(context);
    final isDesktop = ResponsiveHelper.isDesktop(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        // LayoutBuilder handles the actual space available to the card,
        // while ResponsiveHelper handles device-level responsiveness.
        final compact =
            constraints.maxHeight < 120 ||
            ResponsiveHelper.useDenseVerticalLayout(context);

        final veryCompact = constraints.maxHeight < 95;

        final padding = veryCompact
            ? 10.0
            : compact
            ? 12.0
            : isDesktop
            ? 20.0
            : isTablet
            ? 18.0
            : 16.0;

        final iconBox = veryCompact
            ? 28.0
            : compact
            ? 34.0
            : isDesktop
            ? 44.0
            : 40.0;

        final iconSize = veryCompact
            ? 16.0
            : compact
            ? 18.0
            : isDesktop
            ? 25.0
            : 22.0;

        final titleSize = veryCompact
            ? 10.0
            : compact
            ? 11.0
            : isDesktop
            ? 14.0
            : isTablet
            ? 13.5
            : 13.0;

        final valueSize = veryCompact
            ? 14.0
            : compact
            ? 15.0
            : isDesktop
            ? 20.0
            : isTablet
            ? 19.0
            : 18.0;

        final radius = compact ? 16.0 : 20.0;

        return Card(
          elevation: compact ? 1 : 2,
          shadowColor: color.withOpacity(0.12),
          surfaceTintColor: color.withOpacity(0.025),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radius),
          ),
          child: Padding(
            padding: EdgeInsets.all(padding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: iconBox,
                  height: iconBox,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color, size: iconSize),
                ),

                SizedBox(
                  height: veryCompact
                      ? 4
                      : compact
                      ? 7
                      : 10,
                ),

                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurface.withOpacity(0.65),
                    fontWeight: FontWeight.w600,
                    fontSize: titleSize,
                    letterSpacing: 0.2,
                  ),
                ),

                Divider(
                  color: colorScheme.onSurface.withOpacity(0.08),
                  thickness: 0.8,
                  height: veryCompact
                      ? 8
                      : compact
                      ? 11
                      : 16,
                ),

                Expanded(
                  child: Align(
                    alignment: Alignment.bottomLeft,
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: 1),
                      duration: const Duration(milliseconds: 800),
                      curve: Curves.easeOutCubic,
                      builder: (context, animation, child) {
                        return Opacity(
                          opacity: animation,
                          child: Transform.translate(
                            offset: Offset(0, 8 * (1 - animation)),
                            child: child,
                          ),
                        );
                      },
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          value,
                          maxLines: 1,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: valueSize,
                            height: 1.15,
                            letterSpacing: -0.2,
                          ),
                        ),
                      ),
                    ),
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
