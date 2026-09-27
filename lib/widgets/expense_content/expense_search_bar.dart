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

    final landscape = ResponsiveHelper.isLandscape(context);

    final horizontalPadding = ResponsiveHelper.horizontalPadding(context);

    final spacing = ResponsiveHelper.spacing(context);

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final isSearching = controller.text.trim().isNotEmpty;

    final radius = compact ? 15.0 : 17.0;

    final iconSize = compact
        ? 19.0
        : landscape
        ? 20.0
        : 21.0;

    final fieldHeight = compact
        ? 49.0
        : landscape
        ? 50.0
        : 52.0;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: horizontalPadding,
        vertical: compact ? 6 : 8,
      ),
      child: Row(
        children: [
          Expanded(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              height: fieldHeight,
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(radius),
                border: Border.all(
                  color: isSearching
                      ? colorScheme.primary.withOpacity(0.45)
                      : colorScheme.outline.withOpacity(0.09),
                  width: isSearching ? 1.2 : 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(
                      isSearching ? 0.045 : 0.025,
                    ),
                    blurRadius: isSearching ? 12 : 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: TextField(
                controller: controller,
                textInputAction: TextInputAction.search,
                onChanged: onChanged,
                style: TextStyle(
                  fontSize: compact ? 13 : 14,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
                decoration: InputDecoration(
                  hintText: 'Search transactions...',
                  hintStyle: TextStyle(
                    fontSize: compact ? 13 : 14,
                    fontWeight: FontWeight.w500,
                    color: colorScheme.onSurface.withOpacity(0.42),
                  ),

                  prefixIcon: Padding(
                    padding: EdgeInsets.only(
                      left: compact ? 6 : 8,
                      right: compact ? 3 : 4,
                    ),
                    child: Icon(
                      Icons.search_rounded,
                      size: iconSize,
                      color: isSearching
                          ? colorScheme.primary
                          : colorScheme.onSurface.withOpacity(0.48),
                    ),
                  ),

                  prefixIconConstraints: BoxConstraints(
                    minWidth: compact ? 40 : 44,
                    minHeight: fieldHeight,
                  ),

                  suffixIcon: isSearching
                      ? IconButton(
                          tooltip: 'Clear search',
                          splashRadius: 18,
                          onPressed: onClear,
                          icon: Icon(
                            Icons.close_rounded,
                            size: compact ? 18 : 19,
                            color: colorScheme.onSurface.withOpacity(0.48),
                          ),
                        )
                      : null,

                  suffixIconConstraints: BoxConstraints(
                    minWidth: compact ? 40 : 44,
                    minHeight: fieldHeight,
                  ),

                  filled: false,

                  contentPadding: EdgeInsets.symmetric(
                    horizontal: compact ? 4 : 6,
                  ),

                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                ),
              ),
            ),
          ),

          SizedBox(width: spacing * 0.55),

          // Sort / filter action
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(radius),
              onTap: onSort,
              child: Container(
                width: fieldHeight,
                height: fieldHeight,
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: BorderRadius.circular(radius),
                  border: Border.all(
                    color: colorScheme.outline.withOpacity(0.09),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.025),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.tune_rounded,
                  size: compact ? 19 : 21,
                  color: colorScheme.primary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
