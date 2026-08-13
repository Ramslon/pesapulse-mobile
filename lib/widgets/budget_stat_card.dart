import 'package:flutter/material.dart';

import '../../utils/responsive_helper.dart';

class BudgetStatCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final Color color;

  const BudgetStatCard({
    super.key,
    required this.icon,
    required this.title,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final compact = ResponsiveHelper.useCompactLayout(context);

    final landscape = ResponsiveHelper.isLandscape(context);

    final tablet = ResponsiveHelper.isTablet(context);

    final desktop = ResponsiveHelper.isDesktop(context);

    final padding = _padding(
      compact: compact,
      landscape: landscape,
      tablet: tablet,
      desktop: desktop,
    );

    final iconRadius = _iconRadius(
      compact: compact,
      tablet: tablet,
      desktop: desktop,
    );

    final iconSize = _iconSize(
      compact: compact,
      tablet: tablet,
      desktop: desktop,
    );

    final titleSize = _titleSize(
      compact: compact,
      tablet: tablet,
      desktop: desktop,
    );

    final valueSize = _valueSize(
      compact: compact,
      tablet: tablet,
      desktop: desktop,
    );

    final spacing = _spacing(
      compact: compact,
      landscape: landscape,
      tablet: tablet,
      desktop: desktop,
    );

    final radius = _borderRadius(
      compact: compact,
      landscape: landscape,
      tablet: tablet,
      desktop: desktop,
    );

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.95, end: 1),
      duration: const Duration(milliseconds: 700),
      curve: Curves.easeOutBack,
      builder: (context, scale, child) {
        return Transform.scale(scale: scale, child: child);
      },
      child: Card(
        elevation: landscape ? 1 : 2,
        shadowColor: color.withOpacity(.12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius),
        ),
        child: Padding(
          padding: EdgeInsets.all(padding),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: iconRadius,
                backgroundColor: color.withOpacity(.12),
                child: Icon(icon, color: color, size: iconSize),
              ),

              SizedBox(height: spacing),

              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: titleSize,
                  fontWeight: FontWeight.w500,
                ),
              ),

              const SizedBox(height: 2),

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
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  double _padding({
    required bool compact,
    required bool landscape,
    required bool tablet,
    required bool desktop,
  }) {
    if (desktop) return 20;
    if (tablet) return 18;
    if (landscape) return 12;
    if (compact) return 14;
    return 16;
  }

  double _iconRadius({
    required bool compact,
    required bool tablet,
    required bool desktop,
  }) {
    if (desktop) return 20;
    if (tablet) return 19;
    if (compact) return 16;
    return 18;
  }

  double _iconSize({
    required bool compact,
    required bool tablet,
    required bool desktop,
  }) {
    if (desktop) return 24;
    if (tablet) return 23;
    if (compact) return 18;
    return 22;
  }

  double _titleSize({
    required bool compact,
    required bool tablet,
    required bool desktop,
  }) {
    if (desktop) return 14;
    if (tablet) return 13;
    if (compact) return 11.5;
    return 12.5;
  }

  double _valueSize({
    required bool compact,
    required bool tablet,
    required bool desktop,
  }) {
    if (desktop) return 21;
    if (tablet) return 19;
    if (compact) return 15;
    return 20;
  }

  double _spacing({
    required bool compact,
    required bool landscape,
    required bool tablet,
    required bool desktop,
  }) {
    if (desktop) return 10;
    if (tablet) return 9;
    if (landscape) return 5;
    if (compact) return 7;
    return 10;
  }

  double _borderRadius({
    required bool compact,
    required bool landscape,
    required bool tablet,
    required bool desktop,
  }) {
    if (desktop) return 22;
    if (tablet) return 20;
    if (landscape) return 16;
    if (compact) return 16;
    return 20;
  }
}
