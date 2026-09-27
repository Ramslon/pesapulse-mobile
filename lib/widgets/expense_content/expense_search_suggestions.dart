import 'package:flutter/material.dart';

import '../../utils/responsive_helper.dart';

class ExpenseSearchSuggestions extends StatelessWidget {
  final String searchText;
  final List<String> recentSearches;
  final List<String> defaultSuggestions;

  final ValueChanged<String> onSearchSelected;

  const ExpenseSearchSuggestions({
    super.key,
    required this.searchText,
    required this.recentSearches,
    required this.defaultSuggestions,
    required this.onSearchSelected,
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
      default:
        return Icons.search_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Do not show suggestions while the user
    // is actively searching.
    if (searchText.trim().isNotEmpty) {
      return const SizedBox.shrink();
    }

    final compact = ResponsiveHelper.useCompactLayout(context);

    final landscape = ResponsiveHelper.isLandscape(context);

    final horizontalPadding = ResponsiveHelper.horizontalPadding(context);

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final sectionTitleSize = compact
        ? 10.5
        : landscape
        ? 11
        : 11.5;

    final sectionSpacing = compact
        ? 7.0
        : landscape
        ? 8.0
        : 9.0;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        horizontalPadding,
        compact ? 7 : 9,
        horizontalPadding,
        compact ? 14 : 19,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (recentSearches.isNotEmpty) ...[
            _buildSectionHeader(
              context,
              title: 'RECENT SEARCHES',
              icon: Icons.history_rounded,
              titleSize: sectionTitleSize.toDouble(),
            ),

            SizedBox(height: sectionSpacing),

            _buildRecentSearches(context, compact, colorScheme),

            SizedBox(height: compact ? 14 : 18),
          ],

          _buildSectionHeader(
            context,
            title: 'EXPLORE CATEGORIES',
            icon: Icons.category_outlined,
            titleSize: sectionTitleSize.toDouble(),
          ),

          SizedBox(height: sectionSpacing),

          Wrap(
            spacing: compact ? 7 : 8,
            runSpacing: compact ? 7 : 8,
            children: defaultSuggestions.map((category) {
              return _buildCategoryChip(context, category, compact);
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(
    BuildContext context, {
    required String title,
    required IconData icon,
    required double titleSize,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        Icon(icon, size: 15, color: colorScheme.primary),

        const SizedBox(width: 7),

        Text(
          title,
          style: TextStyle(
            fontSize: titleSize,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.85,
            color: colorScheme.onSurface.withOpacity(0.58),
          ),
        ),

        const SizedBox(width: 8),

        Expanded(
          child: Container(
            height: 1,
            color: colorScheme.outline.withOpacity(0.07),
          ),
        ),
      ],
    );
  }

  Widget _buildRecentSearches(
    BuildContext context,
    bool compact,
    ColorScheme colorScheme,
  ) {
    return Wrap(
      spacing: compact ? 7 : 8,
      runSpacing: compact ? 7 : 8,
      children: recentSearches.map((search) {
        return Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () {
              onSearchSelected(search);
            },
            child: Container(
              constraints: const BoxConstraints(maxWidth: 220),
              padding: EdgeInsets.symmetric(
                horizontal: compact ? 9 : 11,
                vertical: compact ? 7 : 8,
              ),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: colorScheme.outline.withOpacity(0.09),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.history_rounded,
                    size: compact ? 14 : 15,
                    color: colorScheme.onSurface.withOpacity(0.45),
                  ),

                  const SizedBox(width: 6),

                  Flexible(
                    child: Text(
                      search,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: compact ? 11.5 : 12,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface.withOpacity(0.70),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildCategoryChip(
    BuildContext context,
    String category,
    bool compact,
  ) {
    final color = _categoryColor(category);

    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {
          onSearchSelected(category);
        },
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 9 : 11,
            vertical: compact ? 7 : 8,
          ),
          decoration: BoxDecoration(
            color: color.withOpacity(0.07),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withOpacity(0.13)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: compact ? 25 : 27,
                height: compact ? 25 : 27,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _categoryIcon(category),
                  size: compact ? 13 : 14,
                  color: color,
                ),
              ),

              const SizedBox(width: 7),

              Text(
                category,
                style: TextStyle(
                  fontSize: compact ? 11.5 : 12.5,
                  fontWeight: FontWeight.w700,
                  color: colorScheme.onSurface.withOpacity(0.74),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
