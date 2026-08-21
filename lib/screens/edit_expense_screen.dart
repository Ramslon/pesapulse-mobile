import 'package:flutter/material.dart';

import 'package:intl/intl.dart';
import '../widgets/input_icon_badge.dart';
import '../widgets/app/adaptive_app_bar.dart';
import '../widgets/app/app_scaffold.dart';
import '../repositories/expense_repository.dart';
import '../services/sync_service.dart';
import '../utils/responsive_helper.dart';
import '../utils/snackbar_helper.dart';
import '../core/utils/currency_formatter.dart';

class EditExpenseScreen extends StatefulWidget {
  final Map expense;

  const EditExpenseScreen({super.key, required this.expense});

  @override
  State<EditExpenseScreen> createState() => _EditExpenseScreenState();
}

class _EditExpenseScreenState extends State<EditExpenseScreen> {
  final ExpenseRepository repository = ExpenseRepository();

  late TextEditingController titleController;

  late TextEditingController amountController;

  late TextEditingController dateController;

  late TextEditingController descriptionController;

  bool isLoading = false;

  final DateFormat dateFormatter = DateFormat("dd MMM yyyy");

  List<String> categories = [
    'Food',
    'Transport',
    'Shopping',
    'Bills',
    'Entertainment',
    'Health',
    'Education',
    'Other',
  ];

  final Map<String, IconData> categoryIcons = {
    'Food': Icons.restaurant,
    'Transport': Icons.directions_car,
    'Shopping': Icons.shopping_bag,
    'Bills': Icons.receipt_long,
    'Entertainment': Icons.movie,
    'Health': Icons.favorite,
    'Education': Icons.school,
    'Other': Icons.category,
  };

  final Map<String, Color> categoryColors = {
    'Food': Colors.orange,
    'Transport': Colors.blue,
    'Shopping': Colors.purple,
    'Bills': Colors.red,
    'Entertainment': Colors.pink,
    'Health': Colors.green,
    'Education': Colors.indigo,
    'Other': Colors.grey,
  };

  late String selectedCategory;

  @override
  void initState() {
    super.initState();

    selectedCategory = widget.expense['category'];

    titleController = TextEditingController(text: widget.expense['title']);

    amountController = TextEditingController(
      text: widget.expense['amount'].toString(),
    );

    dateController = TextEditingController(
      text: widget.expense['expense_date'],
    );

    descriptionController = TextEditingController(
      text: widget.expense['description'] ?? '',
    );

    titleController.addListener(() => setState(() {}));

    amountController.addListener(() => setState(() {}));

    dateController.addListener(() {
      setState(() {});
    });

    descriptionController.addListener(() {
      setState(() {});
    });
  }

  bool get isFormValid {
    final amount = double.tryParse(amountController.text);

    return titleController.text.trim().length >= 3 &&
        amount != null &&
        amount > 0 &&
        selectedCategory.isNotEmpty &&
        dateController.text.isNotEmpty;
  }

  void updateExpense() async {
    if (!isFormValid) {
      SnackbarHelper.showError(
        context,
        "Please complete all required fields correctly.",
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      await repository.updateExpense(
        id: widget.expense["id"],
        title: titleController.text.trim(),
        amount: amountController.text.trim(),
        category: selectedCategory,
        expenseDate: dateController.text.trim(),
        description: descriptionController.text.trim(),
      );

      await SyncService.instance.getPendingChanges();

      if (!mounted) return;

      setState(() => isLoading = false);

      SnackbarHelper.showSuccess(context, "Expense updated successfully!");

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      setState(() => isLoading = false);

      SnackbarHelper.showError(context, "Error updating expense: $e");
    }
  }

  Future<void> pickExpenseDate() async {
    final now = DateTime.now();

    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.tryParse(dateController.text) ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(now.year + 5),
      helpText: "Select Expense Date",
      cancelText: "Cancel",
      confirmText: "Select",
    );

    if (pickedDate != null) {
      dateController.text =
          "${pickedDate.year}-"
          "${pickedDate.month.toString().padLeft(2, '0')}-"
          "${pickedDate.day.toString().padLeft(2, '0')}";
    }
  }

