import 'package:flutter/material.dart';

import '../services/api_services.dart';
import 'edit_expense_screen.dart';

class ExpenseListScreen extends StatefulWidget {
  const ExpenseListScreen({super.key});

  @override
  State<ExpenseListScreen> createState() => _ExpenseListScreenState();
}

class _ExpenseListScreenState extends State<ExpenseListScreen> {
  List expenses = [];

  List filteredExpenses = [];

  TextEditingController searchController = TextEditingController();

  final ScrollController scrollController = ScrollController();

  bool isLoading = true;

  int currentPage = 1;

  bool hasMore = true;

  bool isFetchingMore = false;

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

      final List newExpenses = response['data'];

      setState(() {
        expenses.addAll(newExpenses);

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
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.receipt_long),

            const SizedBox(width: 10),

            const Text('My Expenses'),
          ],
        ),
      ),

      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : expenses.isEmpty
          ? const Center(child: Text('No expenses found'))
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(10),

                  child: TextField(
                    controller: searchController,

                    onChanged: searchExpenses,

                    decoration: const InputDecoration(
                      hintText: 'Search expenses...',

                      prefixIcon: Icon(Icons.search),

                      border: OutlineInputBorder(),
                    ),
                  ),
                ),

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
                                    await ApiService.deleteExpense(
                                      expense['id'],
                                    );

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
            ),
    );
  }
}
