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

  bool isLoading = true;

  @override
  void initState() {
    super.initState();

    fetchExpenses();
  }

  Future<void> fetchExpenses() async {
    try {
      final data = await ApiService.getExpenses();

      setState(() {
        expenses = data;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Expenses')),

      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : expenses.isEmpty
          ? const Center(child: Text('No expenses found'))
          : ListView.builder(
              itemCount: expenses.length,

              itemBuilder: (context, index) {
                final expense = expenses[index];

                return Card(
                  margin: const EdgeInsets.all(10),

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
                              fetchExpenses();
                            }
                          },
                        ),

                        IconButton(
                          icon: const Icon(Icons.delete),

                          onPressed: () async {
                            await ApiService.deleteExpense(expense['id']);

                            fetchExpenses();

                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Expense deleted')),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