  Widget buildExpensePreview() {
    final compact = ResponsiveHelper.useCompactLayout(context);
    final spacing = ResponsiveHelper.spacing(context);
    final cardPadding = ResponsiveHelper.cardPadding(context);

    final title = titleController.text.trim().isEmpty
        ? "Expense Title"
        : titleController.text.trim();

    final amount = double.tryParse(amountController.text) ?? 0;

    final parsedDate = DateTime.tryParse(dateController.text);

    final date = parsedDate == null
        ? "No Date"
        : dateFormatter.format(parsedDate);

    final titleFontSize = compact ? 18.0 : 22.0;
    final amountFontSize = compact ? 24.0 : 28.0;
    final subtitleFontSize = compact ? 12.0 : 13.0;
    final previewValuePadding = compact ? 11.0 : 14.0;

    return Card(
      elevation: 1.5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(compact ? 16 : 20),
      ),
      child: Padding(
        padding: EdgeInsets.all(cardPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                InputIconBadge(
                  icon: categoryIcons[selectedCategory]!,
                  color: categoryColors[selectedCategory]!,
                ),
                SizedBox(width: spacing),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Expense Preview",
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                              fontSize: compact ? 16 : null,
                            ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        "Live preview of your expense",
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: subtitleFontSize,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            SizedBox(height: compact ? 18 : 22),

            Text(
              title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: titleFontSize,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              CurrencyFormatter.format(amount),
              style: TextStyle(
                fontSize: amountFontSize,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),

            SizedBox(height: compact ? 16 : 20),

            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: EdgeInsets.all(previewValuePadding),
                    decoration: BoxDecoration(
                      color: categoryColors[selectedCategory]!.withOpacity(.12),
                      borderRadius: BorderRadius.circular(compact ? 12 : 14),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          categoryIcons[selectedCategory],
                          color: categoryColors[selectedCategory],
                          size: compact ? 18 : 20,
                        ),
                        SizedBox(width: compact ? 6 : 8),
                        Expanded(
                          child: Text(
                            selectedCategory,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: compact ? 12 : 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                SizedBox(width: compact ? 8 : 12),

                Expanded(
                  child: Container(
                    padding: EdgeInsets.all(previewValuePadding),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(.12),
                      borderRadius: BorderRadius.circular(compact ? 12 : 14),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.calendar_today_rounded,
                          color: Colors.orange,
                          size: compact ? 18 : 20,
                        ),
                        SizedBox(width: compact ? 6 : 8),
                        Expanded(
                          child: Text(
                            date,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: compact ? 12 : 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            if (descriptionController.text.trim().isNotEmpty) ...[
              SizedBox(height: compact ? 14 : 18),
              Divider(color: Colors.grey.shade300),
              SizedBox(height: compact ? 10 : 12),
              Text(
                "Notes",
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: compact ? 13 : null,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                descriptionController.text.trim(),
                style: TextStyle(
                  color: Colors.grey.shade700,
                  height: 1.4,
                  fontSize: compact ? 12 : 14,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget buildInputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    String? prefixText,
    String? hintText,
    int maxLines = 1,
    TextInputAction textInputAction = TextInputAction.next,
    bool readOnly = false,
    VoidCallback? onTap,
  }) {
    final compact = ResponsiveHelper.useCompactLayout(context);
    final fieldRadius = compact ? 13.0 : 16.0;

    return Padding(
      padding: EdgeInsets.only(bottom: ResponsiveHelper.spacing(context)),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        textInputAction: textInputAction,
        maxLines: maxLines,
        readOnly: readOnly,
        onTap: onTap,
        style: TextStyle(fontSize: compact ? 14 : 16),
        decoration: InputDecoration(
          labelText: label,
          hintText: hintText,
          prefixText: prefixText,
          labelStyle: TextStyle(fontSize: compact ? 13 : 14),
          hintStyle: TextStyle(fontSize: compact ? 13 : 14),
          prefixIcon: InputIconBadge(
            icon: icon,
            color: Theme.of(context).colorScheme.primary,
          ),
          filled: true,
          fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
          contentPadding: EdgeInsets.symmetric(
            horizontal: compact ? 12 : 16,
            vertical: compact ? 13 : 16,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(fieldRadius),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(fieldRadius),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(fieldRadius),
            borderSide: BorderSide(
              color: Theme.of(context).colorScheme.primary,
              width: 1.5,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final compact = ResponsiveHelper.useCompactLayout(context);
    final landscape = ResponsiveHelper.isLandscape(context);

    final spacing = ResponsiveHelper.spacing(context);
    final sectionSpacing = ResponsiveHelper.sectionSpacing(context);

    final horizontalPadding = compact
        ? 14.0
        : landscape
        ? 24.0
        : ResponsiveHelper.horizontalPadding(context);

    final titleFontSize = compact ? 24.0 : 32.0;
    final descriptionFontSize = compact ? 13.0 : 15.0;
    final cardRadius = compact ? 16.0 : 20.0;
    final cardPadding = ResponsiveHelper.cardPadding(context);

    return AppScaffold(
      showOfflineBanner: true,
      showSyncIcon: true,

      appBar: AdaptiveAppBar(
        titleWidget: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.edit_note_rounded, size: compact ? 21 : 24),
            SizedBox(width: compact ? 6 : 8),
            Text(
              "Edit Expense",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: compact ? 16 : 18,
              ),
            ),
          ],
        ),
      ),

      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SafeArea(
          child: ListView(
            padding: EdgeInsets.fromLTRB(
              horizontalPadding,
              compact ? 16 : 28,
              horizontalPadding,
              compact ? 20 : 24,
            ),
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            children: [
              Text(
                "Edit Expense",
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: titleFontSize,
                ),
              ),

              SizedBox(height: compact ? 6 : 8),

              Text(
                "Update your expense details and keep your spending records accurate.",
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: descriptionFontSize,
                  height: 1.4,
                ),
              ),

              SizedBox(height: compact ? 18 : 28),

              Card(
                elevation: 0,
                color: Colors.blue.withOpacity(.08),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(compact ? 14 : 18),
                ),
                child: Padding(
                  padding: EdgeInsets.all(compact ? 14 : 18),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.lightbulb_outline,
                        color: Colors.blue,
                        size: compact ? 20 : 24,
                      ),
                      SizedBox(width: compact ? 8 : 12),
                      Expanded(
                        child: Text(
                          "Update your expense information to keep your spending history accurate.",
                          style: TextStyle(
                            color: Colors.grey.shade700,
                            height: 1.4,
                            fontSize: compact ? 12 : 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              SizedBox(height: sectionSpacing),

              Row(
                children: [
                  CircleAvatar(
                    radius: compact ? 19 : 22,
                    backgroundColor: Colors.deepPurple.withOpacity(.15),
                    child: Icon(
                      Icons.receipt_long_outlined,
                      color: Colors.deepPurple,
                      size: compact ? 19 : 22,
                    ),
                  ),
                  SizedBox(width: compact ? 10 : 16),
                  Text(
                    "Expense Details",
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: compact ? 18 : 22,
                    ),
                  ),
                ],
              ),

              SizedBox(height: compact ? 14 : 18),

              buildExpensePreview(),

              SizedBox(height: sectionSpacing),

              Card(
                elevation: 1.5,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(cardRadius),
                ),
                child: Padding(
                  padding: EdgeInsets.all(cardPadding),
                  child: Column(
                    children: [
                      buildInputField(
                        controller: titleController,
                        label: "Expense Title",
                        hintText: "e.g. Grocery Shopping",
                        icon: Icons.edit_note_rounded,
                      ),

                      buildInputField(
                        controller: amountController,
                        label: "Amount",
                        hintText: "Enter amount",
                        prefixText: "KES ",
                        icon: Icons.payments_rounded,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                      ),

                      DropdownButtonFormField<String>(
                        value: selectedCategory,
                        isExpanded: true,
                        decoration: InputDecoration(
                          labelText: "Category",
                          prefixIcon: InputIconBadge(
                            icon: categoryIcons[selectedCategory]!,
                            color: categoryColors[selectedCategory]!,
                          ),
                          filled: true,
                          fillColor: Theme.of(
                            context,
                          ).colorScheme.surfaceContainerHighest,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: compact ? 12 : 16,
                            vertical: compact ? 4 : 8,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(
                              compact ? 13 : 16,
                            ),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(
                              compact ? 13 : 16,
                            ),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(
                              compact ? 13 : 16,
                            ),
                            borderSide: BorderSide(
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ),
                        items: categories.map((category) {
                          return DropdownMenuItem(
                            value: category,
                            child: Row(
                              children: [
                                InputIconBadge(
                                  icon: categoryIcons[category]!,
                                  color: categoryColors[category]!,
                                ),
                                SizedBox(width: compact ? 6 : 10),
                                Text(
                                  category,
                                  style: TextStyle(fontSize: compact ? 13 : 15),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value == null) return;

                          setState(() {
                            selectedCategory = value;
                          });
                        },
                      ),

                      SizedBox(height: spacing),

                      TextFormField(
                        textInputAction: TextInputAction.next,
                        controller: dateController,
                        readOnly: true,
                        onTap: pickExpenseDate,
                        style: TextStyle(fontSize: compact ? 14 : 16),
                        decoration: InputDecoration(
                          labelText: "Expense Date",
                          hintText: "Select date",
                          prefixIcon: const InputIconBadge(
                            icon: Icons.calendar_month_rounded,
                            color: Colors.orange,
                          ),
                          suffixIcon: const Icon(
                            Icons.keyboard_arrow_down_rounded,
                          ),
                          filled: true,
                          fillColor: Theme.of(
                            context,
                          ).colorScheme.surfaceContainerHighest,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(
                              compact ? 13 : 16,
                            ),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(
                              compact ? 13 : 16,
                            ),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(
                              compact ? 13 : 16,
                            ),
                            borderSide: BorderSide(
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return "Select an expense date";
                          }

                          return null;
                        },
                      ),

                      SizedBox(height: spacing),

                      buildInputField(
                        controller: descriptionController,
                        label: "Description",
                        hintText: "Optional notes...",
                        icon: Icons.notes_rounded,
                        maxLines: compact ? 4 : 5,
                        textInputAction: TextInputAction.done,
                      ),

                      SizedBox(height: compact ? 12 : 24),

                      SizedBox(
                        width: double.infinity,
                        height: compact ? 52 : 56,
                        child: ElevatedButton.icon(
                          onPressed: isFormValid && !isLoading
                              ? updateExpense
                              : null,
                          icon: isLoading
                              ? SizedBox(
                                  width: compact ? 19 : 22,
                                  height: compact ? 19 : 22,
                                  child: const CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    color: Colors.white,
                                  ),
                                )
                              : Icon(
                                  Icons.check_circle_outline,
                                  size: compact ? 20 : 24,
                                ),
                          label: Text(
                            isLoading ? "Updating..." : "Update Expense",
                            style: TextStyle(
                              fontSize: compact ? 14 : 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                compact ? 15 : 18,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
