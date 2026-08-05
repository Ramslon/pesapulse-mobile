import 'package:flutter/widgets.dart';

class AppSpacing {
  // Heights
  static const SizedBox xs = SizedBox(height: 4);
  static const SizedBox sm = SizedBox(height: 8);
  static const SizedBox md = SizedBox(height: 16);
  static const SizedBox lg = SizedBox(height: 24);
  static const SizedBox xl = SizedBox(height: 32);

  // Widths
  static const SizedBox hXs = SizedBox(width: 4);
  static const SizedBox hSm = SizedBox(width: 8);
  static const SizedBox hMd = SizedBox(width: 16);
  static const SizedBox hLg = SizedBox(width: 24);

  // Padding
  static const EdgeInsets screenPadding = EdgeInsets.symmetric(horizontal: 20);

  static const EdgeInsets cardPadding = EdgeInsets.all(20);

  static const EdgeInsets sectionPadding = EdgeInsets.symmetric(vertical: 16);
}
