import 'package:flutter/material.dart';

import '../services/sync_service.dart';

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

  String selectedDateFilter = 'All';

  String selectedSort = 'Newest';

  String selectedCategory = 'All';

  bool filtersExpanded = false;

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

    fetchExpenses();

    widget.onRefreshReady?.call(refreshExpenses);

    scrollController.addListener(() {
      if (scrollController.position.pixels ==
          scrollController.position.maxScrollExtent) {
        fetchExpenses();
      }
    });
  }

  Future<void> fetchExpenses() async {
    try {
      final newExpenses = await expenseController.fetchExpenses();

      if (!mounted) return;

      setState(() {
        expenses.addAll(newExpenses);

        filterExpenses();

        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> refreshExpenses() async {
    setState(() {
      isLoading = true;

      expenses.clear();
      filteredExpenses.clear();
    });

    expenseController.resetPagination();

    await fetchExpenses();

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 1),
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 8),
            Text("Expenses updated"),
          ],
        ),
      ),
    );
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

            if (expenseController.hasMore)
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(compact ? 14 : 20),
                  child: const Center(child: CircularProgressIndicator()),
                ),
              ),
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
        final result = await ExpenseActions.editExpense(context, expense);

        if (result == true) {
          expenses.clear();
          filteredExpenses.clear();

          expenseController.resetPagination();

          await fetchExpenses();
        }
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
}
