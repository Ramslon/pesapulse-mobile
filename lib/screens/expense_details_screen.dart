import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../screens/edit_expense_screen.dart';
import '../repositories/expense_repository.dart';

class ExpenseDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> expense;

  const ExpenseDetailsScreen({super.key, required this.expense});

  @override
  State<ExpenseDetailsScreen> createState() => _ExpenseDetailsScreenState();
}

class _ExpenseDetailsScreenState extends State<ExpenseDetailsScreen> {
  Map<String, dynamic> get expense => widget.expense;
  final NumberFormat currencyFormatter = NumberFormat("#,##0.00");

  final ExpenseRepository repository = ExpenseRepository();

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Delete Expense"),
        content: const Text(
          "Are you sure you want to permanently delete this expense?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),

          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Delete"),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await repository.deleteExpense(expense["id"]);

      if (!mounted) return;

      Navigator.pop(context, true);
    }
  }

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

  String formatDate(String date) {
    return DateFormat("dd MMMM yyyy").format(DateTime.parse(date));
  }

  Widget buildInfoCard({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.surfaceContainerLowest,
      margin: const EdgeInsets.only(bottom: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(.10),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: Theme.of(context).colorScheme.primary),
            ),

            const SizedBox(width: 16),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),

                  const SizedBox(height: 6),

                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Expense Details")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 20),

            Hero(
              tag: "expense_${expense["id"]}",
              child: CircleAvatar(
                radius: 46,
                backgroundColor: categoryColor(
                  expense["category"] ?? "Other",
                ).withOpacity(.12),
                child: Icon(
                  categoryIcon(expense["category"] ?? "Other"),
                  color: categoryColor(expense["category"] ?? "Other"),
                  size: 42,
                ),
              ),
            ),

            const SizedBox(height: 20),

            TweenAnimationBuilder<double>(
              duration: const Duration(milliseconds: 900),
              tween: Tween(
                begin: 0,
                end: double.tryParse(expense["amount"].toString()) ?? 0,
              ),
              builder: (context, value, child) {
                return Text(
                  "KES ${currencyFormatter.format(value)}",
                  style: const TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    letterSpacing: .3,
                  ),
                );
              },
            ),
            const SizedBox(height: 10),

            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: categoryColor(
                  expense["category"] ?? "Other",
                ).withOpacity(.12),
                borderRadius: BorderRadius.circular(30),
              ),
              child: Text(
                expense["category"] ?? "Other",
                style: TextStyle(
                  color: categoryColor(expense["category"] ?? "Other"),
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),

            const SizedBox(height: 12),

            Text(
              formatDate(expense["expense_date"]),
              style: TextStyle(color: Colors.grey.shade600, fontSize: 15),
            ),

            const SizedBox(height: 28),

            Divider(thickness: 1, color: Colors.grey.shade300),

            const SizedBox(height: 24),

            buildInfoCard(
              icon: Icons.title,
              title: "Expense Title",
              value: expense["title"] ?? "",
            ),

            buildInfoCard(
              icon: Icons.category,
              title: "Category",
              value: expense["category"] ?? "",
            ),

            buildInfoCard(
              icon: Icons.calendar_today,
              title: "Expense Date",
              value: formatDate(expense["expense_date"]),
            ),

            buildInfoCard(
              icon: Icons.notes,
              title: "Description",
              value:
                  (expense["description"] == null ||
                      expense["description"].toString().trim().isEmpty)
                  ? "No description"
                  : expense["description"],
            ),
          ],
        ),
      ),

      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                icon: const Icon(Icons.edit),
                label: const Text("Edit Expense"),
                onPressed: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => EditExpenseScreen(expense: expense),
                    ),
                  );

                  if (result == true && mounted) {
                    Navigator.pop(context, true);
                  }
                },
              ),
            ),

            const SizedBox(height: 12),

            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.delete, color: Colors.red),
                label: const Text(
                  "Delete Expense",
                  style: TextStyle(color: Colors.red),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.red),
                ),
                onPressed: () {
                  _confirmDelete();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
