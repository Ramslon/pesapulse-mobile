import 'package:intl/intl.dart';

class ExpenseDateUtils {
  static Map<String, List<Map<String, dynamic>>> groupExpensesByDate(
    List<Map<String, dynamic>> expenses,
  ) {
    final Map<String, List<Map<String, dynamic>>> grouped = {};

    for (final expense in expenses) {
      final rawDate = expense["expense_date"];

      if (rawDate == null) continue;

      final date = DateTime.tryParse(rawDate.toString());

      if (date == null) continue;

      final now = DateTime.now();

      final difference = now.difference(date).inDays;

      String label;

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

  static String formatDate(String date) {
    final expenseDate = DateTime.parse(date);

    final today = DateTime.now();

    final difference = today.difference(expenseDate).inDays;

    if (difference == 0) return "Today";

    if (difference == 1) return "Yesterday";

    return "${expenseDate.day}/${expenseDate.month}/${expenseDate.year}";
  }
}
