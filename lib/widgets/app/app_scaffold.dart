import 'package:flutter/material.dart';

import '../offline_banner.dart';
import '../sync_status_icon.dart';

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
    final topPadding = MediaQuery.of(context).padding.top;

    return Stack(
      children: [
        Scaffold(
          backgroundColor: backgroundColor,
          appBar: appBar,
          body: body,
          floatingActionButton: floatingActionButton,
          floatingActionButtonLocation: floatingActionButtonLocation,
          bottomNavigationBar: bottomNavigationBar,
        ),

        // Floating Sync Icon
        if (showSyncIcon)
          Positioned(
            top: topPadding + 6,
            right: 12,
            child: const SyncStatusIcon(),
          ),

        // Floating Offline Banner
        if (showOfflineBanner)
          Positioned(
            top: topPadding + 2,
            left: 12,
            child: SizedBox(
              width: MediaQuery.of(context).size.width * 0.75,
              child: const OfflineBanner(),
            ),
          ),
      ],
    );
  }
}
