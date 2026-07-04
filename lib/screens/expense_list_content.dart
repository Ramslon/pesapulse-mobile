import 'package:flutter/material.dart';
import 'package:pesapulse_mobile/widgets/expense_loading_widget.dart';

import '../services/api_services.dart';
import 'edit_expense_screen.dart';
import '../widgets/empty_expense_state.dart';
import '../widgets/no_filter_results_widget.dart';

class ExpenseListContent extends StatefulWidget {
  const ExpenseListContent({super.key});

  @override
  State<ExpenseListContent> createState() => _ExpenseListContentState();
}

class _ExpenseListContentState extends State<ExpenseListContent> {
  List expenses = [];

  List filteredExpenses = [];

  String selectedDateFilter = 'All';

  String selectedSort = 'Newest';

  String selectedCategory = 'All';

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

  TextEditingController searchController = TextEditingController();

  final ScrollController scrollController = ScrollController();

  bool isLoading = true;

  int currentPage = 1;

  bool hasMore = true;

  bool isFetchingMore = false;

  double totalAmount = 0;

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

  @override
  void initState() {
    super.initState();

    fetchExpenses();

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
      final response = await ApiService.getExpenses(page: currentPage);

      final List newExpenses = response['data'] ?? [];

      setState(() {
        expenses.addAll(newExpenses);

        totalAmount = expenses.fold(
          0,
          (sum, item) =>
              sum + (double.tryParse(item['amount'].toString()) ?? 0),
        );

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
  }

  void filterExpenses() {
    List temp = expenses;

    // Search
    if (searchController.text.isNotEmpty) {
      temp = temp.where((expense) {
        return expense['title'].toString().toLowerCase().contains(
          searchController.text.toLowerCase(),
        );
      }).toList();
    }

    // Category
    if (selectedCategory != 'All') {
      temp = temp.where((expense) {
        return expense['category'].toString().toLowerCase() ==
            selectedCategory.toLowerCase();
      }).toList();
    }

    applyDateFilter(temp);

    sortExpenses();

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
          (a, b) => a['title'].toString().compareTo(b['title'].toString()),
        );
        break;

      case 'Z-A':
        filteredExpenses.sort(
          (a, b) => b['title'].toString().compareTo(a['title'].toString()),
        );
        break;
    }
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
  Widget build(BuildContext context) {
    if (isLoading) {
      return const ExpenseLoadingWidget();
    }

    if (expenses.isEmpty) {
      return const EmptyExpenseState();
    }

    return RefreshIndicator(
      onRefresh: refreshExpenses,
      color: Theme.of(context).colorScheme.primary,
      child: CustomScrollView(
        controller: scrollController,
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        slivers: [
          SliverToBoxAdapter(child: _buildHeader()),

          SliverToBoxAdapter(child: _buildSummaryCard()),

          SliverToBoxAdapter(child: _buildSearchBar()),

          SliverToBoxAdapter(child: _buildDateFilters()),

          SliverToBoxAdapter(child: const SizedBox(height: 15)),

          SliverToBoxAdapter(child: _buildCategoryFilters()),

          SliverToBoxAdapter(child: const SizedBox(height: 20)),

          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),

            switchInCurve: Curves.easeOut,

            switchOutCurve: Curves.easeIn,

            child: _buildExpenseList(),
          ),

          if (hasMore)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Center(child: CircularProgressIndicator()),
              ),
            ),
        ],
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
                      "KES ${totalAmount.toStringAsFixed(0)}",
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 4),

                    Text(
                      "${expenses.length} Transactions",
                      style: const TextStyle(color: Colors.grey),
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

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: searchController,
              onChanged: (_) => filterExpenses(),
              decoration: InputDecoration(
                hintText: "Search expenses...",
                prefixIcon: const Icon(Icons.search),
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

          IconButton(onPressed: showSortSheet, icon: const Icon(Icons.tune)),
        ],
      ),
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
      return const SliverFillRemaining(
        hasScrollBody: false,
        child: NoFilterResultsWidget(),
      );
    }
    return SliverList(
      delegate: SliverChildBuilderDelegate((context, index) {
        final expense = filteredExpenses[index];

        return _buildExpenseCard(expense);
      }, childCount: filteredExpenses.length),
    );
  }

  Widget _buildExpenseCard(Map<String, dynamic> expense) {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 350),

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
          await ApiService.deleteExpense(expense['id']);

          expenses.removeWhere((e) => e['id'] == expense['id']);

          filterExpenses();

          setState(() {});

          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text("Expense deleted")));
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

        child: Card(
          elevation: 1.5,

          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),

          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),

          child: Padding(
            padding: const EdgeInsets.all(10),

            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: categoryColor(
                        expense['category'],
                      ).withOpacity(.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      expense['category'],
                      style: TextStyle(
                        color: categoryColor(expense['category']),
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  Text(
                    expense['title'],
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),

                  const SizedBox(height: 5),

                  Text(
                    formatDate(expense['expense_date']),
                    style: const TextStyle(color: Colors.grey),
                  ),

                  const SizedBox(height: 18),

                  Row(
                    children: [
                      Text(
                        "KES ${expense['amount']}",
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
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
