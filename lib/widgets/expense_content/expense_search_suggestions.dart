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

  @override
  Widget build(BuildContext context) {
    // Suggestions should not be visible while actively searching.
    if (searchText.isNotEmpty) {
      return const SizedBox.shrink();
    }

    final compact = ResponsiveHelper.useCompactLayout(context);
    final spacing = ResponsiveHelper.spacing(context);
    final horizontalPadding = ResponsiveHelper.horizontalPadding(context);

    final titleFontSize = compact ? 13.0 : 15.0;
    final chipFontSize = compact ? 12.0 : 14.0;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        horizontalPadding,
        compact ? 8 : 10,
        horizontalPadding,
        compact ? 15 : 25,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (recentSearches.isNotEmpty) ...[
            Text(
              "Recent Searches",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: titleFontSize,
              ),
            ),

            SizedBox(height: spacing * 0.7),

            Wrap(
              spacing: compact ? 6 : 8,
              runSpacing: compact ? 6 : 8,
              children: recentSearches.map((search) {
                return ActionChip(
                  label: Text(search, style: TextStyle(fontSize: chipFontSize)),
                  onPressed: () {
                    onSearchSelected(search);
                  },
                );
              }).toList(),
            ),

            SizedBox(height: spacing * 1.3),
          ],

          Text(
            "Suggestions",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: titleFontSize,
            ),
          ),

          SizedBox(height: spacing * 0.7),

          Wrap(
            spacing: compact ? 6 : 8,
            runSpacing: compact ? 6 : 8,
            children: defaultSuggestions.map((category) {
              return FilterChip(
                label: Text(category, style: TextStyle(fontSize: chipFontSize)),
                selected: false,
                onSelected: (_) {
                  onSearchSelected(category);
                },
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
