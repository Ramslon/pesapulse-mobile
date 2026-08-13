import 'package:flutter/material.dart';

import '../offline_banner.dart';
import '../sync_status_icon.dart';
import '../../utils/responsive_helper.dart';

class AppScaffold extends StatelessWidget {
  final PreferredSizeWidget? appBar;
  final Widget body;
  final Widget? floatingActionButton;
  final Widget? bottomNavigationBar;
  final Color? backgroundColor;
  final bool showSyncIcon;
  final bool showOfflineBanner;
  final FloatingActionButtonLocation? floatingActionButtonLocation;

  const AppScaffold({
    super.key,
    this.appBar,
    required this.body,
    this.floatingActionButton,
    this.bottomNavigationBar,
    this.backgroundColor,
    this.showSyncIcon = true,
    this.showOfflineBanner = true,
    this.floatingActionButtonLocation,
  });

  @override
  Widget build(BuildContext context) {
    final compact = ResponsiveHelper.useCompactLayout(context);

    final tablet = ResponsiveHelper.isTablet(context);

    final desktop = ResponsiveHelper.isDesktop(context);

    final screenWidth = ResponsiveHelper.width(context);

    final topPadding = MediaQuery.paddingOf(context).top;

    // Floating overlay position.
    final overlayTop =
        topPadding +
        (compact
            ? 5.0
            : tablet
            ? 7.0
            : desktop
            ? 8.0
            : 6.0);

    final horizontalPadding = compact
        ? 10.0
        : tablet
        ? 16.0
        : desktop
        ? 24.0
        : 12.0;

    return Stack(
      children: [
        // ────────────────────────────────────────
        // Main scaffold
        // ────────────────────────────────────────
        Scaffold(
          backgroundColor: backgroundColor,
          appBar: appBar,
          body: body,
          floatingActionButton: floatingActionButton,
          floatingActionButtonLocation: floatingActionButtonLocation,
          bottomNavigationBar: bottomNavigationBar,
        ),

        // ────────────────────────────────────────
        // Floating sync status
        // ────────────────────────────────────────
        if (showSyncIcon)
          Positioned(
            top: overlayTop,
            right: horizontalPadding,
            child: const SyncStatusIcon(),
          ),

        // ────────────────────────────────────────
        // Floating offline banner
        // ────────────────────────────────────────
        if (showOfflineBanner)
          Positioned(
            top: overlayTop,
            left: horizontalPadding,
            child: SizedBox(
              width: _offlineBannerWidth(
                screenWidth,
                compact: compact,
                tablet: tablet,
                desktop: desktop,
              ),
              child: const OfflineBanner(),
            ),
          ),
      ],
    );
  }

  double _offlineBannerWidth(
    double screenWidth, {
    required bool compact,
    required bool tablet,
    required bool desktop,
  }) {
    if (desktop) {
      return 420;
    }

    if (tablet) {
      return 360;
    }

    if (compact) {
      return screenWidth * 0.68;
    }

    return screenWidth * 0.75;
  }
}
