import 'package:flutter/material.dart';
import 'budget_screen.dart';
import '../widgets/app/adaptive_app_bar.dart';
import '../widgets/app/app_scaffold.dart';

class BudgetPage extends StatelessWidget {
  const BudgetPage({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: const AdaptiveAppBar(title: null),
      body: const BudgetScreen(),
    );
  }
}
