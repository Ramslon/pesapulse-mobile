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

  @override
  Widget build(BuildContext context) {
    final compact = ResponsiveHelper.useCompactLayout(context);
    final horizontalPadding = ResponsiveHelper.horizontalPadding(context);

    final chipHeight = compact ? 36.0 : 40.0;
    final chipFontSize = compact ? 11.0 : 13.0;

    return Padding(
      padding: EdgeInsets.only(left: horizontalPadding, top: compact ? 10 : 15),
      child: SizedBox(
        height: chipHeight,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: filters.length,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (context, index) {
            final filter = filters[index];
            final selected = selectedDateFilter == filter;

            return ChoiceChip(
              label: Text(filter, style: TextStyle(fontSize: chipFontSize)),
              selected: selected,
              selectedColor: Theme.of(context).colorScheme.primary,
              labelStyle: TextStyle(
                color: selected ? Colors.white : null,
                fontWeight: FontWeight.w600,
              ),
              showCheckmark: false,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              onSelected: (_) {
                onFilterSelected(filter);
              },
            );
          },
        ),
      ),
    );
  }
}
