import 'package:flutter/material.dart';

import '../utils/responsive_helper.dart';

class InputIconBadge extends StatelessWidget {
  final IconData icon;
  final Color color;

  /// Optional icon size override.
  /// If null, ResponsiveHelper determines the icon size.
  final double? size;

  const InputIconBadge({
    super.key,
    required this.icon,
    required this.color,
    this.size,
  });

  @override
  Widget build(BuildContext context) {
    final compact = ResponsiveHelper.useCompactLayout(context);

    final landscape = ResponsiveHelper.isLandscape(context);

    final tablet = ResponsiveHelper.isTablet(context);

    final desktop = ResponsiveHelper.isDesktop(context);

    final iconSize =
        size ??
        (desktop
            ? 20.0
            : tablet
            ? 19.0
            : compact
            ? 15.0
            : landscape
            ? 17.0
            : 18.0);

    final badgeSize = desktop
        ? 38.0
        : tablet
        ? 36.0
        : compact
        ? 30.0
        : landscape
        ? 32.0
        : 36.0;

    final radius = compact
        ? 9.0
        : landscape
        ? 10.0
        : 11.0;

    return SizedBox(
      width: badgeSize,
      height: badgeSize,
      child: Center(
        child: Container(
          width: badgeSize,
          height: badgeSize,
          decoration: BoxDecoration(
            color: color.withOpacity(0.10),
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(color: color.withOpacity(0.07)),
          ),
          child: Icon(icon, color: color, size: iconSize),
        ),
      ),
    );
  }
}
