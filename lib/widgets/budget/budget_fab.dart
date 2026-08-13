import 'package:flutter/material.dart';

import '../../utils/responsive_helper.dart';

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
    final compact = ResponsiveHelper.useCompactLayout(context);

    final landscape = ResponsiveHelper.isLandscape(context);

    final desktop = ResponsiveHelper.isDesktop(context);

    final primary = Theme.of(context).colorScheme.primary;

    final icon = hasBudget ? Icons.edit_rounded : Icons.add_rounded;

    final label = hasBudget ? "Edit Budget" : "Create Budget";

    // Compact mobile landscape:
    // Use a circular FAB to save valuable horizontal space.
    if (landscape && !desktop) {
      return FloatingActionButton(
        heroTag: "budgetFab",
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 4,
        tooltip: label,
        onPressed: onPressed,
        child: Icon(icon, size: compact ? 22 : 24),
      );
    }

    // Phones/tablets/desktop in portrait or larger layouts.
    return FloatingActionButton.extended(
      heroTag: "budgetFab",
      backgroundColor: primary,
      foregroundColor: Colors.white,
      elevation: 4,
      onPressed: onPressed,
      icon: Icon(icon, size: desktop ? 22 : 20),
      label: Text(
        label,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: desktop ? 14 : 13,
        ),
      ),
    );
  }
}
