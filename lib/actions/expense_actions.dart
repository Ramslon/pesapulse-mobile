import 'package:flutter/material.dart';

import '../screens/edit_expense_screen.dart';
import '../screens/expense_details_screen.dart';

class ExpenseActions {
  ExpenseActions._();

  static Future<bool?> editExpense(
    BuildContext context,
    Map<String, dynamic> expense,
  ) {
    return Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => EditExpenseScreen(expense: expense)),
    );
  }

  static Future<bool?> duplicateExpense(
    BuildContext context,
    Map<String, dynamic> expense,
  ) {
    // Temporary behavior:
    // Opens the expense details screen.
    return Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => ExpenseDetailsScreen(expense: expense)),
    );
  }

  static Future<void> deleteExpense({
    required BuildContext context,
    required VoidCallback onDeleteLocally,
    required VoidCallback onUndo,
    required Future<void> Function() onDeletePermanently,
  }) async {
    onDeleteLocally();

    bool undoPressed = false;

    await ScaffoldMessenger.of(context)
        .showSnackBar(
          SnackBar(
            duration: const Duration(seconds: 5),
            content: const Text("Expense deleted"),
            action: SnackBarAction(
              label: "UNDO",
              onPressed: () {
                undoPressed = true;
                onUndo();
              },
            ),
          ),
        )
        .closed;

    if (!undoPressed) {
      await onDeletePermanently();
    }
  }
}
