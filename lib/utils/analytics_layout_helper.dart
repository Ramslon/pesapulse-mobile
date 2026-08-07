import 'package:flutter/material.dart';

class AnalyticsLayoutHelper {
  static bool isLandscape(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return size.width > size.height;
  }

  static double sectionSpacing(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return (size.height * .035).clamp(20.0, 32.0);
  }

  static double chartHeight(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final landscape = size.width > size.height;

    if (landscape) {
      return (size.height * .55).clamp(180.0, 320.0);
    }

    return (size.height * .32).clamp(220.0, 360.0);
  }

  static double contentPadding(BuildContext context) {
    final size = MediaQuery.of(context).size;

    if (size.width >= 900) {
      return 28.0;
    }

    if (size.width >= 600) {
      return 24.0;
    }

    return 20.0;
  }

  static double smallSpacing(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return (size.height * .02).clamp(16.0, 24.0);
  }

  static double sectionHeaderSpacing(BuildContext context) {
    return smallSpacing(context);
  }

  static const double cardSpacing = 24.0;

  static const double internalSpacing = 16.0;
}
