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

    final radius = desktop
        ? 18.0
        : compact
        ? 14.0
        : 16.0;

    final horizontalPadding = desktop
        ? 14.0
        : tablet
        ? 12.0
        : compact
        ? 9.0
        : 11.0;

    final verticalPadding = desktop
        ? 9.0
        : compact
        ? 6.0
        : landscape
        ? 7.0
        : 8.0;

    final iconBoxSize = desktop
        ? 40.0
        : tablet
        ? 38.0
        : compact
        ? 32.0
        : 36.0;

    final iconSize = desktop
        ? 21.0
        : tablet
        ? 20.0
        : compact
        ? 17.0
        : 19.0;

    final labelSize = desktop
        ? 10.5
        : compact
        ? 8.5
        : 9.5;

    final selectedSize = desktop
        ? 14.0
        : tablet
        ? 13.5
        : compact
        ? 11.5
        : 12.5;

    final dropdownHeight = desktop
        ? 42.0
        : tablet
        ? 40.0
        : compact
        ? 34.0
        : 38.0;

    final dropdownRadius = compact ? 10.0 : 12.0;

    final disabledOpacity = isDisabled ? 0.50 : 1.0;

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 180),
      opacity: disabledOpacity,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(
          horizontal: horizontalPadding,
          vertical: verticalPadding,
        ),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(color: colorScheme.outline.withOpacity(0.08)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(
                theme.brightness == Brightness.dark ? 0.06 : 0.025,
              ),
              blurRadius: desktop ? 16 : 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            _buildCalendarIcon(context, size: iconBoxSize, iconSize: iconSize),

            SizedBox(width: compact ? 9 : 11),

            Expanded(
              child: _buildPeriodSelector(
                context,
                selectedPeriod: selectedPeriod,
                selectedSize: selectedSize,
                labelSize: labelSize,
                height: dropdownHeight,
                radius: dropdownRadius,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCalendarIcon(
    BuildContext context, {
    required double size,
    required double iconSize,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: colorScheme.primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(size <= 32 ? 10 : 12),
        border: Border.all(color: colorScheme.primary.withOpacity(0.09)),
      ),
      child: Icon(
        Icons.calendar_month_rounded,
        size: iconSize,
        color: colorScheme.primary,
      ),
    );
  }

  Widget _buildPeriodSelector(
    BuildContext context, {
    required AnalyticsPeriod selectedPeriod,
    required double selectedSize,
    required double labelSize,
    required double height,
    required double radius,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      children: [
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'ANALYTICS PERIOD',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: colorScheme.onSurfaceVariant.withOpacity(0.65),
                  fontSize: labelSize,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.7,
                ),
              ),

              const SizedBox(height: 2),

              Text(
                _periodLabel(selectedPeriod),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: colorScheme.onSurface,
                  fontSize: selectedSize,
                  fontWeight: FontWeight.w800,
                  height: 1.1,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(width: 10),

        SizedBox(
          height: height,
          child: _buildDropdown(context, height: height, radius: radius),
        ),
      ],
    );
  }

  Widget _buildDropdown(
    BuildContext context, {
    required double height,
    required double radius,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      height: height,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withOpacity(0.55),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: colorScheme.outline.withOpacity(0.09)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<AnalyticsPeriod>(
          value: selectedPeriod,
          isDense: true,
          borderRadius: BorderRadius.circular(14),
          icon: Icon(
            Icons.keyboard_arrow_down_rounded,
            size: 20,
            color: isDisabled ? theme.disabledColor : colorScheme.onSurface,
          ),
          padding: EdgeInsets.zero,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: isDisabled ? theme.disabledColor : colorScheme.onSurface,
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
    );
  }
}
