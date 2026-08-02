import 'package:flutter/material.dart';
import 'budget_screen.dart';
import '../widgets/offline_banner.dart';
import '../widgets/sync_status_icon.dart';

class BudgetPage extends StatelessWidget {
  const BudgetPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(""),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 12),
            child: SyncStatusIcon(), //  quick glance sync state
          ),
        ],
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(40),
          child: OfflineBanner(), //  pinned under AppBar
        ),
      ),
      body: const BudgetScreen(),
    );
  }
}
