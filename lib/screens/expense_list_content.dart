import 'package:flutter/material.dart';
import 'package:pesapulse_mobile/widgets/loading_widget.dart';

import '../services/api_services.dart';
import 'edit_expense_screen.dart';

class ExpenseListContent extends StatefulWidget {
  const ExpenseListContent({super.key});

  @override
  State<ExpenseListContent> createState() => _ExpenseListContentState();
}

class _ExpenseListContentState extends State<ExpenseListContent> {
  List expenses = [];

  List filteredExpenses = [];

  TextEditingController searchController = TextEditingController();

  final ScrollController scrollController = ScrollController();

  bool isLoading = true;

  int currentPage = 1;

  bool hasMore = true;

  bool isFetchingMore = false;

  double totalAmount = 0;

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

        filteredExpenses = expenses;

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

  void searchExpenses(String query) {
    final results = expenses.where((expense) {
      final title = expense['title'].toString().toLowerCase();

      return title.contains(query.toLowerCase());
    }).toList();

    setState(() {
      filteredExpenses = results;
    });
  }

  @override
  void dispose() {
    scrollController.dispose();

    searchController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return isLoading
        ? const LoadingWidget()
        : expenses.isEmpty
        ? const Center(child: Text('No expenses found'))
        : Column(
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 20, 20, 5),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Expenses",
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    SizedBox(height: 6),

                    Text(
                      "Track and manage your spending",
                      style: TextStyle(color: Colors.grey, fontSize: 15),
                    ),
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                child: Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
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
              ),

              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 8,
                ),
                child: TextField(
                  controller: searchController,
                  onChanged: searchExpenses,
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

              const SizedBox(height: 10),

              Expanded(
                child: ListView.builder(
                  controller: scrollController,

                  itemCount: filteredExpenses.length + (hasMore ? 1 : 0),

                  itemBuilder: (context, index) {
                    if (index == filteredExpenses.length) {
                      return const Padding(
                        padding: EdgeInsets.all(20),

                        child: Center(child: CircularProgressIndicator()),
                      );
                    }

                    final expense = filteredExpenses[index];

                    return Card(
                      elevation: 3,

                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      margin: const EdgeInsets.all(10),

                      child: Padding(
                        padding: const EdgeInsets.all(10),

                        child: ListTile(
                          title: Text(expense['title']),

                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,

                            children: [
                              Text('Category: ${expense['category']}'),

                              Text('Date: ${expense['expense_date']}'),
                            ],
                          ),

                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,

                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit),

                                onPressed: () async {
                                  final result = await Navigator.push(
                                    context,

                                    MaterialPageRoute(
                                      builder: (context) =>
                                          EditExpenseScreen(expense: expense),
                                    ),
                                  );

                                  if (result == true) {
                                    expenses.clear();

                                    filteredExpenses.clear();

                                    currentPage = 1;

                                    hasMore = true;

                                    fetchExpenses();
                                  }
                                },
                              ),

                              IconButton(
                                icon: const Icon(Icons.delete),

                                onPressed: () async {
                                  await ApiService.deleteExpense(expense['id']);

                                  expenses.removeAt(index);

                                  filteredExpenses = expenses;

                                  setState(() {});

                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Expense deleted'),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
  }
}
