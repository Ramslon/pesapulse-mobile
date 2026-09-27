import 'package:flutter/material.dart';

import '../../core/utils/currency_formatter.dart';
import '../../utils/responsive_helper.dart';
import '../../widgets/empty_state_helper.dart';
import '../../widgets/no_filter_results_widget.dart';
import '../../widgets/expense_content/expense_date_header.dart';
import '../../widgets/expense_content/expense_item_card.dart';

class ExpenseListSection extends StatelessWidget {
  final List<MapEntry<String, List<Map<String, dynamic>>>> sections;

  final List filteredExpenses;

  final String searchQuery;

  final bool hasActiveFilters;
  final bool isGuest;

  final VoidCallback onClearFilters;

  final String Function(num) currencyFormatter;

  final Future<void> Function() onRefresh;

  final Future<void> Function(Map<String, dynamic> expense) onEdit;
  final Future<void> Function(Map<String, dynamic> expense) onDelete;
  final Future<void> Function(Map<String, dynamic> expense) onDuplicate;

  const ExpenseListSection({
    super.key,
    required this.sections,
    required this.filteredExpenses,
    required this.searchQuery,
    required this.hasActiveFilters,
    required this.isGuest,
    required this.onClearFilters,
    required this.currencyFormatter,
    required this.onRefresh,
    required this.onEdit,
    required this.onDelete,
    required this.onDuplicate,
  });

  @override
  Widget build(BuildContext context) {
    final compact = ResponsiveHelper.useCompactLayout(context);
    final landscape = ResponsiveHelper.isLandscape(context);

    final sectionSpacing = ResponsiveHelper.sectionSpacing(context);

    final spacing = ResponsiveHelper.spacing(context);

    final horizontalInset = compact
        ? 14.0
        : landscape
        ? 20.0
        : 18.0;

    if (filteredExpenses.isEmpty) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: hasActiveFilters
            ? NoFilterResultsWidget(onClearFilters: onClearFilters)
            : buildEmptyState(
                context,
                EmptyStateType.expenses,
                isGuest: isGuest,
              ),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate((context, index) {
        final section = sections[index];

        final transactionCount = section.value.length;

        return Padding(
          padding: EdgeInsets.only(
            left: horizontalInset,
            right: horizontalInset,
            top: index == 0 ? spacing : sectionSpacing * 0.72,
            bottom: compact ? 2 : 4,
          ),
          child: _ExpenseDateSection(
            title: section.key,
            transactionCount: transactionCount,
            compact: compact,
            landscape: landscape,
            children: [
              ExpenseDateHeader(title: section.key),

              SizedBox(height: compact ? 4 : 6),

              ...section.value.map(
                (expense) => ExpenseItemCard(
                  expense: expense,
                  searchQuery: searchQuery,
                  currencyFormatter: CurrencyFormatter.format,
                  onEdit: () => onEdit(expense),
                  onDelete: () => onDelete(expense),
                  onDuplicate: () => onDuplicate(expense),
                ),
              ),
            ],
          ),
        );
      }, childCount: sections.length),
    );
  }
}

class _ExpenseDateSection extends StatelessWidget {
  final String title;
  final int transactionCount;
  final bool compact;
  final bool landscape;
  final List<Widget> children;

  const _ExpenseDateSection({
    required this.title,
    required this.transactionCount,
    required this.compact,
    required this.landscape,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Date heading row
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 4,
              height: compact ? 22 : 25,
              decoration: BoxDecoration(
                color: colorScheme.primary,
                borderRadius: BorderRadius.circular(20),
              ),
            ),

            const SizedBox(width: 9),

            Expanded(child: children.first),

            const SizedBox(width: 8),

            Container(
              padding: EdgeInsets.symmetric(
                horizontal: compact ? 7 : 8,
                vertical: compact ? 4 : 4.5,
              ),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest.withOpacity(0.65),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: colorScheme.outline.withOpacity(0.07),
                ),
              ),
              child: Text(
                _transactionLabel(transactionCount),
                style: TextStyle(
                  fontSize: compact ? 10 : 10.5,
                  fontWeight: FontWeight.w700,
                  color: colorScheme.onSurface.withOpacity(0.55),
                ),
              ),
            ),
          ],
        ),

        SizedBox(height: compact ? 7 : 9),

        // Transactions belonging to this date
        Padding(
          padding: EdgeInsets.only(left: compact ? 1 : 2),
          child: Column(children: children.skip(1).toList()),
        ),
      ],
    );
  }

  String _transactionLabel(int count) {
    if (count == 1) {
      return '1 transaction';
    }

    return '$count transactions';
  }
}
