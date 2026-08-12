import 'package:flutter/material.dart';

import '../../utils/responsive_helper.dart';

class ExpenseFilterHeader extends StatelessWidget {
  final bool filtersExpanded;
  final VoidCallback onTap;

  const ExpenseFilterHeader({
    super.key,
    required this.filtersExpanded,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final compact = ResponsiveHelper.useCompactLayout(context);
    final horizontalPadding = ResponsiveHelper.horizontalPadding(context);

    final borderRadius = compact ? 12.0 : 14.0;
    final horizontalSpacing = compact ? 8.0 : 10.0;
    final iconSize = compact ? 20.0 : 24.0;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
      child: InkWell(
        borderRadius: BorderRadius.circular(borderRadius),
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 12 : 16,
            vertical: compact ? 11 : 14,
          ),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(borderRadius),
          ),
          child: Row(
            children: [
              Icon(Icons.filter_list, size: iconSize),

              SizedBox(width: horizontalSpacing),

              Expanded(
                child: Text(
                  "Filters",
                  style: TextStyle(
                    fontSize: compact ? 14 : 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),

              AnimatedRotation(
                turns: filtersExpanded ? 0.5 : 0,
                duration: const Duration(milliseconds: 250),
                child: Icon(Icons.keyboard_arrow_down, size: iconSize),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
