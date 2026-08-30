import 'package:flutter/material.dart';

import '../screens/edit_expense_screen.dart';
import '../screens/expense_details_screen.dart';
import '../exceptions/rate_limit_exception.dart';
import '../utils/snackbar_helper.dart';

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
      try {
        await onDeletePermanently();
      } on RateLimitException catch (e) {
        debugPrint('Expense deletion rate limit: ${e.message}');

        if (!context.mounted) return;

        SnackbarHelper.showRateLimited(
          context,
          message: e.message,
          remaining: e.remaining,
          retryAfter: e.retryAfter,
        );
      } catch (e) {
        debugPrint('Error permanently deleting expense: $e');

        if (!context.mounted) return;

        SnackbarHelper.showError(
          context,
          'Failed to delete expense. Please try again.',
        );
      }
    }
  }
}
