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

    final compact = ResponsiveHelper.useCompactLayout(context);
    final landscape = ResponsiveHelper.isLandscape(context);
    final tablet = ResponsiveHelper.isTablet(context);
    final desktop = ResponsiveHelper.isDesktop(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.hasBoundedWidth
            ? constraints.maxWidth
            : ResponsiveHelper.width(context);

        final veryNarrow = width < 155;
        final narrow = width < 190;

        final effectiveCompact = compact || landscape || veryNarrow || narrow;

        final padding = _calculatePadding(
          compact: effectiveCompact,
          tablet: tablet,
          desktop: desktop,
          veryNarrow: veryNarrow,
        );

        final iconBoxSize = _calculateIconBoxSize(
          compact: effectiveCompact,
          tablet: tablet,
          desktop: desktop,
          veryNarrow: veryNarrow,
        );

        final iconSize = _calculateIconSize(
          compact: effectiveCompact,
          tablet: tablet,
          desktop: desktop,
          veryNarrow: veryNarrow,
        );

        final titleSize = _calculateTitleSize(
          compact: effectiveCompact,
          tablet: tablet,
          desktop: desktop,
          veryNarrow: veryNarrow,
        );

        final valueSize = _calculateValueSize(
          compact: effectiveCompact,
          tablet: tablet,
          desktop: desktop,
          veryNarrow: veryNarrow,
        );

        final radius = desktop
            ? 21.0
            : tablet
            ? 19.0
            : effectiveCompact
            ? 15.0
            : 18.0;

        final topSpacing = veryNarrow
            ? 8.0
            : effectiveCompact
            ? 10.0
            : desktop
            ? 13.0
            : 11.0;

        final valueSpacing = veryNarrow
            ? 5.0
            : effectiveCompact
            ? 7.0
            : 9.0;

        return TweenAnimationBuilder<double>(
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeOutCubic,
          tween: Tween(begin: 0.96, end: 1.0),
          builder: (_, scale, child) {
            return Transform.scale(scale: scale, child: child);
          },
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(radius),
              border: Border.all(color: colorScheme.outline.withOpacity(0.08)),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(
                    theme.brightness == Brightness.dark ? 0.07 : 0.055,
                  ),
                  blurRadius: desktop ? 18 : 12,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Padding(
              padding: EdgeInsets.all(padding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Icon + subtle accent indicator.
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        width: iconBoxSize,
                        height: iconBoxSize,
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.09),
                          borderRadius: BorderRadius.circular(
                            veryNarrow
                                ? 9
                                : effectiveCompact
                                ? 11
                                : 13,
                          ),
                          border: Border.all(color: color.withOpacity(0.10)),
                        ),
                        child: Icon(icon, color: color, size: iconSize),
                      ),

                      const Spacer(),

                      Container(
                        width: veryNarrow ? 5 : 6,
                        height: veryNarrow ? 5 : 6,
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.70),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: topSpacing),

                  // Metric title.
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant.withOpacity(0.72),
                      fontWeight: FontWeight.w700,
                      fontSize: titleSize,
                      letterSpacing: 0.05,
                      height: 1.15,
                    ),
                  ),

                  SizedBox(height: valueSpacing),

                  // Metric value.
                  _buildValue(context, valueSize: valueSize),

                  SizedBox(
                    height: veryNarrow
                        ? 7
                        : effectiveCompact
                        ? 9
                        : 11,
                  ),

                  // Semantic accent line.
                  Container(
                    width: veryNarrow
                        ? 22
                        : effectiveCompact
                        ? 30
                        : desktop
                        ? 42
                        : 36,
                    height: 3,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildValue(BuildContext context, {required double valueSize}) {
    final theme = Theme.of(context);

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 750),
      curve: Curves.easeOutCubic,
      builder: (context, animation, child) {
        return Opacity(
          opacity: animation,
          child: Transform.translate(
            offset: Offset(0, 6 * (1 - animation)),
            child: child,
          ),
        );
      },
      child: SizedBox(
        width: double.infinity,
        child: FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            value,
            maxLines: 1,
            softWrap: false,
            style: theme.textTheme.titleLarge?.copyWith(
              fontSize: valueSize,
              fontWeight: FontWeight.w900,
              height: 1.0,
              letterSpacing: -0.7,
            ),
          ),
        ),
      ),
    );
  }

  double _calculatePadding({
    required bool compact,
    required bool tablet,
    required bool desktop,
    required bool veryNarrow,
  }) {
    if (veryNarrow) {
      return 10;
    }

    if (desktop) {
      return 18;
    }

    if (tablet) {
      return 16;
    }

    if (compact) {
      return 12;
    }

    return 14;
  }

  double _calculateIconBoxSize({
    required bool compact,
    required bool tablet,
    required bool desktop,
    required bool veryNarrow,
  }) {
    if (veryNarrow) {
      return 28;
    }

    if (desktop) {
      return 44;
    }

    if (tablet) {
      return 40;
    }

    if (compact) {
      return 32;
    }

    return 37;
  }

  double _calculateIconSize({
    required bool compact,
    required bool tablet,
    required bool desktop,
    required bool veryNarrow,
  }) {
    if (veryNarrow) {
      return 15;
    }

    if (desktop) {
      return 23;
    }

    if (tablet) {
      return 21;
    }

    if (compact) {
      return 17;
    }

    return 19;
  }

  double _calculateTitleSize({
    required bool compact,
    required bool tablet,
    required bool desktop,
    required bool veryNarrow,
  }) {
    if (veryNarrow) {
      return 9.5;
    }

    if (desktop) {
      return 13.5;
    }

    if (tablet) {
      return 12.5;
    }

    if (compact) {
      return 10.5;
    }

    return 11.5;
  }

  double _calculateValueSize({
    required bool compact,
    required bool tablet,
    required bool desktop,
    required bool veryNarrow,
  }) {
    if (veryNarrow) {
      return 13;
    }

    if (desktop) {
      return 21;
    }

    if (tablet) {
      return 19;
    }

    if (compact) {
      return 15;
    }

    return 18;
  }
}
