import 'package:flutter/material.dart';

import '../offline_banner.dart';
import '../sync_status_icon.dart';

class BudgetAppBar extends StatelessWidget implements PreferredSizeWidget {
  const BudgetAppBar({super.key});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: const Text(""),
      actions: const [
        Padding(padding: EdgeInsets.only(right: 12), child: SyncStatusIcon()),
      ],
      bottom: const PreferredSize(
        preferredSize: Size.fromHeight(40),
        child: OfflineBanner(),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 40);
}
