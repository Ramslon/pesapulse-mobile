import 'package:flutter/material.dart';

class AnalyticsLayoutHelper {
  static bool isLandscape(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return size.width > size.height;
  }

  // Vertical spacing between major analytics sections.
  static double sectionSpacing(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return (size.height * .025).clamp(14.0, 24.0);
  }

  // More compact chart heights.
  static double chartHeight(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final landscape = size.width > size.height;

    if (landscape) {
      return (size.height * .40).clamp(150.0, 240.0);
    }

    return (size.height * .25).clamp(170.0, 280.0);
  }

  // Page padding.
  static double contentPadding(BuildContext context) {
    final size = MediaQuery.of(context).size;

    if (size.width >= 1200) {
      return 24.0;
    }

    if (size.width >= 900) {
      return 20.0;
    }

    if (size.width >= 600) {
      return 16.0;
    }

    return 14.0;
  }

  // Smaller spacing inside sections.
  static double smallSpacing(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return (size.height * .015).clamp(10.0, 16.0);
  }

  static double sectionHeaderSpacing(BuildContext context) {
    return smallSpacing(context);
  }

  // Maximum width for normal analytics cards.
  static double maxContentWidth(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    if (width >= 1200) {
      return 950.0;
    }

    if (width >= 900) {
      return 820.0;
    }

    return double.infinity;
  }

  // Charts can be slightly narrower than normal cards.
  static double maxChartWidth(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    if (width >= 1200) {
      return 700.0;
    }

    if (width >= 900) {
      return 620.0;
    }

    return double.infinity;
  }

  static const double cardSpacing = 16.0;

  static const double internalSpacing = 12.0;
}
