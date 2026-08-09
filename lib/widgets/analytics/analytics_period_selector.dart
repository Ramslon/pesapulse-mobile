import 'package:flutter/material.dart';
import '../../models/analytics_period.dart';

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

    return Card(
      elevation: 1,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        child: Row(
          children: [
            // Calendar icon
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: colorScheme.primary.withOpacity(0.10),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.calendar_month_outlined,
                size: 21,
                color: colorScheme.primary,
              ),
            ),

            const SizedBox(width: 12),

            // Label
            Text(
              'Period',
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),

            const SizedBox(width: 10),

            // Dropdown
            Expanded(
              child: Container(
                height: 42,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest.withOpacity(0.55),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: colorScheme.outline.withOpacity(0.12),
                  ),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<AnalyticsPeriod>(
                    value: selectedPeriod,
                    isExpanded: true,
                    borderRadius: BorderRadius.circular(14),
                    icon: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      size: 21,
                      color: isDisabled
                          ? theme.disabledColor
                          : colorScheme.onSurface,
                    ),

                    style: theme.textTheme.bodyMedium?.copyWith(
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
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }).toList(),

                    onChanged: isDisabled ? null : onChanged,
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
