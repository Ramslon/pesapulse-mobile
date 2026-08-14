import 'package:flutter/material.dart';

import '../utils/responsive_helper.dart';

class InputIconBadge extends StatelessWidget {
  final IconData icon;
  final Color color;

  /// Optional icon size override.
  /// If null, ResponsiveHelper determines the size.
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

    // Responsive icon size
    final iconSize =
        size ??
        (desktop
            ? 22.0
            : tablet
            ? 21.0
            : compact
            ? 16.0
            : landscape
            ? 17.0
            : 20.0);

    // Responsive badge size
    final badgeSize = desktop
        ? 44.0
        : tablet
        ? 42.0
        : compact
        ? 32.0
        : landscape
        ? 34.0
        : 42.0;

    // Responsive outer padding
    final badgePadding = desktop
        ? 8.0
        : tablet
        ? 7.0
        : compact
        ? 5.0
        : landscape
        ? 5.0
        : 8.0;

    return Padding(
      padding: EdgeInsets.all(badgePadding),
      child: Container(
        width: badgeSize,
        height: badgeSize,
        decoration: BoxDecoration(
          color: color.withOpacity(.21),
          borderRadius: BorderRadius.circular(badgeSize / 2),
        ),
        alignment: Alignment.center,
        child: Icon(icon, color: color, size: iconSize),
      ),
    );
  }
}
