import 'package:flutter/material.dart';

// Reusable responsive layout helper for PesaPulse.
//
// Centralizes screen-size and orientation decisions so individual
// widgets do not need to repeat MediaQuery/LayoutBuilder logic.
class ResponsiveHelper {
  ResponsiveHelper._();

  // ─────────────────────────────────────────────
  // Breakpoints
  // ─────────────────────────────────────────────

  /// Small phones and compact mobile screens.
  static const double mobileBreakpoint = 600;

  /// Tablets and larger screens.
  static const double tabletBreakpoint = 900;

  /// Desktop / large-screen breakpoint.
  static const double desktopBreakpoint = 1200;

  // ─────────────────────────────────────────────
  // Screen type
  // ─────────────────────────────────────────────

  static bool isMobile(BuildContext context) {
    return MediaQuery.sizeOf(context).shortestSide < mobileBreakpoint;
  }

  static bool isTablet(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final shortestSide = MediaQuery.sizeOf(context).shortestSide;

    return shortestSide >= mobileBreakpoint && width < desktopBreakpoint;
  }

  static bool isDesktop(BuildContext context) {
    return MediaQuery.sizeOf(context).width >= desktopBreakpoint;
  }

  // ─────────────────────────────────────────────
  // Orientation
  // ─────────────────────────────────────────────

  static bool isPortrait(BuildContext context) {
    return MediaQuery.orientationOf(context) == Orientation.portrait;
  }

  static bool isLandscape(BuildContext context) {
    return MediaQuery.orientationOf(context) == Orientation.landscape;
  }

  // ─────────────────────────────────────────────
  // Device categories
  // ─────────────────────────────────────────────

  static bool isMobilePortrait(BuildContext context) {
    return isMobile(context) && isPortrait(context);
  }

  static bool isMobileLandscape(BuildContext context) {
    return isMobile(context) && isLandscape(context);
  }

  static bool isTabletPortrait(BuildContext context) {
    return isTablet(context) && isPortrait(context);
  }

  static bool isTabletLandscape(BuildContext context) {
    return isTablet(context) && isLandscape(context);
  }

  // ─────────────────────────────────────────────
  // Width / height
  // ─────────────────────────────────────────────

  static double width(BuildContext context) {
    return MediaQuery.sizeOf(context).width;
  }

  static double height(BuildContext context) {
    return MediaQuery.sizeOf(context).height;
  }

  // ─────────────────────────────────────────────
  // Content width
  // ─────────────────────────────────────────────

  static double contentMaxWidth(BuildContext context) {
    if (isDesktop(context)) {
      return 1100;
    }

    if (isTablet(context)) {
      return 900;
    }

    return double.infinity;
  }

  static double horizontalPadding(BuildContext context) {
    if (isDesktop(context)) {
      return 32;
    }

    if (isTablet(context)) {
      return 24;
    }

    return 16;
  }

  // ─────────────────────────────────────────────
  // Grid columns
  // ─────────────────────────────────────────────

  static int gridColumns(
    BuildContext context, {
    int mobilePortrait = 2,
    int mobileLandscape = 3,
    int tabletPortrait = 3,
    int tabletLandscape = 4,
    int desktop = 4,
  }) {
    if (isDesktop(context)) {
      return desktop;
    }

    if (isTabletLandscape(context)) {
      return tabletLandscape;
    }

    if (isTabletPortrait(context)) {
      return tabletPortrait;
    }

    if (isMobileLandscape(context)) {
      return mobileLandscape;
    }

    return mobilePortrait;
  }

  // ─────────────────────────────────────────────
  // Spacing
  // ─────────────────────────────────────────────

  static double spacing(BuildContext context) {
    if (isDesktop(context)) {
      return 20;
    }

    if (isTablet(context)) {
      return 18;
    }

    return 14;
  }

  static double sectionSpacing(BuildContext context) {
    if (isDesktop(context)) {
      return 28;
    }

    if (isTablet(context)) {
      return 24;
    }

    return 20;
  }

  // ─────────────────────────────────────────────
  // Card padding
  // ─────────────────────────────────────────────

  static double cardPadding(BuildContext context) {
    if (isDesktop(context)) {
      return 24;
    }

    if (isTablet(context)) {
      return 22;
    }

    return 18;
  }

  // ─────────────────────────────────────────────
  // Compact layout
  // ─────────────────────────────────────────────

  static bool useCompactLayout(BuildContext context) {
    return isMobile(context) && isPortrait(context);
  }

  /// Useful when landscape mode has limited vertical space.
  static bool useDenseVerticalLayout(BuildContext context) {
    return isLandscape(context);
  }
}
