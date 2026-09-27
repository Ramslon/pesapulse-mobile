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

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final radius = compact ? 16.0 : 18.0;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: horizontalPadding,
        vertical: compact ? 4 : 5,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(radius),
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            padding: EdgeInsets.symmetric(
              horizontal: compact ? 12 : 15,
              vertical: compact ? 11 : 13,
            ),
            decoration: BoxDecoration(
              color: filtersExpanded
                  ? colorScheme.primary.withOpacity(0.07)
                  : colorScheme.surface,
              borderRadius: BorderRadius.circular(radius),
              border: Border.all(
                color: filtersExpanded
                    ? colorScheme.primary.withOpacity(0.18)
                    : colorScheme.outline.withOpacity(0.08),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(
                    filtersExpanded ? 0.035 : 0.02,
                  ),
                  blurRadius: filtersExpanded ? 12 : 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: compact ? 36 : 40,
                  height: compact ? 36 : 40,
                  decoration: BoxDecoration(
                    color: filtersExpanded
                        ? colorScheme.primary
                        : colorScheme.primary.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(compact ? 11 : 12),
                  ),
                  child: Icon(
                    Icons.tune_rounded,
                    size: compact ? 18 : 20,
                    color: filtersExpanded
                        ? colorScheme.onPrimary
                        : colorScheme.primary,
                  ),
                ),

                SizedBox(width: compact ? 10 : 12),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'FILTERS',
                        style: TextStyle(
                          fontSize: compact ? 9.5 : 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.95,
                          color: filtersExpanded
                              ? colorScheme.primary
                              : colorScheme.onSurface.withOpacity(0.48),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        filtersExpanded
                            ? 'Refine your transactions'
                            : 'Filter by date or category',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: compact ? 12.5 : 13.5,
                          fontWeight: FontWeight.w700,
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),

                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: EdgeInsets.symmetric(
                    horizontal: compact ? 7 : 8,
                    vertical: compact ? 4 : 5,
                  ),
                  decoration: BoxDecoration(
                    color: filtersExpanded
                        ? colorScheme.primary.withOpacity(0.10)
                        : colorScheme.surfaceContainerHighest.withOpacity(0.70),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    filtersExpanded ? 'OPEN' : 'HIDDEN',
                    style: TextStyle(
                      fontSize: compact ? 9 : 9.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.4,
                      color: filtersExpanded
                          ? colorScheme.primary
                          : colorScheme.onSurface.withOpacity(0.48),
                    ),
                  ),
                ),

                const SizedBox(width: 7),

                AnimatedRotation(
                  turns: filtersExpanded ? 0.5 : 0,
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOut,
                  child: Icon(
                    Icons.keyboard_arrow_down_rounded,
                    size: compact ? 20 : 22,
                    color: colorScheme.onSurface.withOpacity(0.50),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
