import 'package:flutter/material.dart';

import '../offline_banner.dart';
import '../sync_status_icon.dart';
import '../../utils/responsive_helper.dart';

class BudgetAppBar extends StatelessWidget implements PreferredSizeWidget {
  const BudgetAppBar({super.key});

  @override
  Widget build(BuildContext context) {
    final compact = ResponsiveHelper.useCompactLayout(context);

    final landscape = ResponsiveHelper.isLandscape(context);

    final toolbarHeight = landscape
        ? compact
              ? 36.0
              : 40.0
        : kToolbarHeight;

    final bannerHeight = landscape
        ? 18.0
        : compact
        ? 34.0
        : 36.0;

    return AppBar(
      toolbarHeight: toolbarHeight,

      title: landscape ? null : const Text(""),

      actions: [
        Padding(
          padding: EdgeInsets.only(right: compact ? 8 : 12),
          child: const SyncStatusIcon(),
        ),
      ],

      bottom: PreferredSize(
        preferredSize: Size.fromHeight(bannerHeight),
        child: const OfflineBanner(),
      ),
    );
  }

  @override
  Size get preferredSize {
    return const Size.fromHeight(kToolbarHeight + 36);
  }
}
