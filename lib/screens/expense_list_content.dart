import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:pesapulse_mobile/widgets/sync_status_icon.dart';
import 'package:pesapulse_mobile/screens/expense_details_screen.dart';

import 'edit_expense_screen.dart';

import '../widgets/empty_state_helper.dart';
import '../widgets/no_filter_results_widget.dart';
import '../widgets/expense_loading_skeleton.dart';
import '../widgets/offline_banner.dart';
import '../repositories/expense_repository.dart';
import '../services/sync_service.dart';
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
    return Scaffold(
      appBar: AppBar(
        title: const Text(""),

        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 12),
            child: SyncStatusIcon(), //  quick glance sync state
          ),
        ],
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(40),
          child: OfflineBanner(), // pinned under AppBar
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: "expenseFabInner",
        backgroundColor: Theme.of(context).colorScheme.primary,
        icon: const Icon(Icons.add),
        label: const Text("New Expense"),
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
      body: isLoading
          ? const ExpenseLoadingSkeleton()
          : RefreshIndicator(
              onRefresh: refreshExpenses,
              color: Theme.of(context).colorScheme.primary,
              child: CustomScrollView(
                key: const PageStorageKey("expenses"),
                controller: scrollController,
                physics: const AlwaysScrollableScrollPhysics(),
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                slivers: [
                  SliverToBoxAdapter(child: _buildHeader()),
                  SliverToBoxAdapter(child: _buildSummaryCard()),
                  SliverToBoxAdapter(child: _buildSearchBar()),

                  if (searchController.text.isEmpty)
                    SliverToBoxAdapter(child: buildSearchSuggestions()),

                  SliverToBoxAdapter(
                    child: Column(
                      children: [
                        _buildFiltersHeader(),

                        AnimatedCrossFade(
                          duration: const Duration(milliseconds: 250),
                          crossFadeState: filtersExpanded
                              ? CrossFadeState.showFirst
                              : CrossFadeState.showSecond,

                          firstChild: Column(
                            children: [
                              const SizedBox(height: 15),

                              _buildDateFilters(),

                              const SizedBox(height: 15),

                              _buildCategoryFilters(),

                              //   const SizedBox(height: 20),

                              //   _buildSortDropdown(),
                              const SizedBox(height: 20),

                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton.icon(
                                  onPressed: resetFilters,
                                  icon: const Icon(Icons.refresh),
                                  label: const Text("Reset Filters"),
                                ),
                              ),

                              const SizedBox(height: 20),
                            ],
                          ),

                          secondChild: const SizedBox.shrink(),
                        ),
                      ],
                    ),
                  ),

                  _buildExpenseList(),

                  if (hasMore)
                    const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.all(20),
                        child: Center(child: CircularProgressIndicator()),
                      ),
                    ),
                ],
              ),
            ),
    );
  }

  Widget buildHighlightedText(String text, String query) {
    if (query.isEmpty) {
      return Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
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
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      );
    }

    final end = start + query.length;

    return RichText(
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      text: TextSpan(
        style: const TextStyle(
          fontSize: 16,
          color: Colors.black,
          fontWeight: FontWeight.w600,
        ),
        children: [
          TextSpan(text: text.substring(0, start)),
          TextSpan(
            text: text.substring(start, end),
            style: TextStyle(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
          TextSpan(text: text.substring(end)),
        ],
      ),
    );
  }

  Widget _buildFiltersHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () {
          setState(() {
            filtersExpanded = !filtersExpanded;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              const Icon(Icons.filter_list),

              const SizedBox(width: 10),

              const Expanded(
                child: Text(
                  "Filters",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),

              AnimatedRotation(
                turns: filtersExpanded ? 0.5 : 0,
                duration: const Duration(milliseconds: 250),
                child: const Icon(Icons.keyboard_arrow_down),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return const Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, 5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Expenses",
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          ),

          SizedBox(height: 6),

          Text(
            "Track and manage your spending",
            style: TextStyle(color: Colors.grey, fontSize: 15),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: Theme.of(
                  context,
                ).colorScheme.primary.withOpacity(.12),
                child: Icon(
                  Icons.account_balance_wallet,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),

              const SizedBox(width: 18),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "KES ${currencyFormatter.format(filteredTotalAmount)}",
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 4),

                    Text(
                      "$filteredExpenseCount ${filteredExpenseCount == 1 ? "Transaction" : "Transactions"}",
                      style: const TextStyle(color: Colors.grey),
                    ),

                    const SizedBox(height: 16),

                    Row(
                      children: [
                        Expanded(
                          child: _buildMiniStat(
                            "Categories",
                            categoryCount.toString(),
                          ),
                        ),

                        Expanded(
                          child: _buildMiniStat(
                            "Highest",
                            "KES ${currencyFormatter.format(highestExpense)}",
                          ),
                        ),

                        Expanded(
                          child: _buildMiniStat(
                            "Average",
                            "KES ${currencyFormatter.format(averageExpense)}",
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMiniStat(String title, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
        ),
        const SizedBox(height: 4),
        Text(title, style: const TextStyle(color: Colors.grey, fontSize: 12)),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: searchController,
              textInputAction: TextInputAction.search,
              onChanged: (value) {
                filterExpenses();

                if (value.trim().isNotEmpty) {
                  addRecentSearch(value);
                }

                setState(() {});
              },

              decoration: InputDecoration(
                hintText: "Search expenses...",

                prefixIcon: const Icon(Icons.search),

                suffixIcon: searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          searchController.clear();
                          filterExpenses();
                          setState(() {});
                        },
                      )
                    : null,

                filled: true,

                fillColor: Theme.of(
                  context,
                ).colorScheme.surfaceContainerHighest,

                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),

                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),

                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(width: 10),

          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(16),
            ),
            child: IconButton(
              onPressed: showSortSheet,
              icon: const Icon(Icons.tune),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildSearchSuggestions() {
    if (searchController.text.isNotEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (recentSearches.isNotEmpty) ...[
          const Text(
            "Recent Searches",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 10),

          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: recentSearches.map((search) {
              return ActionChip(
                label: Text(search),
                onPressed: () {
                  searchController.text = search;
                  filterExpenses();
                  setState(() {});
                },
              );
            }).toList(),
          ),

          const SizedBox(height: 20),
        ],

        const Text(
          "Suggestions",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),

        const SizedBox(height: 10),

        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: defaultSuggestions.map((category) {
            return FilterChip(
              label: Text(category),
              selected: false,
              onSelected: (_) {
                searchController.text = category;

                filterExpenses();

                setState(() {});
              },
            );
          }).toList(),
        ),

        const SizedBox(height: 25),
      ],
    );
  }

  Widget _buildDateFilters() {
    return Padding(
      padding: const EdgeInsets.only(left: 20, top: 15),
      child: SizedBox(
        height: 40,
        child: ListView(
          scrollDirection: Axis.horizontal,
          children: [
            buildDateChip('All'),
            buildDateChip('Today'),
            buildDateChip('This Week'),
            buildDateChip('This Month'),
          ],
        ),
      ),
    );
  }

  Widget _buildDateHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 10),
      child: Row(
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),

          const SizedBox(width: 12),

          Expanded(child: Divider(thickness: 1, color: Colors.grey.shade300)),
        ],
      ),
    );
  }

  Widget _buildCategoryFilters() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Category",
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
          ),

          const SizedBox(height: 10),

          SizedBox(
            height: 45,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: filterCategories.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final category = filterCategories[index];

                final selected = category == selectedCategory;

                return ChoiceChip(
                  label: Text(category),

                  selected: selected,

                  selectedColor: Theme.of(context).colorScheme.primary,

                  backgroundColor: Theme.of(
                    context,
                  ).colorScheme.surfaceContainerHighest,

                  labelStyle: TextStyle(
                    color: selected ? Colors.white : null,
                    fontWeight: FontWeight.w600,
                  ),

                  showCheckmark: false,

                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),

                  onSelected: (_) {
                    setState(() {
                      selectedCategory = category;
                    });

                    filterExpenses();
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpenseList() {
    if (filteredExpenses.isEmpty) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: hasActiveFilters
            ? NoFilterResultsWidget(onClearFilters: clearFilters)
            : buildEmptyState(
                context,
                EmptyStateType.expenses,
                isGuest: isGuest,
              ),
      );
    }

    final groupedExpenses = groupExpensesByDate();

    final sections = groupedExpenses.entries.toList();

    return SliverList(
      delegate: SliverChildBuilderDelegate((context, index) {
        final section = sections[index];

        return Padding(
          padding: const EdgeInsets.only(top: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDateHeader(section.key),

              ...section.value.map((expense) => _buildExpenseCard(expense)),
            ],
          ),
        );
      }, childCount: sections.length),
    );
  }

  Widget _buildExpenseCard(Map<String, dynamic> expense) {
    final amount = double.tryParse(expense["amount"].toString()) ?? 0;
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 250),

      tween: Tween(begin: 0, end: 1),

      curve: Curves.easeOut,

      builder: (context, value, child) {
        return Opacity(
          opacity: value,

          child: Transform.translate(
            offset: Offset(0, 20 * (1 - value)),

            child: child,
          ),
        );
      },

      child: Dismissible(
        key: ValueKey(expense['id']),

        confirmDismiss: (direction) async {
          if (direction == DismissDirection.startToEnd) {
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

              fetchExpenses();
            }

            return false;
          }

          return await showDialog<bool>(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text("Delete Expense"),
                  content: const Text(
                    "Are you sure you want to delete this expense?",
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text("Cancel"),
                    ),

                    FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.red,
                      ),
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text("Delete"),
                    ),
                  ],
                ),
              ) ??
              false;
        },

        onDismissed: (_) async {
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
        background: Container(
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            color: Colors.blue,
            borderRadius: BorderRadius.circular(18),
          ),
          child: const Row(
            children: [
              Icon(Icons.edit, color: Colors.white),
              SizedBox(width: 8),
              Text(
                "Edit",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),

        secondaryBackground: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            color: Colors.red,
            borderRadius: BorderRadius.circular(18),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                "Delete",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(width: 8),
              Icon(Icons.delete, color: Colors.white),
            ],
          ),
        ),

        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            color: Theme.of(context).colorScheme.surface,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(.04),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Row(
              children: [
                Container(width: 5, color: categoryColor(expense["category"])),

                Expanded(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(18),

                    onTap: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              ExpenseDetailsScreen(expense: expense),
                        ),
                      );

                      if (result == true) {
                        refreshExpenses();
                      }
                    },

                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 24,
                            backgroundColor: categoryColor(
                              expense["category"],
                            ).withOpacity(.12),
                            child: Icon(
                              categoryIcon(expense["category"]),
                              color: categoryColor(expense["category"]),
                              size: 24,
                            ),
                          ),

                          const SizedBox(width: 14),

                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                buildHighlightedText(
                                  expense["title"] ?? "",
                                  searchController.text,
                                ),

                                const SizedBox(height: 4),

                                Row(
                                  children: [
                                    Text(
                                      expense["category"] ?? "Other",
                                      style: TextStyle(
                                        color: categoryColor(
                                          expense["category"],
                                        ),
                                        fontWeight: FontWeight.w500,
                                        fontSize: 13,
                                      ),
                                    ),

                                    const SizedBox(width: 8),

                                    Container(
                                      width: 4,
                                      height: 4,
                                      decoration: const BoxDecoration(
                                        color: Colors.grey,
                                        shape: BoxShape.circle,
                                      ),
                                    ),

                                    const SizedBox(width: 8),

                                    Flexible(
                                      child: Text(
                                        formatDate(expense["expense_date"]),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          color: Colors.grey,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(width: 12),

                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                "KES ${currencyFormatter.format(amount)}",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),

                              const SizedBox(height: 4),

                              PopupMenuButton<String>(
                                padding: EdgeInsets.zero,
                                icon: const Icon(Icons.more_vert, size: 18),
                                onSelected: (value) async {
                                  switch (value) {
                                    case "edit":
                                      final result = await Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => EditExpenseScreen(
                                            expense: expense,
                                          ),
                                        ),
                                      );

                                      if (result == true) {
                                        refreshExpenses();
                                      }
                                      break;

                                    case "delete":
                                      final confirm = await showDialog<bool>(
                                        context: context,
                                        builder: (_) => AlertDialog(
                                          title: const Text("Delete Expense"),
                                          content: const Text(
                                            "Are you sure you want to delete this expense?",
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.pop(context, false),
                                              child: const Text("Cancel"),
                                            ),
                                            FilledButton(
                                              style: FilledButton.styleFrom(
                                                backgroundColor: Colors.red,
                                              ),
                                              onPressed: () =>
                                                  Navigator.pop(context, true),
                                              child: const Text("Delete"),
                                            ),
                                          ],
                                        ),
                                      );

                                      if (confirm == true) {
                                        await repository.deleteExpense(
                                          expense["id"],
                                        );

                                        await SyncService.instance
                                            .getPendingChanges();

                                        expenses.removeWhere(
                                          (e) => e["id"] == expense["id"],
                                        );

                                        filterExpenses();

                                        if (context.mounted) {
                                          setState(() {});

                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            const SnackBar(
                                              content: Text("Expense deleted"),
                                            ),
                                          );
                                        }
                                      }

                                      break;

                                    case "duplicate":
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            "Duplicate feature coming soon",
                                          ),
                                        ),
                                      );
                                      break;
                                  }
                                },
                                itemBuilder: (_) => const [
                                  PopupMenuItem(
                                    value: "edit",
                                    child: Row(
                                      children: [
                                        Icon(Icons.edit),
                                        SizedBox(width: 10),
                                        Text("Edit"),
                                      ],
                                    ),
                                  ),
                                  PopupMenuItem(
                                    value: "delete",
                                    child: Row(
                                      children: [
                                        Icon(Icons.delete, color: Colors.red),
                                        SizedBox(width: 10),
                                        Text("Delete"),
                                      ],
                                    ),
                                  ),
                                  PopupMenuItem(
                                    value: "duplicate",
                                    child: Row(
                                      children: [
                                        Icon(Icons.copy),
                                        SizedBox(width: 10),
                                        Text("Duplicate"),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget buildDateChip(String label) {
    final selected = selectedDateFilter == label;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selectedColor: Theme.of(context).colorScheme.primary,

        labelStyle: TextStyle(
          color: selected ? Colors.white : null,
          fontWeight: FontWeight.w600,
        ),

        showCheckmark: false,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),

        selected: selected,

        onSelected: (_) {
          setState(() {
            selectedDateFilter = label;
          });

          filterExpenses();
        },
      ),
    );
  }
}
