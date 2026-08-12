import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../utils/responsive_helper.dart';
import '../../widgets/empty_state_helper.dart';
import '../../widgets/no_filter_results_widget.dart';
import '../../widgets/expense_content/expense_date_header.dart';
import '../../widgets/expense_content/expense_item_card.dart';

class ExpenseListSection extends StatelessWidget {
  final List<MapEntry<String, List<Map<String, dynamic>>>> sections;

  final List filteredExpenses;

  final String searchQuery;
  final NumberFormat currencyFormatter;

  final bool hasActiveFilters;
  final bool isGuest;

  final VoidCallback onClearFilters;

  final Future<void> Function() onRefresh;

  final Future<void> Function(Map<String, dynamic> expense) onEdit;
  final Future<void> Function(Map<String, dynamic> expense) onDelete;
  final Future<void> Function(Map<String, dynamic> expense) onDuplicate;

  const ExpenseListSection({
    super.key,
    required this.sections,
    required this.filteredExpenses,
    required this.searchQuery,
    required this.currencyFormatter,
    required this.hasActiveFilters,
    required this.isGuest,
    required this.onClearFilters,
    required this.onRefresh,
    required this.onEdit,
    required this.onDelete,
    required this.onDuplicate,
  });

  @override
  Widget build(BuildContext context) {
    final sectionSpacing = ResponsiveHelper.sectionSpacing(context);
    final spacing = ResponsiveHelper.spacing(context);
    final compact = ResponsiveHelper.useCompactLayout(context);

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

        return Padding(
          padding: EdgeInsets.only(
            top: index == 0 ? spacing : sectionSpacing * 0.5,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ExpenseDateHeader(title: section.key),

              SizedBox(height: compact ? 2 : 4),

              ...section.value.map(
                (expense) => ExpenseItemCard(
                  expense: expense,
                  searchQuery: searchQuery,
                  currencyFormatter: currencyFormatter,

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
