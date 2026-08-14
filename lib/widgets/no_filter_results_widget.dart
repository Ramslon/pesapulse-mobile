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
    final cardPadding = ResponsiveHelper.cardPadding(context);
    final spacing = ResponsiveHelper.spacing(context);

    final contentMaxWidth = desktop
        ? 520.0
        : tablet
        ? 460.0
        : double.infinity;

    final iconSize = desktop
        ? 86.0
        : tablet
        ? 76.0
        : landscape
        ? 62.0
        : compact
        ? 68.0
        : 80.0;

    final titleSize = desktop
        ? 24.0
        : tablet
        ? 22.0
        : compact
        ? 19.0
        : 22.0;

    final descriptionSize = desktop
        ? 16.0
        : tablet
        ? 15.0
        : compact
        ? 13.0
        : 15.0;

    final verticalPadding = landscape
        ? 16.0
        : desktop
        ? 30.0
        : tablet
        ? 26.0
        : compact
        ? 20.0
        : 30.0;

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: contentMaxWidth),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: horizontalPadding + cardPadding,
            vertical: verticalPadding,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.search_off_rounded,
                size: iconSize,
                color: colorScheme.onSurface.withOpacity(.35),
              ),

              SizedBox(
                height: landscape
                    ? spacing
                    : compact
                    ? 14
                    : 20,
              ),

              Text(
                'No matching expenses',
                textAlign: TextAlign.center,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontSize: titleSize,
                  fontWeight: FontWeight.bold,
                ),
              ),

              SizedBox(height: compact ? 7 : 10),

              Text(
                'Try changing your search or filters.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurface.withOpacity(.60),
                  fontSize: descriptionSize,
                  height: 1.4,
                ),
              ),

              if (onClearFilters != null) ...[
                SizedBox(
                  height: landscape
                      ? spacing
                      : compact
                      ? 18
                      : 24,
                ),

                SizedBox(
                  height: compact
                      ? 42
                      : desktop
                      ? 48
                      : 46,
                  child: OutlinedButton.icon(
                    onPressed: onClearFilters,
                    icon: Icon(Icons.refresh_rounded, size: compact ? 18 : 20),
                    label: Text(
                      'Clear Filters',
                      style: TextStyle(
                        fontSize: compact ? 12 : 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.symmetric(
                        horizontal: compact ? 14 : 18,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(compact ? 11 : 13),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
