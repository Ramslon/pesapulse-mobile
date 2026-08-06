import 'package:flutter/material.dart';

import '../offline_banner.dart';
import '../sync_status_icon.dart';

class BudgetAppBar extends StatelessWidget implements PreferredSizeWidget {
  const BudgetAppBar({super.key});

  @override
  Widget build(BuildContext context) {
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;

    return AppBar(
      toolbarHeight: isLandscape ? 36 : kToolbarHeight,

      title: isLandscape ? null : const Text(""),

      actions: const [
        Padding(padding: EdgeInsets.only(right: 12), child: SyncStatusIcon()),
      ],

      bottom: PreferredSize(
        preferredSize: Size.fromHeight(isLandscape ? 18 : 36),
        child: const OfflineBanner(),
      ),
    );
  }

  @override
  Size get preferredSize {
    final view = WidgetsBinding.instance.platformDispatcher.views.first;

    final isLandscape = view.physicalSize.width > view.physicalSize.height;

    return Size.fromHeight(
      (isLandscape ? 46 : kToolbarHeight) + (isLandscape ? 18 : 40),
    );
  }
}
