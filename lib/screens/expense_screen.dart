import 'package:flutter/material.dart';

import 'expense_list_content.dart';
import 'add_expense_screen.dart';

class ExpenseScreen extends StatefulWidget {
  const ExpenseScreen({super.key});

  @override
  State<ExpenseScreen> createState() => _ExpenseScreenState();
}

class _ExpenseScreenState extends State<ExpenseScreen> {
  final GlobalKey<ExpenseListContentState> _expenseListKey = GlobalKey();

  void _handleAddExpense() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddExpenseScreen()),
    );

    if (result == true) {
      _expenseListKey.currentState?.refreshExpenses();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        heroTag: "expenseFab",
        elevation: 4,
        icon: const Icon(Icons.receipt_long_outlined),
        label: const Text(
          "New Expense",
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        onPressed: _handleAddExpense,
      ),
      body: SafeArea(child: ExpenseListContent(key: _expenseListKey)),
    );
  }
}
