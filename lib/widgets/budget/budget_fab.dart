import 'package:flutter/material.dart';

class BudgetFAB extends StatelessWidget {
  final bool hasBudget;
  final VoidCallback onPressed;

  const BudgetFAB({
    super.key,
    required this.hasBudget,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;

    if (isLandscape) {
      return FloatingActionButton(
        heroTag: "budgetFab",
        backgroundColor: Theme.of(context).colorScheme.primary,
        onPressed: onPressed,
        child: Icon(hasBudget ? Icons.edit_rounded : Icons.add_rounded),
      );
    }

    return FloatingActionButton.extended(
      heroTag: "budgetFab",
      backgroundColor: Theme.of(context).colorScheme.primary,
      onPressed: onPressed,
      icon: Icon(hasBudget ? Icons.edit_rounded : Icons.add_rounded),
      label: Text(hasBudget ? "Edit Budget" : "Create Budget"),
    );
  }
}
