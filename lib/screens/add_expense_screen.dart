import 'package:flutter/material.dart';

import '../widgets/custom_button.dart';
import '../widgets/input_icon_badge.dart';
import '../widgets/app/adaptive_app_bar.dart';
import '../widgets/app/app_scaffold.dart';

import '../utils/responsive_helper.dart';

import '../services/notification_service.dart';
import '../repositories/expense_repository.dart';
import '../services/sync_service.dart';

class AddExpenseScreen extends StatefulWidget {
  const AddExpenseScreen({super.key});

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final TextEditingController titleController = TextEditingController();

  final TextEditingController amountController = TextEditingController();

  final TextEditingController categoryController = TextEditingController();

  final TextEditingController descriptionController = TextEditingController();

  final TextEditingController dateController = TextEditingController();

  final _formKey = GlobalKey<FormState>();

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

  String selectedCategory = 'Food';

  bool isLoading = false;

  void addExpense() async {
    if (!_formKey.currentState!.validate()) return;
    if (isLoading) return;

    setState(() => isLoading = true);

    final repository = ExpenseRepository();

    try {
      await repository.createExpense(
        title: titleController.text.trim(),
        amount: amountController.text.trim(),
        category: selectedCategory,
        expenseDate: dateController.text.trim(),
        description: descriptionController.text.trim(),
      );

      // Trigger sync in background (don’t block UI)
      SyncService.instance.getPendingChanges();

      // Budget alerts can also run in background
      NotificationService.checkBudgetAlerts();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(20),
          duration: const Duration(seconds: 2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          backgroundColor: Colors.green.shade600,
          content: const Row(
            children: [
              Icon(Icons.check_circle_rounded, color: Colors.white),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  "Expense saved successfully!",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      );

      Navigator.pop(context, true); // return flag to trigger refresh
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error saving expense: $e")));
      setState(() => isLoading = false);
    }
  }

  Future<void> pickExpenseDate() async {
    final now = DateTime.now();

    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: now,
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

  void clearForm() {
    titleController.clear();

    amountController.clear();

    descriptionController.clear();

    dateController.clear();

    selectedCategory = "Food";
  }

  @override
  void initState() {
    super.initState();

    final now = DateTime.now();

    dateController.text =
        "${now.year}-"
        "${now.month.toString().padLeft(2, '0')}-"
        "${now.day.toString().padLeft(2, '0')}";
  }

  @override
  void dispose() {
    titleController.dispose();
    amountController.dispose();
    categoryController.dispose();
    descriptionController.dispose();
    dateController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final compact = ResponsiveHelper.useCompactLayout(context);
    final landscape = ResponsiveHelper.isLandscape(context);
    final spacing = ResponsiveHelper.spacing(context);
    final cardPadding = ResponsiveHelper.cardPadding(context);
    final horizontalPadding = ResponsiveHelper.horizontalPadding(context);

    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;
    final surfaceContainer = theme.colorScheme.surfaceContainerHighest;

    final titleFontSize = compact
        ? 24.0
        : landscape
        ? 28.0
        : 30.0;
    final subtitleFontSize = compact ? 14.0 : 15.0;

    final sectionSpacing = compact ? 16.0 : 24.0;
    final fieldSpacing = compact ? 16.0 : 24.0;
    final cardRadius = compact ? 16.0 : 20.0;

    return AppScaffold(
      showOfflineBanner: true,
      showSyncIcon: true,

      appBar: const AdaptiveAppBar(
        titleWidget: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.receipt_long_rounded),
            SizedBox(width: 8),
            Text("Add Expense", style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      ),

      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SafeArea(
          child: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: horizontalPadding,
                vertical: compact ? 12 : 20,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: landscape ? 800 : 700),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Record a new expense",
                        style: TextStyle(
                          fontSize: titleFontSize,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      SizedBox(height: spacing * 0.4),

                      Text(
                        "Keep your spending up to date.",
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: subtitleFontSize,
                        ),
                      ),

                      SizedBox(height: sectionSpacing),

                      Row(
                        children: [
                          InputIconBadge(
                            icon: Icons.receipt_long_rounded,
                            color: primaryColor,
                          ),
                          SizedBox(width: spacing * 0.5),
                          Text(
                            "Expense Details",
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: spacing * 0.7),

                      Form(
                        key: _formKey,
                        child: Card(
                          elevation: 1.5,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(cardRadius),
                          ),
                          child: Padding(
                            padding: EdgeInsets.all(cardPadding),
                            child: Column(
                              children: [
                                // ─────────────────────────────
                                // EXPENSE TITLE
                                // ─────────────────────────────
                                TextFormField(
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return "Please enter an expense title";
                                    }

                                    if (value.trim().length < 3) {
                                      return "Title is too short";
                                    }

                                    return null;
                                  },
                                  textInputAction: TextInputAction.next,
                                  controller: titleController,
                                  decoration: InputDecoration(
                                    labelText: "Expense Title",
                                    hintText: "e.g. Grocery Shopping",
                                    prefixIcon: InputIconBadge(
                                      icon: Icons.edit_note_rounded,
                                      color: primaryColor,
                                    ),
                                    filled: true,
                                    fillColor: surfaceContainer,
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
                                        color: primaryColor,
                                        width: 1.5,
                                      ),
                                    ),
                                  ),
                                ),

                                SizedBox(height: fieldSpacing),

                                // ─────────────────────────────
                                // AMOUNT
                                // ─────────────────────────────
                                TextFormField(
                                  controller: amountController,
                                  textInputAction: TextInputAction.next,
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                        decimal: true,
                                      ),
                                  decoration: InputDecoration(
                                    labelText: "Amount",
                                    hintText: "Enter amount",
                                    prefixText: "KES ",
                                    prefixIcon: const InputIconBadge(
                                      icon: Icons.payments_rounded,
                                      color: Colors.green,
                                    ),
                                    filled: true,
                                    fillColor: surfaceContainer,
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
                                        color: primaryColor,
                                      ),
                                    ),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return "Please enter an amount";
                                    }

                                    final amount = double.tryParse(value);

                                    if (amount == null) {
                                      return "Enter a valid number";
                                    }

                                    if (amount <= 0) {
                                      return "Amount must be greater than zero";
                                    }

                                    return null;
                                  },
                                ),

                                SizedBox(height: spacing * 0.5),

                                // ─────────────────────────────
                                // QUICK AMOUNT CHIPS
                                // ─────────────────────────────
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: Wrap(
                                    spacing: compact ? 8 : 10,
                                    runSpacing: compact ? 8 : 10,
                                    children: [100, 200, 500, 1000, 2000].map((
                                      amount,
                                    ) {
                                      return ActionChip(
                                        label: Text("KES $amount"),
                                        onPressed: () {
                                          amountController.text = amount
                                              .toString();
                                        },
                                      );
                                    }).toList(),
                                  ),
                                ),

                                SizedBox(height: fieldSpacing),

                                // ─────────────────────────────
                                // CATEGORY
                                // ─────────────────────────────
                                DropdownButtonFormField<String>(
                                  value: selectedCategory,
                                  decoration: InputDecoration(
                                    labelText: "Category",
                                    prefixIcon: InputIconBadge(
                                      icon: categoryIcons[selectedCategory]!,
                                      color: categoryColors[selectedCategory]!,
                                    ),
                                    filled: true,
                                    fillColor: surfaceContainer,
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
                                        color: primaryColor,
                                      ),
                                    ),
                                  ),
                                  items: categories.map((category) {
                                    return DropdownMenuItem<String>(
                                      value: category,
                                      child: Row(
                                        children: [
                                          InputIconBadge(
                                            icon: categoryIcons[category]!,
                                            color: categoryColors[category]!,
                                          ),
                                          SizedBox(width: spacing * 0.5),
                                          Text(category),
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

                                SizedBox(height: fieldSpacing),

                                // ─────────────────────────────
                                // DATE
                                // ─────────────────────────────
                                TextFormField(
                                  textInputAction: TextInputAction.next,
                                  controller: dateController,
                                  readOnly: true,
                                  onTap: pickExpenseDate,
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
                                    fillColor: surfaceContainer,
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
                                        color: primaryColor,
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

                                SizedBox(height: fieldSpacing),

                                // ─────────────────────────────
                                // ADDITIONAL NOTES
                                // ─────────────────────────────
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: Row(
                                    children: [
                                      const InputIconBadge(
                                        icon: Icons.sticky_note_2_rounded,
                                        color: Colors.blue,
                                      ),
                                      SizedBox(width: spacing * 0.5),
                                      Text(
                                        "Additional Notes",
                                        style: theme.textTheme.titleSmall
                                            ?.copyWith(
                                              fontWeight: FontWeight.w600,
                                            ),
                                      ),
                                    ],
                                  ),
                                ),

                                SizedBox(height: spacing * 0.5),

                                TextFormField(
                                  textInputAction: TextInputAction.done,
                                  controller: descriptionController,
                                  maxLines: compact ? 4 : 5,
                                  maxLength: 250,
                                  decoration: InputDecoration(
                                    labelText: "Description",
                                    hintText: "Optional notes...",
                                    prefixIcon: Padding(
                                      padding: EdgeInsets.only(
                                        bottom: compact ? 45 : 60,
                                      ),
                                      child: const InputIconBadge(
                                        icon: Icons.notes_rounded,
                                        color: Colors.blue,
                                      ),
                                    ),
                                    alignLabelWithHint: true,
                                    filled: true,
                                    fillColor: surfaceContainer,
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
                                        color: primaryColor,
                                      ),
                                    ),
                                  ),
                                  validator: (value) {
                                    if (value != null && value.length > 250) {
                                      return "Maximum 250 characters";
                                    }

                                    return null;
                                  },
                                ),

                                SizedBox(height: compact ? 24 : 36),

                                // ─────────────────────────────
                                // SAVE BUTTON
                                // ─────────────────────────────
                                AnimatedScale(
                                  duration: const Duration(milliseconds: 180),
                                  scale: isLoading ? 0.97 : 1,
                                  curve: Curves.easeOut,
                                  child: SizedBox(
                                    width: double.infinity,
                                    height: compact ? 52 : 56,
                                    child: CustomButton(
                                      text: "Save Expense",
                                      isLoading: isLoading,
                                      onPressed: isLoading ? null : addExpense,
                                    ),
                                  ),
                                ),

                                SizedBox(height: spacing),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
