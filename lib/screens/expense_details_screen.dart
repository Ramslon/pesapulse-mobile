import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../screens/edit_expense_screen.dart';
import '../repositories/expense_repository.dart';
import '../widgets/app/adaptive_app_bar.dart';
import '../widgets/app/app_scaffold.dart';
import '../utils/responsive_helper.dart';

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
    required double cardPadding,
    required double iconContainerSize,
    required double iconSize,
    required double titleFontSize,
    required double valueFontSize,
    required double spacing,
  }) {
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.surfaceContainerLowest,
      margin: EdgeInsets.only(bottom: spacing),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(
          ResponsiveHelper.useCompactLayout(context) ? 15 : 18,
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(cardPadding),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: iconContainerSize,
              height: iconContainerSize,
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(.10),
                borderRadius: BorderRadius.circular(
                  ResponsiveHelper.useCompactLayout(context) ? 12 : 14,
                ),
              ),
              child: Icon(icon, color: primaryColor, size: iconSize),
            ),

            SizedBox(width: spacing),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: titleFontSize,
                      fontWeight: FontWeight.w500,
                    ),
                  ),

                  SizedBox(height: spacing * .4),

                  Text(
                    value,
                    style: TextStyle(
                      fontSize: valueFontSize,
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
    final compact = ResponsiveHelper.useCompactLayout(context);
    final landscape = ResponsiveHelper.isLandscape(context);

    final spacing = ResponsiveHelper.spacing(context);
    final cardPadding = ResponsiveHelper.cardPadding(context);

    final horizontalPadding = compact
        ? ResponsiveHelper.horizontalPadding(context)
        : landscape
        ? 28.0
        : 24.0;

    final category = expense["category"] ?? "Other";
    final categoryAccent = categoryColor(category);

    final amount = double.tryParse(expense["amount"].toString()) ?? 0;

    final title = expense["title"]?.toString() ?? "";

    final description =
        expense["description"] == null ||
            expense["description"].toString().trim().isEmpty
        ? "No description"
        : expense["description"].toString();

    final formattedDate = formatDate(expense["expense_date"].toString());

    final avatarRadius = compact
        ? 38.0
        : landscape
        ? 48.0
        : 46.0;

    final categoryIconSize = compact
        ? 34.0
        : landscape
        ? 44.0
        : 42.0;

    final amountFontSize = compact
        ? 28.0
        : landscape
        ? 38.0
        : 36.0;

    final categoryFontSize = compact ? 12.0 : 14.0;

    final dateFontSize = compact ? 13.0 : 15.0;

    final infoTitleFontSize = compact ? 11.0 : 13.0;

    final infoValueFontSize = compact ? 14.0 : 16.0;

    final infoIconContainerSize = compact ? 42.0 : 46.0;

    final infoIconSize = compact ? 19.0 : 21.0;

    return AppScaffold(
      showOfflineBanner: true,
      showSyncIcon: true,

      appBar: const AdaptiveAppBar(
        titleWidget: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.receipt_long_rounded),
            SizedBox(width: 8),
            Text(
              "Expense Details",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),

      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          horizontalPadding,
          compact ? 18 : 24,
          horizontalPadding,
          compact ? 18 : 24,
        ),
        child: Column(
          children: [
            SizedBox(height: compact ? 8 : 20),

            Hero(
              tag: "expense_${expense["id"]}",
              child: CircleAvatar(
                radius: avatarRadius,
                backgroundColor: categoryAccent.withOpacity(.12),
                child: Icon(
                  categoryIcon(category),
                  color: categoryAccent,
                  size: categoryIconSize,
                ),
              ),
            ),

            SizedBox(height: compact ? 16 : 20),

            TweenAnimationBuilder<double>(
              duration: const Duration(milliseconds: 900),
              tween: Tween(begin: 0, end: amount),
              builder: (context, value, child) {
                return Text(
                  "KES ${currencyFormatter.format(value)}",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: amountFontSize,
                    fontWeight: FontWeight.bold,
                    letterSpacing: .3,
                  ),
                );
              },
            ),

            SizedBox(height: compact ? 8 : 10),

            Container(
              padding: EdgeInsets.symmetric(
                horizontal: compact ? 13 : 16,
                vertical: compact ? 6 : 8,
              ),
              decoration: BoxDecoration(
                color: categoryAccent.withOpacity(.12),
                borderRadius: BorderRadius.circular(30),
              ),
              child: Text(
                category,
                style: TextStyle(
                  color: categoryAccent,
                  fontWeight: FontWeight.w600,
                  fontSize: categoryFontSize,
                ),
              ),
            ),

            SizedBox(height: compact ? 8 : 12),

            Text(
              formattedDate,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: dateFontSize,
              ),
            ),

            SizedBox(height: compact ? 20 : 28),

            Divider(thickness: 1, color: Colors.grey.shade300),

            SizedBox(height: compact ? 18 : 24),

            buildInfoCard(
              icon: Icons.title,
              title: "Expense Title",
              value: title,
              cardPadding: cardPadding,
              iconContainerSize: infoIconContainerSize,
              iconSize: infoIconSize,
              titleFontSize: infoTitleFontSize,
              valueFontSize: infoValueFontSize,
              spacing: spacing,
            ),

            buildInfoCard(
              icon: Icons.category,
              title: "Category",
              value: category,
              cardPadding: cardPadding,
              iconContainerSize: infoIconContainerSize,
              iconSize: infoIconSize,
              titleFontSize: infoTitleFontSize,
              valueFontSize: infoValueFontSize,
              spacing: spacing,
            ),

            buildInfoCard(
              icon: Icons.calendar_today,
              title: "Expense Date",
              value: formattedDate,
              cardPadding: cardPadding,
              iconContainerSize: infoIconContainerSize,
              iconSize: infoIconSize,
              titleFontSize: infoTitleFontSize,
              valueFontSize: infoValueFontSize,
              spacing: spacing,
            ),

            buildInfoCard(
              icon: Icons.notes,
              title: "Description",
              value: description,
              cardPadding: cardPadding,
              iconContainerSize: infoIconContainerSize,
              iconSize: infoIconSize,
              titleFontSize: infoTitleFontSize,
              valueFontSize: infoValueFontSize,
              spacing: spacing,
            ),

            SizedBox(height: compact ? 8 : 12),
          ],
        ),
      ),

      bottomNavigationBar: SafeArea(
        minimum: EdgeInsets.fromLTRB(
          horizontalPadding,
          compact ? 10 : 16,
          horizontalPadding,
          compact ? 10 : 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: double.infinity,
              height: compact ? 50 : 56,
              child: FilledButton.icon(
                icon: Icon(Icons.edit, size: compact ? 19 : 22),
                label: Text(
                  "Edit Expense",
                  style: TextStyle(fontSize: compact ? 13 : 15),
                ),
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

            SizedBox(height: compact ? 8 : 12),

            SizedBox(
              width: double.infinity,
              height: compact ? 50 : 56,
              child: OutlinedButton.icon(
                icon: Icon(
                  Icons.delete,
                  color: Colors.red,
                  size: compact ? 19 : 22,
                ),
                label: Text(
                  "Delete Expense",
                  style: TextStyle(
                    color: Colors.red,
                    fontSize: compact ? 13 : 15,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.red),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(compact ? 15 : 18),
                  ),
                ),
                onPressed: _confirmDelete,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
