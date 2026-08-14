import 'package:flutter/material.dart';

import '../../models/analytics_period.dart';
import '../../utils/responsive_helper.dart';

class AnalyticsPeriodSelector extends StatelessWidget {
  final AnalyticsPeriod selectedPeriod;
  final bool isDisabled;
  final ValueChanged<AnalyticsPeriod?> onChanged;

  const AnalyticsPeriodSelector({
    super.key,
    required this.selectedPeriod,
    required this.isDisabled,
    required this.onChanged,
  });

  String _periodLabel(AnalyticsPeriod period) {
    switch (period) {
      case AnalyticsPeriod.thisMonth:
        return 'This Month';

      case AnalyticsPeriod.lastMonth:
        return 'Last Month';

      case AnalyticsPeriod.last3Months:
        return 'Last 3 Months';

      case AnalyticsPeriod.last6Months:
        return 'Last 6 Months';

      case AnalyticsPeriod.thisYear:
        return 'This Year';

      case AnalyticsPeriod.allTime:
        return 'All Time';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final compact = ResponsiveHelper.useCompactLayout(context);
    final landscape = ResponsiveHelper.isLandscape(context);
    final tablet = ResponsiveHelper.isTablet(context);
    final desktop = ResponsiveHelper.isDesktop(context);

    final horizontalPadding = desktop
        ? 18.0
        : tablet
        ? 16.0
        : compact
        ? 10.0
        : 14.0;

    final verticalPadding = compact
        ? 6.0
        : landscape
        ? 6.0
        : 8.0;

    final iconBoxSize = desktop
        ? 44.0
        : tablet
        ? 42.0
        : compact
        ? 32.0
        : 40.0;

    final iconSize = desktop
        ? 23.0
        : tablet
        ? 22.0
        : compact
        ? 17.0
        : 21.0;

    final labelSize = desktop
        ? 14.0
        : tablet
        ? 13.5
        : compact
        ? 11.0
        : 13.0;

    final dropdownHeight = desktop
        ? 46.0
        : tablet
        ? 44.0
        : compact
        ? 38.0
        : 42.0;

    final dropdownHorizontalPadding = compact
        ? 9.0
        : tablet
        ? 11.0
        : 12.0;

    final dropdownFontSize = desktop
        ? 14.0
        : tablet
        ? 13.5
        : compact
        ? 11.5
        : 13.0;

    final iconLabelSpacing = compact
        ? 8.0
        : landscape
        ? 9.0
        : 12.0;

    final labelDropdownSpacing = compact
        ? 7.0
        : landscape
        ? 8.0
        : 10.0;

    final borderRadius = compact ? 13.0 : 16.0;
    final dropdownRadius = compact ? 10.0 : 12.0;

    return Card(
      elevation: compact ? 0.5 : 1,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: horizontalPadding,
          vertical: verticalPadding,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // ─────────────────────────────────────
            // Calendar icon
            // ─────────────────────────────────────
            Container(
              width: iconBoxSize,
              height: iconBoxSize,
              decoration: BoxDecoration(
                color: colorScheme.primary.withOpacity(0.10),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.calendar_month_outlined,
                size: iconSize,
                color: colorScheme.primary,
              ),
            ),

            SizedBox(width: iconLabelSpacing),

            // ─────────────────────────────────────
            // Period label
            // ─────────────────────────────────────
            Text(
              'Period',
              style: theme.textTheme.labelLarge?.copyWith(
                fontSize: labelSize,
                fontWeight: FontWeight.w700,
              ),
            ),

            SizedBox(width: labelDropdownSpacing),

            // ─────────────────────────────────────
            // Dropdown
            // ─────────────────────────────────────
            Expanded(
              child: SizedBox(
                height: dropdownHeight,
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: dropdownHorizontalPadding,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest.withOpacity(
                      0.55,
                    ),
                    borderRadius: BorderRadius.circular(dropdownRadius),
                    border: Border.all(
                      color: colorScheme.outline.withOpacity(0.12),
                    ),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<AnalyticsPeriod>(
                      value: selectedPeriod,
                      isExpanded: true,
                      isDense: compact,
                      borderRadius: BorderRadius.circular(compact ? 12 : 14),
                      icon: Icon(
                        Icons.keyboard_arrow_down_rounded,
                        size: compact ? 19 : 21,
                        color: isDisabled
                            ? theme.disabledColor
                            : colorScheme.onSurface,
                      ),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontSize: dropdownFontSize,
                        fontWeight: FontWeight.w600,
                        color: isDisabled
                            ? theme.disabledColor
                            : colorScheme.onSurface,
                      ),
                      items: AnalyticsPeriod.values.map((period) {
                        return DropdownMenuItem<AnalyticsPeriod>(
                          value: period,
                          child: Text(
                            _periodLabel(period),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }).toList(),
                      onChanged: isDisabled ? null : onChanged,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
