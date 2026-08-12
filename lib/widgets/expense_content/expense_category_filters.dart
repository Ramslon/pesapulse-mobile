import 'package:flutter/material.dart';

import '../../utils/responsive_helper.dart';

class ExpenseCategoryFilters extends StatelessWidget {
  final List<String> categories;
  final String selectedCategory;
  final ValueChanged<String> onCategorySelected;

  const ExpenseCategoryFilters({
    super.key,
    required this.categories,
    required this.selectedCategory,
    required this.onCategorySelected,
  });

  @override
  Widget build(BuildContext context) {
    final compact = ResponsiveHelper.useCompactLayout(context);
    final horizontalPadding = ResponsiveHelper.horizontalPadding(context);

    final chipHeight = compact ? 42.0 : 45.0;
    final chipFontSize = compact ? 11.0 : 13.0;
    final categoryTitleFontSize = compact ? 13.0 : 14.0;

    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;
    final surfaceColor = theme.colorScheme.surfaceContainerHighest;

    return Padding(
      padding: EdgeInsets.only(left: horizontalPadding, top: compact ? 10 : 15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Category",
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              fontSize: categoryTitleFontSize,
            ),
          ),

          SizedBox(height: compact ? 8 : 10),

          SizedBox(
            height: chipHeight,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: categories.length,
              separatorBuilder: (_, __) => SizedBox(width: compact ? 6 : 8),
              itemBuilder: (context, index) {
                final category = categories[index];
                final selected = category == selectedCategory;

                return ChoiceChip(
                  label: Text(
                    category,
                    style: TextStyle(fontSize: chipFontSize),
                  ),

                  selected: selected,

                  selectedColor: primaryColor,

                  backgroundColor: surfaceColor,

                  labelStyle: TextStyle(
                    color: selected ? Colors.white : null,
                    fontWeight: FontWeight.w600,
                    fontSize: chipFontSize,
                  ),

                  showCheckmark: false,

                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),

                  onSelected: (_) {
                    onCategorySelected(category);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
