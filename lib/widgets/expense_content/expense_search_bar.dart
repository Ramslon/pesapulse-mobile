import 'package:flutter/material.dart';

import '../../utils/responsive_helper.dart';

class ExpenseSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;
  final VoidCallback onSort;

  const ExpenseSearchBar({
    super.key,
    required this.controller,
    required this.onChanged,
    required this.onClear,
    required this.onSort,
  });

  @override
  Widget build(BuildContext context) {
    final compact = ResponsiveHelper.useCompactLayout(context);
    final horizontalPadding = ResponsiveHelper.horizontalPadding(context);
    final spacing = ResponsiveHelper.spacing(context);

    final borderRadius = compact ? 14.0 : 16.0;
    final iconSize = compact ? 20.0 : 24.0;

    final surfaceColor = Theme.of(context).colorScheme.surfaceContainerHighest;

    final primaryColor = Theme.of(context).colorScheme.primary;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: horizontalPadding,
        vertical: compact ? 6 : 8,
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              textInputAction: TextInputAction.search,
              onChanged: onChanged,
              decoration: InputDecoration(
                hintText: "Search expenses...",

                prefixIcon: Icon(Icons.search, size: iconSize),

                suffixIcon: controller.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.close, size: iconSize),
                        onPressed: onClear,
                      )
                    : null,

                filled: true,
                fillColor: surfaceColor,

                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(borderRadius),
                  borderSide: BorderSide.none,
                ),

                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(borderRadius),
                  borderSide: BorderSide.none,
                ),

                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(borderRadius),
                  borderSide: BorderSide(color: primaryColor),
                ),
              ),
            ),
          ),

          SizedBox(width: spacing * 0.5),

          Container(
            decoration: BoxDecoration(
              color: surfaceColor,
              borderRadius: BorderRadius.circular(borderRadius),
            ),
            child: IconButton(
              onPressed: onSort,
              icon: Icon(Icons.tune, size: iconSize),
            ),
          ),
        ],
      ),
    );
  }
}
