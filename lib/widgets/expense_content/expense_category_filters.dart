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

  Color _categoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'food':
        return Colors.orange;
      case 'transport':
        return Colors.blue;
      case 'shopping':
        return Colors.purple;
      case 'bills':
        return Colors.red;
      case 'health':
        return Colors.green;
      case 'education':
        return Colors.indigo;
      case 'entertainment':
        return Colors.pink;
      case 'other':
        return Colors.blueGrey;
      case 'all':
      default:
        return Colors.teal;
    }
  }

  IconData _categoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'food':
        return Icons.restaurant_rounded;
      case 'transport':
        return Icons.directions_car_rounded;
      case 'shopping':
        return Icons.shopping_bag_rounded;
      case 'bills':
        return Icons.receipt_long_rounded;
      case 'health':
        return Icons.favorite_rounded;
      case 'education':
        return Icons.school_rounded;
      case 'entertainment':
        return Icons.movie_rounded;
      case 'other':
        return Icons.account_balance_wallet_rounded;
      case 'all':
      default:
        return Icons.apps_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final compact = ResponsiveHelper.useCompactLayout(context);

    final horizontalPadding = ResponsiveHelper.horizontalPadding(context);

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final chipHeight = compact ? 43.0 : 47.0;

    return Padding(
      padding: EdgeInsets.only(
        left: horizontalPadding,
        right: horizontalPadding,
        top: compact ? 9 : 12,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.category_outlined,
                size: compact ? 14 : 15,
                color: colorScheme.primary,
              ),
              const SizedBox(width: 6),
              Text(
                'CATEGORY',
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
              itemCount: categories.length,
              separatorBuilder: (_, __) => SizedBox(width: compact ? 7 : 8),
              itemBuilder: (context, index) {
                final category = categories[index];

                final selected = category == selectedCategory;

                final color = _categoryColor(category);

                return AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(23),
                    boxShadow: selected
                        ? [
                            BoxShadow(
                              color: color.withOpacity(0.16),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ]
                        : null,
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(23),
                      onTap: () {
                        onCategorySelected(category);
                      },
                      child: Container(
                        height: chipHeight,
                        padding: EdgeInsets.symmetric(
                          horizontal: compact ? 9 : 11,
                        ),
                        decoration: BoxDecoration(
                          color: selected ? color : color.withOpacity(0.06),
                          borderRadius: BorderRadius.circular(23),
                          border: Border.all(
                            color: selected ? color : color.withOpacity(0.13),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: compact ? 27 : 29,
                              height: compact ? 27 : 29,
                              decoration: BoxDecoration(
                                color: selected
                                    ? Colors.white.withOpacity(0.16)
                                    : color.withOpacity(0.10),
                                borderRadius: BorderRadius.circular(9),
                              ),
                              child: Icon(
                                _categoryIcon(category),
                                size: compact ? 14 : 15,
                                color: selected ? Colors.white : color,
                              ),
                            ),

                            const SizedBox(width: 7),

                            Text(
                              category,
                              style: TextStyle(
                                fontSize: compact ? 11 : 12,
                                fontWeight: FontWeight.w700,
                                color: selected
                                    ? Colors.white
                                    : colorScheme.onSurface.withOpacity(0.74),
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
