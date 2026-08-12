import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:pesapulse_mobile/screens/expense_details_screen.dart';

import 'edit_expense_screen.dart';
import '../services/sync_service.dart';

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

import '../repositories/expense_repository.dart';

import '../screens/add_expense_screen.dart';

class ExpenseListContent extends StatefulWidget {
  final void Function(Future<void> Function())? onRefreshReady;

  const ExpenseListContent({super.key, this.onRefreshReady});

  @override
  ExpenseListContentState createState() => ExpenseListContentState();
}

class ExpenseListContentState extends State<ExpenseListContent>
    with AutomaticKeepAliveClientMixin {
  List expenses = [];

  final ExpenseRepository repository = ExpenseRepository();

  final NumberFormat currencyFormatter = NumberFormat("#,##0.00");

  List filteredExpenses = [];

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

  int currentPage = 1;

  bool hasMore = true;

  bool isFetchingMore = false;

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
    if (isFetchingMore || !hasMore) return;

    setState(() {
      isFetchingMore = true;
    });

    try {
      final response = await repository.getExpenses(page: currentPage);

      final List newExpenses = response['data'] ?? [];

      setState(() {
        expenses.addAll(newExpenses);

        filterExpenses();

        currentPage++;

        hasMore = response['next_page_url'] != null;

        isLoading = false;

        isFetchingMore = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
        isFetchingMore = false;
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

      currentPage = 1;
      hasMore = true;
    });

    await fetchExpenses();

    filterExpenses();

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

  Map<String, List<Map<String, dynamic>>> groupExpensesByDate() {
    final Map<String, List<Map<String, dynamic>>> grouped = {};

    for (final expense in filteredExpenses) {
      final rawDate = expense["expense_date"];

      if (rawDate == null) continue;

      final date = DateTime.tryParse(rawDate.toString());

      if (date == null) continue;

      final now = DateTime.now();

      String label;

      final difference = now.difference(date).inDays;

      if (difference == 0) {
        label = "Today";
      } else if (difference == 1) {
        label = "Yesterday";
      } else {
        label = DateFormat("dd MMM yyyy").format(date);
      }

      grouped.putIfAbsent(label, () => []);

      grouped[label]!.add(Map<String, dynamic>.from(expense));
    }

    return grouped;
  }

  void filterExpenses() {
    List temp = List.from(expenses);

    // Search
    if (searchController.text.isNotEmpty) {
      final query = searchController.text.trim().toLowerCase();

      temp = temp.where((expense) {
        final title = (expense["title"] ?? "").toString().toLowerCase();

        final category = (expense["category"] ?? "").toString().toLowerCase();

        final description = (expense["description"] ?? "")
            .toString()
            .toLowerCase();

        final amount = expense["amount"].toString().toLowerCase();

        final date = formatDate(expense["expense_date"]).toLowerCase();

        return title.contains(query) ||
            category.contains(query) ||
            description.contains(query) ||
            amount.contains(query) ||
            date.contains(query);
      }).toList();
    }

    // Category
    if (selectedCategory != 'All') {
      temp = temp.where((expense) {
        final expenseCategory = (expense['category'] ?? '')
            .toString()
            .trim()
            .toLowerCase();

        final selected = selectedCategory.trim().toLowerCase();

        return expenseCategory == selected;
      }).toList();
    }

    applyDateFilter(temp);

    sortExpenses();

    setState(() {});
  }

  void resetFilters() {
    searchController.clear();

    selectedCategory = "All";
    selectedSort = "Newest";

    selectedDateFilter = "All";

    filterExpenses();

    setState(() {});
  }

  void sortExpenses() {
    switch (selectedSort) {
      case 'Newest':
        filteredExpenses.sort(
          (a, b) => DateTime.parse(
            b['expense_date'],
          ).compareTo(DateTime.parse(a['expense_date'])),
        );
        break;

      case 'Oldest':
        filteredExpenses.sort(
          (a, b) => DateTime.parse(
            a['expense_date'],
          ).compareTo(DateTime.parse(b['expense_date'])),
        );
        break;

      case 'Highest Amount':
        filteredExpenses.sort(
          (a, b) => (double.tryParse(b['amount'].toString()) ?? 0).compareTo(
            double.tryParse(a['amount'].toString()) ?? 0,
          ),
        );
        break;

      case 'Lowest Amount':
        filteredExpenses.sort(
          (a, b) => (double.tryParse(a['amount'].toString()) ?? 0).compareTo(
            double.tryParse(b['amount'].toString()) ?? 0,
          ),
        );
        break;

      case 'A-Z':
        filteredExpenses.sort(
          (a, b) => a['title'].toString().toLowerCase().compareTo(
            b['title'].toString().toLowerCase(),
          ),
        );
        break;

      case 'Z-A':
        filteredExpenses.sort(
          (a, b) => b['title'].toString().toLowerCase().compareTo(
            a['title'].toString().toLowerCase(),
          ),
        );
        break;
    }
  }

  void addRecentSearch(String query) {
    query = query.trim();

    if (query.isEmpty) return;

    recentSearches.remove(query);

    recentSearches.insert(0, query);

    if (recentSearches.length > 5) {
      recentSearches.removeLast();
    }
  }

  void clearFilters() {
    searchController.clear();

    selectedCategory = "All";
    selectedDateFilter = "All";
    selectedSort = "Newest";

    filterExpenses();

    setState(() {});
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
                    setState(() {
                      selectedSort = value!;
                    });

                    filterExpenses();

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

  void applyDateFilter(List source) {
    final now = DateTime.now();

    final today = DateTime(now.year, now.month, now.day);

    filteredExpenses = source.where((expense) {
      final rawDate = DateTime.parse(expense['expense_date']);

      final date = DateTime(rawDate.year, rawDate.month, rawDate.day);

      switch (selectedDateFilter) {
        case 'Today':
          return date == today;

        case 'This Week':
          final startOfWeek = today.subtract(Duration(days: today.weekday - 1));

          final endOfWeek = startOfWeek.add(const Duration(days: 6));

          return !date.isBefore(startOfWeek) && !date.isAfter(endOfWeek);

        case 'This Month':
          return date.year == today.year && date.month == today.month;

        default:
          return true;
      }
    }).toList();
  }

  String formatDate(String date) {
    final expenseDate = DateTime.parse(date);

    final today = DateTime.now();

    final difference = today.difference(expenseDate).inDays;

    if (difference == 0) return "Today";

    if (difference == 1) return "Yesterday";

    return "${expenseDate.day}/${expenseDate.month}/${expenseDate.year}";
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
    final spacing = ResponsiveHelper.spacing(context);

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
                    addRecentSearch(value);
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
                            });

                            filterExpenses();
                          },
                        ),

                        SizedBox(height: compact ? 10 : 15),

                        ExpenseCategoryFilters(
                          categories: filterCategories,
                          selectedCategory: selectedCategory,
                          onCategorySelected: (category) {
                            setState(() {
                              selectedCategory = category;
                            });

                            filterExpenses();
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

            if (hasMore)
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
    final groupedExpenses = groupExpensesByDate();

    final sections = groupedExpenses.entries.toList();

    return ExpenseListSection(
      sections: sections,
      filteredExpenses: filteredExpenses,
      searchQuery: searchController.text,
      currencyFormatter: currencyFormatter,
      hasActiveFilters: hasActiveFilters,
      isGuest: isGuest,

      onClearFilters: clearFilters,

      onRefresh: refreshExpenses,

      onEdit: (expense) async {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => EditExpenseScreen(expense: expense),
          ),
        );

        if (result == true) {
          expenses.clear();
          filteredExpenses.clear();
          currentPage = 1;
          hasMore = true;

          await fetchExpenses();
        }
      },

      onDelete: (expense) async {
        recentlyDeletedExpense = expense;
        recentlyDeletedIndex = expenses.indexWhere(
          (e) => e["id"] == expense["id"],
        );
        expenses.removeWhere((e) => e["id"] == expense["id"]);
        filterExpenses();
        setState(() {});
        bool undoPressed = false;
        ScaffoldMessenger.of(context)
            .showSnackBar(
              SnackBar(
                duration: const Duration(seconds: 5),
                content: const Text("Expense deleted"),
                action: SnackBarAction(
                  label: "UNDO",
                  onPressed: () {
                    undoPressed = true;
                    if (recentlyDeletedExpense != null &&
                        recentlyDeletedIndex != null) {
                      expenses.insert(
                        recentlyDeletedIndex!,
                        recentlyDeletedExpense!,
                      );
                      filterExpenses();
                      setState(() {});
                    }
                  },
                ),
              ),
            )
            .closed
            .then((_) async {
              if (!undoPressed && recentlyDeletedExpense != null) {
                await repository.deleteExpense(recentlyDeletedExpense!["id"]);
                await SyncService.instance.getPendingChanges();
              }
              recentlyDeletedExpense = null;
              recentlyDeletedIndex = null;
            });
      },

      onDuplicate: (expense) async {
        // Keep the current temporary logic for now.
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ExpenseDetailsScreen(expense: expense),
          ),
        );

        if (result == true) {
          await refreshExpenses();
        }
      },
    );
  }
}
