import 'package:flutter/material.dart';

import '../services/sync_service.dart';

import '../services/sync_events.dart';
import '../repositories/expense_repository.dart';

import '../actions/expense_actions.dart';
import '../controllers/expense_controller.dart';

import '../widgets/expense_loading_skeleton.dart';
import '../widgets/app/adaptive_app_bar.dart';
import '../widgets/app/app_scaffold.dart';
import '../widgets/expense_content/expense_list_header.dart';
import '../widgets/expense_content/expense_summary_section.dart';
import '../widgets/expense_content/expense_search_bar.dart';
import '../widgets/expense_content/expense_search_suggestions.dart';
import '../widgets/expense_content/expense_filter_header.dart';
import '../widgets/expense_content/expense_date_filters.dart';
import '../widgets/expense_content/expense_category_filters.dart';
import '../widgets/expense_content/expense_list_section.dart';

import '../utils/responsive_helper.dart';
import '../utils/expense_filters.dart';
import '../utils/expense_date_utils.dart';
import '../utils/expense_search_utils.dart';
import '../utils/snackbar_helper.dart';
import '../core/utils/currency_formatter.dart';

import '../screens/add_expense_screen.dart';

class ExpenseListContent extends StatefulWidget {
  final void Function(Future<void> Function())? onRefreshReady;

  const ExpenseListContent({super.key, this.onRefreshReady});

  @override
  ExpenseListContentState createState() => ExpenseListContentState();
}

