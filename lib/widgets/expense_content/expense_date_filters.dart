import 'package:flutter/material.dart';

import '../../utils/responsive_helper.dart';

class ExpenseDateFilters extends StatelessWidget {
  final String selectedDateFilter;
  final ValueChanged<String> onFilterSelected;

  const ExpenseDateFilters({
    super.key,
    required this.selectedDateFilter,
    required this.onFilterSelected,
  });

  static const List<String> filters = [
    'All',
    'Today',
    'This Week',
    'This Month',
  ];

  IconData _filterIcon(String filter) {
    switch (filter) {
      case 'Today':
        return Icons.today_rounded;
      case 'This Week':
        return Icons.date_range_rounded;
      case 'This Month':
        return Icons.calendar_month_rounded;
      case 'All':
      default:
        return Icons.calendar_view_day_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final compact = ResponsiveHelper.useCompactLayout(context);

    final horizontalPadding = ResponsiveHelper.horizontalPadding(context);

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final chipHeight = compact ? 40.0 : 44.0;

    return Padding(
      padding: EdgeInsets.only(
        left: horizontalPadding,
        right: horizontalPadding,
        top: compact ? 10 : 13,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.schedule_rounded,
                size: compact ? 14 : 15,
                color: colorScheme.primary,
              ),
              const SizedBox(width: 6),
              Text(
                'DATE RANGE',
                style: TextStyle(
                  fontSize: compact ? 10 : 10.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.85,
                  color: colorScheme.onSurface.withOpacity(0.55),
                ),
              ),
            ],
          ),

          SizedBox(height: compact ? 8 : 9),

          SizedBox(
            height: chipHeight,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: filters.length,
              separatorBuilder: (_, __) => SizedBox(width: compact ? 7 : 8),
              itemBuilder: (context, index) {
                final filter = filters[index];
                final selected = filter == selectedDateFilter;

                return AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: selected
                        ? [
                            BoxShadow(
                              color: colorScheme.primary.withOpacity(0.16),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ]
                        : null,
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(22),
                      onTap: () {
                        onFilterSelected(filter);
                      },
                      child: Container(
                        height: chipHeight,
                        padding: EdgeInsets.symmetric(
                          horizontal: compact ? 10 : 12,
                        ),
                        decoration: BoxDecoration(
                          color: selected
                              ? colorScheme.primary
                              : colorScheme.surface,
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(
                            color: selected
                                ? colorScheme.primary
                                : colorScheme.outline.withOpacity(0.09),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _filterIcon(filter),
                              size: compact ? 14 : 15,
                              color: selected
                                  ? colorScheme.onPrimary
                                  : colorScheme.primary,
                            ),

                            const SizedBox(width: 6),

                            Text(
                              filter,
                              style: TextStyle(
                                fontSize: compact ? 11 : 12,
                                fontWeight: FontWeight.w700,
                                color: selected
                                    ? colorScheme.onPrimary
                                    : colorScheme.onSurface.withOpacity(0.72),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
