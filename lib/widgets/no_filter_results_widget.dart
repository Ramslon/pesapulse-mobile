import 'package:flutter/material.dart';

import '../../utils/responsive_helper.dart';

class NoFilterResultsWidget extends StatelessWidget {
  final VoidCallback? onClearFilters;

  const NoFilterResultsWidget({super.key, this.onClearFilters});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final compact = ResponsiveHelper.useCompactLayout(context);

    final landscape = ResponsiveHelper.isLandscape(context);

    final tablet = ResponsiveHelper.isTablet(context);

    final desktop = ResponsiveHelper.isDesktop(context);

    final horizontalPadding = ResponsiveHelper.horizontalPadding(context);

    final spacing = ResponsiveHelper.spacing(context);

    final contentMaxWidth = desktop
        ? 520.0
        : tablet
        ? 470.0
        : 420.0;

    final iconContainerSize = desktop
        ? 90.0
        : tablet
        ? 82.0
        : landscape
        ? 68.0
        : compact
        ? 72.0
        : 80.0;

    final iconSize = compact
        ? 28.0
        : landscape
        ? 28.0
        : 32.0;

    final titleSize = desktop
        ? 24.0
        : tablet
        ? 22.0
        : compact
        ? 19.0
        : 22.0;

    final descriptionSize = desktop
        ? 15.0
        : tablet
        ? 14.5
        : compact
        ? 12.5
        : 14.0;

    final verticalPadding = landscape
        ? 18.0
        : desktop
        ? 30.0
        : tablet
        ? 27.0
        : compact
        ? 22.0
        : 28.0;

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: contentMaxWidth),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: horizontalPadding + (compact ? 4 : 8),
            vertical: verticalPadding,
          ),
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.all(compact ? 17 : 22),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(compact ? 18 : 21),
              border: Border.all(color: colorScheme.outline.withOpacity(0.07)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.025),
                  blurRadius: 14,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Search status icon
                Container(
                  width: iconContainerSize,
                  height: iconContainerSize,
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(compact ? 19 : 22),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Icon(
                        Icons.receipt_long_rounded,
                        size: iconSize + 5,
                        color: colorScheme.primary.withOpacity(0.18),
                      ),
                      Icon(
                        Icons.search_off_rounded,
                        size: iconSize,
                        color: colorScheme.primary,
                      ),
                    ],
                  ),
                ),

                SizedBox(
                  height: landscape
                      ? spacing
                      : compact
                      ? 14
                      : 18,
                ),

                Text(
                  'No matching expenses',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontSize: titleSize,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.2,
                    color: colorScheme.onSurface,
                  ),
                ),

                const SizedBox(height: 7),

                Text(
                  'No transactions match your current search or filters.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurface.withOpacity(0.55),
                    fontSize: descriptionSize,
                    height: 1.45,
                    fontWeight: FontWeight.w500,
                  ),
                ),

                if (onClearFilters != null) ...[
                  SizedBox(
                    height: landscape
                        ? spacing
                        : compact
                        ? 17
                        : 22,
                  ),

                  SizedBox(
                    height: compact
                        ? 44
                        : desktop
                        ? 48
                        : 46,
                    child: FilledButton.icon(
                      onPressed: onClearFilters,
                      icon: Icon(
                        Icons.filter_alt_off_rounded,
                        size: compact ? 17 : 19,
                      ),
                      label: Text(
                        'Clear Filters',
                        style: TextStyle(
                          fontSize: compact ? 12 : 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      style: FilledButton.styleFrom(
                        padding: EdgeInsets.symmetric(
                          horizontal: compact ? 15 : 18,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            compact ? 12 : 14,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