class ExpenseListContentState extends State<ExpenseListContent>
    with AutomaticKeepAliveClientMixin {
  List<Map<String, dynamic>> expenses = [];
  List<Map<String, dynamic>> filteredExpenses = [];

  final ExpenseController expenseController = ExpenseController();

  final ExpenseRepository expenseRepository = ExpenseRepository();

  String selectedDateFilter = 'All';

  String selectedSort = 'Newest';

  String selectedCategory = 'All';

  DateTime _selectedPeriod = DateTime(
    DateTime.now().year,
    DateTime.now().month,
  );

  bool _isLoadingHistoricalPeriod = false;

  bool get _isCurrentPeriod {
    final now = DateTime.now();

    return _selectedPeriod.year == now.year &&
        _selectedPeriod.month == now.month;
  }

  String get _selectedPeriodLabel {
    final months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];

    return '${months[_selectedPeriod.month - 1]} ${_selectedPeriod.year}';
  }

  bool filtersExpanded = false;

  bool get hasNoExpenses => expenses.isEmpty;

  bool get hasNoFilteredResults =>
      expenses.isNotEmpty && filteredExpenses.isEmpty;

  final List<String> filterCategories = [
    'All',
    'Food',
    'Transport',
    'Shopping',
    'Bills',
    'Entertainment',
    'Health',
    'Education',
    'Other',
  ];

  List<String> recentSearches = [];

  final List<String> defaultSuggestions = [
    "Food",
    "Transport",
    "Shopping",
    "Bills",
    "Health",
    "Education",
    "Entertainment",
    "Other",
  ];

  TextEditingController searchController = TextEditingController();

  final ScrollController scrollController = ScrollController();

  bool isLoading = true;

  bool isGuest = false;

  double totalAmount = 0;

  bool get isSearching =>
      searchController.text.trim().isNotEmpty ||
      selectedCategory != "All" ||
      selectedDateFilter != "All";

  Map<String, dynamic>? recentlyDeletedExpense;
  int? recentlyDeletedIndex;

  Color categoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'food':
        return Colors.orange;

      case 'transport':
        return Colors.blue;

      case 'shopping':
        return Colors.purple;

      case 'bills':
        return Colors.red;

      case 'health':
        return Colors.green;

      case 'education':
        return Colors.indigo;

      case 'entertainment':
        return Colors.pink;

      default:
        return Colors.grey;
    }
  }

  IconData categoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'food':
        return Icons.restaurant;
      case 'transport':
        return Icons.directions_car;
      case 'shopping':
        return Icons.shopping_bag;
      case 'bills':
        return Icons.receipt_long;
      case 'health':
        return Icons.favorite;
      case 'education':
        return Icons.school;
      case 'entertainment':
        return Icons.movie;
      default:
        return Icons.account_balance_wallet;
    }
  }

  double get filteredTotalAmount => filteredExpenses.fold(
    0.0,
    (sum, e) => sum + (double.tryParse(e["amount"].toString()) ?? 0),
  );

  int get filteredExpenseCount => filteredExpenses.length;

  double get highestExpense {
    if (filteredExpenses.isEmpty) return 0;

    return filteredExpenses
        .map((e) => double.tryParse(e["amount"].toString()) ?? 0)
        .reduce((a, b) => a > b ? a : b);
  }

  double get averageExpense {
    if (filteredExpenses.isEmpty) return 0;

    return filteredTotalAmount / filteredExpenses.length;
  }

  int get categoryCount =>
      filteredExpenses.map((e) => e["category"].toString()).toSet().length;

  bool get hasActiveFilters {
    return searchController.text.trim().isNotEmpty ||
        selectedCategory != "All" ||
        selectedDateFilter != "All";
  }

  @override
  void initState() {
    super.initState();

    SyncEvents.instance.expensesRefresh.addListener(_handleExpensesRefresh);

    _loadSelectedPeriod();

    widget.onRefreshReady?.call(refreshExpenses);
  }

  void _handleExpensesRefresh() {
    if (!mounted) return;

    if (_isCurrentPeriod) {
      _reloadExpensesFromLocal();
    } else {
      _loadSelectedPeriod();
    }
  }

  Future<void> _loadSelectedPeriod({bool showSuccessMessage = false}) async {
    if (_isLoadingHistoricalPeriod || !mounted) return;

    setState(() {
      _isLoadingHistoricalPeriod = true;
      isLoading = true;
    });

    try {
      final loadedExpenses = <Map<String, dynamic>>[];
      var page = 1;
      var hasMore = true;

      while (hasMore) {
        final response = await expenseRepository.getExpenses(
          page: page,
          month: _selectedPeriod.month,
          year: _selectedPeriod.year,
        );

        final pageExpenses = (response['data'] as List? ?? [])
            .map((expense) => Map<String, dynamic>.from(expense))
            .toList();

        loadedExpenses.addAll(pageExpenses);

        final nextPageUrl = response['next_page_url'];
        hasMore = nextPageUrl != null && nextPageUrl.toString().isNotEmpty;

        if (hasMore) page++;
      }

      if (!mounted) return;

      setState(() {
        expenses = loadedExpenses;
        filterExpenses();
        isLoading = false;
        _isLoadingHistoricalPeriod = false;
      });

      if (showSuccessMessage) {
        SnackbarHelper.showSuccess(
          context,
          '$_selectedPeriodLabel expenses updated',
        );
      }
    } catch (e) {
      debugPrint('ExpenseListContent: remote period load failed: $e');

      try {
        final localExpenses = await expenseRepository.getExpensesFromLocal(
          month: _selectedPeriod.month,
          year: _selectedPeriod.year,
        );

        if (!mounted) return;

        setState(() {
          expenses = localExpenses;
          filterExpenses();
          isLoading = false;
          _isLoadingHistoricalPeriod = false;
        });

        if (showSuccessMessage) {
          SnackbarHelper.showSuccess(
            context,
            'Showing saved expenses for $_selectedPeriodLabel',
          );
        }
      } catch (cacheError) {
        if (!mounted) return;

        setState(() {
          isLoading = false;
          _isLoadingHistoricalPeriod = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Unable to load expenses: $cacheError')),
        );
      }
    }
  }

  Future<void> _showPeriodPicker() async {
    final now = DateTime.now();

    final selected = await showModalBottomSheet<DateTime>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return _ExpensePeriodPicker(
          selectedPeriod: _selectedPeriod,
          currentPeriod: DateTime(now.year, now.month),
        );
      },
    );

    if (selected == null || !mounted) return;

    if (selected.year == _selectedPeriod.year &&
        selected.month == _selectedPeriod.month) {
      return;
    }

    setState(() {
      _selectedPeriod = DateTime(selected.year, selected.month);

      selectedDateFilter = 'All';
      selectedCategory = 'All';
      selectedSort = 'Newest';
      searchController.clear();
    });

    await _loadSelectedPeriod();
  }

  Future<void> _reloadExpensesFromLocal() async {
    try {
      final localExpenses = await expenseRepository.getExpensesFromLocal(
        month: _selectedPeriod.month,
        year: _selectedPeriod.year,
      );

      if (!mounted) return;

      setState(() {
        expenses = localExpenses;
        filterExpenses();
        isLoading = false;
      });

      debugPrint(
        'ExpenseListContent: reloaded '
        '${localExpenses.length} '
        '$_selectedPeriodLabel expenses from local cache.',
      );
    } catch (e) {
      debugPrint('ExpenseListContent: failed to reload local expenses: $e');
    }
  }

  Future<void> refreshExpenses() async {
    await _loadSelectedPeriod(showSuccessMessage: true);
  }

  void filterExpenses() {
    filteredExpenses = ExpenseFilters.filter(
      expenses: expenses,
      searchQuery: searchController.text,
      selectedCategory: selectedCategory,
      selectedDateFilter: selectedDateFilter,
      selectedSort: selectedSort,
      formatDate: ExpenseDateUtils.formatDate,
    );
  }

  void resetFilters() {
    setState(() {
      searchController.clear();

      selectedCategory = "All";
      selectedSort = "Newest";
      selectedDateFilter = "All";

      filterExpenses();
    });
  }

  void clearFilters() {
    setState(() {
      searchController.clear();

      selectedCategory = "All";
      selectedDateFilter = "All";
      selectedSort = "Newest";

      filterExpenses();
    });
  }

  void showSortSheet() {
    final options = [
      'Newest',
      'Oldest',
      'Highest Amount',
      'Lowest Amount',
      'A-Z',
      'Z-A',
    ];

    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) {
        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            children: [
              const ListTile(
                title: Text(
                  "Sort Expenses",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
              ),

              ...options.map((option) {
                return RadioListTile<String>(
                  value: option,
                  groupValue: selectedSort,
                  title: Text(option),
                  onChanged: (value) {
                    if (value == null) return;

                    setState(() {
                      selectedSort = value;
                      filterExpenses();
                    });

                    Navigator.pop(context);
                  },
                );
              }),
            ],
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    SyncEvents.instance.expensesRefresh.removeListener(_handleExpensesRefresh);

    scrollController.dispose();
    searchController.dispose();

    super.dispose();
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final compact = ResponsiveHelper.useCompactLayout(context);
    final landscape = ResponsiveHelper.isLandscape(context);

    final horizontalPadding = compact
        ? 14.0
        : landscape
        ? 24.0
        : 20.0;

    if (isLoading) {
      return const ExpenseLoadingSkeleton();
    }

    return AppScaffold(
      appBar: const AdaptiveAppBar(title: null),

      floatingActionButton: FloatingActionButton.extended(
        heroTag: "expenseFabInner",
        backgroundColor: Theme.of(context).colorScheme.primary,
        icon: const Icon(Icons.add),
        label: Text(compact ? "New" : "New Expense"),
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddExpenseScreen()),
          );

          if (result == true) {
            await refreshExpenses();
          }
        },
      ),

      body: RefreshIndicator(
        onRefresh: refreshExpenses,
        color: Theme.of(context).colorScheme.primary,

        child: CustomScrollView(
          key: const PageStorageKey("expenses"),
          controller: scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,

          slivers: [
            SliverToBoxAdapter(
              child: ExpenseListHeader(horizontalPadding: horizontalPadding),
            ),

            SliverToBoxAdapter(child: _buildPeriodSelector(context)),

            SliverToBoxAdapter(
              child: ExpenseSummarySection(
                totalAmount: filteredTotalAmount,
                expenseCount: filteredExpenseCount,
                categoryCount: categoryCount,
                highestExpense: highestExpense,
                averageExpense: averageExpense,
              ),
            ),

            SliverToBoxAdapter(
              child: ExpenseSearchBar(
                controller: searchController,
                onChanged: (value) {
                  filterExpenses();

                  if (value.trim().isNotEmpty) {
                    recentSearches = ExpenseSearchUtils.addRecentSearch(
                      recentSearches: recentSearches,
                      query: value,
                    );
                  }

                  setState(() {});
                },
                onClear: () {
                  searchController.clear();
                  filterExpenses();
                  setState(() {});
                },
                onSort: showSortSheet,
              ),
            ),

            if (searchController.text.isEmpty)
              SliverToBoxAdapter(
                child: ExpenseSearchSuggestions(
                  searchText: searchController.text,
                  recentSearches: recentSearches,
                  defaultSuggestions: defaultSuggestions,
                  onSearchSelected: (value) {
                    searchController.text = value;
                    filterExpenses();
                    setState(() {});
                  },
                ),
              ),
            SliverToBoxAdapter(
              child: Column(
                children: [
                  ExpenseFilterHeader(
                    filtersExpanded: filtersExpanded,
                    onTap: () {
                      setState(() {
                        filtersExpanded = !filtersExpanded;
                      });
                    },
                  ),

                  AnimatedCrossFade(
                    duration: const Duration(milliseconds: 250),

                    crossFadeState: filtersExpanded
                        ? CrossFadeState.showFirst
                        : CrossFadeState.showSecond,

                    firstChild: Column(
                      children: [
                        SizedBox(height: compact ? 10 : 15),

                        ExpenseDateFilters(
                          selectedDateFilter: selectedDateFilter,
                          onFilterSelected: (filter) {
                            setState(() {
                              selectedDateFilter = filter;
                              filterExpenses();
                            });
                          },
                        ),

                        SizedBox(height: compact ? 10 : 15),

                        ExpenseCategoryFilters(
                          categories: filterCategories,
                          selectedCategory: selectedCategory,
                          onCategorySelected: (category) {
                            setState(() {
                              selectedCategory = category;
                              filterExpenses();
                            });
                          },
                        ),

                        SizedBox(height: compact ? 15 : 20),

                        Align(
                          alignment: Alignment.centerRight,
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: horizontalPadding,
                            ),
                            child: TextButton.icon(
                              onPressed: resetFilters,
                              icon: const Icon(Icons.refresh),
                              label: const Text("Reset Filters"),
                            ),
                          ),
                        ),

                        SizedBox(height: compact ? 15 : 20),
                      ],
                    ),

                    secondChild: const SizedBox.shrink(),
                  ),
                ],
              ),
            ),

            _buildExpenseList(),
          ],
        ),
      ),
    );
  }

  Widget buildHighlightedText(String text, String query, bool compact) {
    final textStyle = TextStyle(
      fontSize: compact ? 14 : 16,
      fontWeight: FontWeight.w600,
    );

    if (query.isEmpty) {
      return Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: textStyle,
      );
    }

    final lowerText = text.toLowerCase();
    final lowerQuery = query.toLowerCase();

    final start = lowerText.indexOf(lowerQuery);

    if (start == -1) {
      return Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: textStyle,
      );
    }

    final end = start + query.length;

    return RichText(
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      text: TextSpan(
        style: textStyle.copyWith(
          color: Theme.of(context).textTheme.bodyMedium?.color,
        ),
        children: [
          TextSpan(text: text.substring(0, start)),
          TextSpan(
            text: text.substring(start, end),
            style: textStyle.copyWith(
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          TextSpan(text: text.substring(end)),
        ],
      ),
    );
  }

  Widget _buildExpenseList() {
    final groupedExpenses = ExpenseDateUtils.groupExpensesByDate(
      filteredExpenses,
    );
    final sections = groupedExpenses.entries.toList();

    return ExpenseListSection(
      sections: sections,
      filteredExpenses: filteredExpenses,
      searchQuery: searchController.text,
      currencyFormatter: CurrencyFormatter.format,
      hasActiveFilters: hasActiveFilters,
      isGuest: isGuest,

      onClearFilters: clearFilters,

      onRefresh: refreshExpenses,

      onEdit: (expense) async {
        await ExpenseActions.editExpense(context, expense);
      },
      onDelete: (expense) async {
        recentlyDeletedExpense = expense;

        recentlyDeletedIndex = expenses.indexWhere(
          (e) => e["id"] == expense["id"],
        );

        await ExpenseActions.deleteExpense(
          context: context,

          onDeleteLocally: () {
            expenses.removeWhere((e) => e["id"] == expense["id"]);

            filterExpenses();

            setState(() {});
          },

          onUndo: () {
            if (recentlyDeletedExpense != null &&
                recentlyDeletedIndex != null) {
              expenses.insert(recentlyDeletedIndex!, recentlyDeletedExpense!);

              filterExpenses();

              setState(() {});
            }
          },

          onDeletePermanently: () async {
            if (recentlyDeletedExpense != null) {
              await expenseController.deleteExpense(
                recentlyDeletedExpense!["id"],
              );

              await SyncService.instance.getPendingChanges();
            }

            recentlyDeletedExpense = null;
            recentlyDeletedIndex = null;
          },
        );
      },

      onDuplicate: (expense) async {
        final result = await ExpenseActions.duplicateExpense(context, expense);

        if (result == true) {
          await refreshExpenses();
        }
      },
    );
  }

  Widget _buildPeriodSelector(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final compact = ResponsiveHelper.useCompactLayout(context);

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 14 : 20,
        vertical: compact ? 8 : 10,
      ),
      child: Container(
        padding: EdgeInsets.all(compact ? 12 : 14),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(compact ? 16 : 18),
          border: Border.all(
            color: colorScheme.outlineVariant.withOpacity(0.6),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: compact ? 40 : 44,
              height: compact ? 40 : 44,
              decoration: BoxDecoration(
                color: colorScheme.primary.withOpacity(0.10),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                _isCurrentPeriod
                    ? Icons.calendar_month_rounded
                    : Icons.history_rounded,
                color: colorScheme.primary,
                size: compact ? 20 : 22,
              ),
            ),

            SizedBox(width: compact ? 10 : 12),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _isCurrentPeriod ? 'Current Month' : 'Expense History',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  const SizedBox(height: 2),

                  Text(
                    _selectedPeriodLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 8),

            OutlinedButton.icon(
              onPressed: _showPeriodPicker,
              icon: Icon(Icons.swap_horiz_rounded, size: compact ? 17 : 18),
              label: Text(compact ? 'Change' : 'Change Period'),
              style: OutlinedButton.styleFrom(
                padding: EdgeInsets.symmetric(
                  horizontal: compact ? 10 : 12,
                  vertical: compact ? 9 : 10,
                ),
                visualDensity: compact
                    ? VisualDensity.compact
                    : VisualDensity.standard,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExpensePeriodPicker extends StatelessWidget {
  final DateTime selectedPeriod;
  final DateTime currentPeriod;

  const _ExpensePeriodPicker({
    required this.selectedPeriod,
    required this.currentPeriod,
  });

  static const List<String> _months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final periods = <DateTime>[];

    // Show the current month plus the previous 11 months.
    for (int i = 0; i < 12; i++) {
      periods.add(DateTime(currentPeriod.year, currentPeriod.month - i));
    }

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Expense Period',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),

            const SizedBox(height: 6),

            Text(
              'Choose a month to view its expenses.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),

            const SizedBox(height: 18),

            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 420),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: periods.length,
                separatorBuilder: (_, __) => const SizedBox(height: 6),
                itemBuilder: (context, index) {
                  final period = periods[index];

                  final isSelected =
                      period.year == selectedPeriod.year &&
                      period.month == selectedPeriod.month;

                  final isCurrent =
                      period.year == currentPeriod.year &&
                      period.month == currentPeriod.month;

                  return ListTile(
                    selected: isSelected,
                    selectedTileColor: colorScheme.primary.withOpacity(0.08),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    leading: Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? colorScheme.primary.withOpacity(0.12)
                            : colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(11),
                      ),
                      alignment: Alignment.center,
                      child: Icon(
                        isCurrent
                            ? Icons.calendar_today_rounded
                            : Icons.history_rounded,
                        size: 19,
                        color: isSelected
                            ? colorScheme.primary
                            : colorScheme.onSurfaceVariant,
                      ),
                    ),
                    title: Text(
                      '${_months[period.month - 1]} ${period.year}',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    subtitle: isCurrent
                        ? const Text('Current month')
                        : const Text('Expense history'),
                    trailing: isSelected
                        ? Icon(
                            Icons.check_circle_rounded,
                            color: colorScheme.primary,
                          )
                        : null,
                    onTap: () {
                      Navigator.pop(context, period);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
