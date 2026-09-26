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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final compact = ResponsiveHelper.useCompactLayout(context);

    final landscape = ResponsiveHelper.isLandscape(context);

    final desktop = ResponsiveHelper.isDesktop(context);

    final primary = colorScheme.primary;

    final icon = hasBudget ? Icons.edit_rounded : Icons.add_rounded;

    final label = hasBudget ? 'Edit Budget' : 'Create Budget';

    // Landscape on phones/tablets gets a circular
    // action to preserve horizontal space.
    if (landscape && !desktop) {
      return FloatingActionButton(
        heroTag: 'budgetFab',
        onPressed: onPressed,
        tooltip: label,
        backgroundColor: primary,
        foregroundColor: colorScheme.onPrimary,
        elevation: 5,
        highlightElevation: 7,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(compact ? 15 : 17),
        ),
        child: Icon(icon, size: compact ? 21 : 23),
      );
    }

    return FloatingActionButton.extended(
      heroTag: 'budgetFab',
      onPressed: onPressed,
      backgroundColor: primary,
      foregroundColor: colorScheme.onPrimary,
      elevation: 5,
      highlightElevation: 7,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(desktop ? 17 : 15),
      ),
      extendedPadding: EdgeInsets.symmetric(
        horizontal: desktop
            ? 18
            : compact
            ? 13
            : 15,
      ),
      icon: Icon(
        icon,
        size: desktop
            ? 21
            : compact
            ? 18
            : 20,
      ),
      label: Text(
        label,
        style: TextStyle(
          fontWeight: FontWeight.w800,
          fontSize: desktop
              ? 13.5
              : compact
              ? 11.5
              : 12.5,
          letterSpacing: -0.1,
        ),
      ),
    );
  }
}
