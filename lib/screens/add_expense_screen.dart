import 'package:flutter/material.dart';

import '../widgets/custom_button.dart';
import '../widgets/input_icon_badge.dart';
import '../widgets/app/adaptive_app_bar.dart';
import '../widgets/app/app_scaffold.dart';

import '../utils/responsive_helper.dart';
import '../utils/snackbar_helper.dart';

import '../services/notification_service.dart';
import '../repositories/expense_repository.dart';
import '../services/sync_service.dart';

import '../exceptions/rate_limit_exception.dart';

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

  final List<String> categories = [
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
    'Food': Icons.restaurant_rounded,
    'Transport': Icons.directions_car_rounded,
    'Shopping': Icons.shopping_bag_rounded,
    'Bills': Icons.receipt_long_rounded,
    'Entertainment': Icons.movie_rounded,
    'Health': Icons.favorite_rounded,
    'Education': Icons.school_rounded,
    'Other': Icons.category_rounded,
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

  // ─────────────────────────────────────────────
  // SAVE EXPENSE
  // ─────────────────────────────────────────────

  Future<void> addExpense() async {
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

      // Trigger sync in background.
      SyncService.instance.getPendingChanges();

      // Budget alerts can also run in background.
      NotificationService.checkBudgetAlerts();

      if (!mounted) return;

      SnackbarHelper.showSuccess(context, 'Expense saved successfully!');

      Navigator.pop(context, true);
    } on RateLimitException catch (e) {
      debugPrint('Expense rate limit: ${e.message}');

      if (!mounted) return;

      setState(() => isLoading = false);

      SnackbarHelper.showRateLimited(
        context,
        message: e.message,
        remaining: e.remaining,
        retryAfter: e.retryAfter,
      );
    } catch (e) {
      debugPrint('Error saving expense: $e');

      if (!mounted) return;

      setState(() => isLoading = false);

      SnackbarHelper.showError(
        context,
        'We couldn’t save your expense. Please try again',
      );
    }
  }

  // ─────────────────────────────────────────────
  // DATE PICKER
  // ─────────────────────────────────────────────

  Future<void> pickExpenseDate() async {
    final now = DateTime.now();

    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(2020),
      lastDate: DateTime(now.year + 5),
      helpText: 'Select Expense Date',
      cancelText: 'Cancel',
      confirmText: 'Select',
    );

    if (pickedDate != null) {
      dateController.text =
          '${pickedDate.year}-'
          '${pickedDate.month.toString().padLeft(2, '0')}-'
          '${pickedDate.day.toString().padLeft(2, '0')}';
    }
  }

  // ─────────────────────────────────────────────
  // CLEAR FORM
  // ─────────────────────────────────────────────

  void clearForm() {
    titleController.clear();
    amountController.clear();
    categoryController.clear();
    descriptionController.clear();

    final now = DateTime.now();

    dateController.text =
        '${now.year}-'
        '${now.month.toString().padLeft(2, '0')}-'
        '${now.day.toString().padLeft(2, '0')}';

    setState(() {
      selectedCategory = 'Food';
    });
  }

  // ─────────────────────────────────────────────
  // INIT
  // ─────────────────────────────────────────────

  @override
  void initState() {
    super.initState();

    final now = DateTime.now();

    dateController.text =
        '${now.year}-'
        '${now.month.toString().padLeft(2, '0')}-'
        '${now.day.toString().padLeft(2, '0')}';
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

  // ─────────────────────────────────────────────
  // RESPONSIVE INPUT ICON
  // ─────────────────────────────────────────────

  Widget _buildInputIcon(
    BuildContext context, {
    required IconData icon,
    required Color color,
  }) {
    final compact = ResponsiveHelper.useCompactLayout(context);
    final landscape = ResponsiveHelper.isLandscape(context);
    final tablet = ResponsiveHelper.isTablet(context);
    final desktop = ResponsiveHelper.isDesktop(context);

    final iconSize = desktop
        ? 20.0
        : tablet
        ? 19.0
        : compact
        ? 15.0
        : landscape
        ? 16.0
        : 18.0;

    return InputIconBadge(icon: icon, color: color, size: iconSize);
  }

  // ─────────────────────────────────────────────
  // FIELD BORDER
  // ─────────────────────────────────────────────

  InputBorder _fieldBorder(
    BuildContext context, {
    required double radius,
    required Color color,
    bool focused = false,
  }) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(radius),
      borderSide: focused
          ? BorderSide(color: color, width: 1.5)
          : BorderSide.none,
    );
  }

  // ─────────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final compact = ResponsiveHelper.useCompactLayout(context);
    final landscape = ResponsiveHelper.isLandscape(context);
    final tablet = ResponsiveHelper.isTablet(context);
    final desktop = ResponsiveHelper.isDesktop(context);

    final spacing = ResponsiveHelper.spacing(context);
    final cardPadding = ResponsiveHelper.cardPadding(context);
    final horizontalPadding = ResponsiveHelper.horizontalPadding(context);

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final primaryColor = colorScheme.primary;
    final surfaceContainer = colorScheme.surfaceContainerHighest;

    // ─────────────────────────────────────────────
    // RESPONSIVE TYPOGRAPHY
    // ─────────────────────────────────────────────

    final titleFontSize = desktop
        ? 32.0
        : tablet
        ? 30.0
        : compact
        ? 22.0
        : landscape
        ? 24.0
        : 30.0;

    final subtitleFontSize = desktop
        ? 16.0
        : tablet
        ? 15.0
        : compact
        ? 12.0
        : landscape
        ? 13.0
        : 15.0;

    final sectionTitleSize = desktop
        ? 17.0
        : tablet
        ? 16.0
        : compact
        ? 13.0
        : landscape
        ? 14.0
        : 16.0;

    final fieldTextSize = desktop
        ? 16.0
        : tablet
        ? 15.0
        : compact
        ? 12.0
        : landscape
        ? 13.0
        : 15.0;

    final fieldRadius = compact
        ? 12.0
        : landscape
        ? 13.0
        : 16.0;

    // ─────────────────────────────────────────────
    // RESPONSIVE SPACING
    // ─────────────────────────────────────────────

    final sectionSpacing = desktop
        ? 28.0
        : tablet
        ? 26.0
        : compact
        ? 14.0
        : landscape
        ? 16.0
        : 24.0;

    final fieldSpacing = compact
        ? 12.0
        : landscape
        ? 14.0
        : 22.0;

    final verticalPadding = compact
        ? 10.0
        : landscape
        ? 12.0
        : 20.0;

    // ─────────────────────────────────────────────
    // RESPONSIVE SECTION ICON
    // ─────────────────────────────────────────────

    return AppScaffold(
      showOfflineBanner: true,
      showSyncIcon: true,

      appBar: AdaptiveAppBar(
        titleWidget: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.receipt_long_rounded,
              size: compact
                  ? 20
                  : landscape
                  ? 22
                  : 24,
            ),
            SizedBox(
              width: compact
                  ? 5
                  : landscape
                  ? 6
                  : 8,
            ),
            Text(
              'Add Expense',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: compact
                    ? 17
                    : landscape
                    ? 18
                    : 20,
              ),
            ),
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
                vertical: verticalPadding,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: desktop
                        ? 850
                        : landscape
                        ? 800
                        : 700,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ─────────────────────────────
                      // PAGE HEADER
                      // ─────────────────────────────
                      Text(
                        'Record a new expense',
                        style: TextStyle(
                          fontSize: titleFontSize,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.4,
                        ),
                      ),

                      SizedBox(height: spacing * 0.35),

                      Text(
                        'Keep your spending up to date.',
                        style: TextStyle(
                          color: colorScheme.onSurface.withOpacity(.60),
                          fontSize: subtitleFontSize,
                        ),
                      ),

                      SizedBox(height: sectionSpacing),

                      // ─────────────────────────────
                      // SECTION HEADER
                      // ─────────────────────────────
                      Row(
                        children: [
                          _buildInputIcon(
                            context,
                            icon: Icons.receipt_long_rounded,
                            color: primaryColor,
                          ),

                          SizedBox(width: spacing * 0.35),

                          Text(
                            'Expense Details',
                            style: TextStyle(
                              fontSize: sectionTitleSize,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: spacing * 0.55),

                      // ─────────────────────────────
                      // FORM
                      // ─────────────────────────────
                      Form(
                        key: _formKey,
                        child: Card(
                          elevation: compact ? 1 : 1.5,
                          margin: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              compact ? 14 : 20,
                            ),
                          ),
                          child: Padding(
                            padding: EdgeInsets.all(cardPadding),
                            child: Column(
                              children: [
                                // ─────────────────────
                                // EXPENSE TITLE
                                // ─────────────────────
                                TextFormField(
                                  controller: titleController,
                                  textInputAction: TextInputAction.next,
                                  style: TextStyle(fontSize: fieldTextSize),
                                  decoration: InputDecoration(
                                    labelText: 'Expense Title',
                                    hintText: 'e.g. Grocery Shopping',
                                    labelStyle: TextStyle(
                                      fontSize: fieldTextSize,
                                    ),
                                    hintStyle: TextStyle(
                                      fontSize: fieldTextSize,
                                    ),
                                    prefixIcon: _buildInputIcon(
                                      context,
                                      icon: Icons.edit_note_rounded,
                                      color: primaryColor,
                                    ),
                                    prefixIconConstraints: BoxConstraints(
                                      minWidth: compact ? 48 : 56,
                                      maxWidth: compact ? 52 : 60,
                                      minHeight: compact ? 40 : 48,
                                      maxHeight: compact ? 40 : 48,
                                    ),
                                    filled: true,
                                    fillColor: surfaceContainer,
                                    border: _fieldBorder(
                                      context,
                                      radius: fieldRadius,
                                      color: primaryColor,
                                    ),
                                    enabledBorder: _fieldBorder(
                                      context,
                                      radius: fieldRadius,
                                      color: primaryColor,
                                    ),
                                    focusedBorder: _fieldBorder(
                                      context,
                                      radius: fieldRadius,
                                      color: primaryColor,
                                      focused: true,
                                    ),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return 'Please enter an expense title';
                                    }

                                    if (value.trim().length < 3) {
                                      return 'Title is too short';
                                    }

                                    return null;
                                  },
                                ),

                                SizedBox(height: fieldSpacing),

                                // ─────────────────────
                                // AMOUNT
                                // ─────────────────────
                                TextFormField(
                                  controller: amountController,
                                  textInputAction: TextInputAction.next,
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                        decimal: true,
                                      ),
                                  style: TextStyle(fontSize: fieldTextSize),
                                  decoration: InputDecoration(
                                    labelText: 'Amount',
                                    hintText: 'Enter amount',
                                    labelStyle: TextStyle(
                                      fontSize: fieldTextSize,
                                    ),
                                    hintStyle: TextStyle(
                                      fontSize: fieldTextSize,
                                    ),
                                    prefixText: 'KES ',
                                    prefixStyle: TextStyle(
                                      fontSize: fieldTextSize,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    prefixIcon: _buildInputIcon(
                                      context,
                                      icon: Icons.payments_rounded,
                                      color: Colors.green,
                                    ),
                                    prefixIconConstraints: BoxConstraints(
                                      minWidth: compact ? 48 : 56,
                                      maxWidth: compact ? 52 : 60,
                                      minHeight: compact ? 40 : 48,
                                      maxHeight: compact ? 40 : 48,
                                    ),
                                    filled: true,
                                    fillColor: surfaceContainer,
                                    border: _fieldBorder(
                                      context,
                                      radius: fieldRadius,
                                      color: primaryColor,
                                    ),
                                    enabledBorder: _fieldBorder(
                                      context,
                                      radius: fieldRadius,
                                      color: primaryColor,
                                    ),
                                    focusedBorder: _fieldBorder(
                                      context,
                                      radius: fieldRadius,
                                      color: primaryColor,
                                      focused: true,
                                    ),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Please enter an amount';
                                    }

                                    final amount = double.tryParse(value);

                                    if (amount == null) {
                                      return 'Enter a valid number';
                                    }

                                    if (amount <= 0) {
                                      return 'Amount must be greater than zero';
                                    }

                                    return null;
                                  },
                                ),

                                SizedBox(height: spacing * .45),

                                // ─────────────────────
                                // QUICK AMOUNT CHIPS
                                // ─────────────────────
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: Wrap(
                                    spacing: compact ? 6 : 10,
                                    runSpacing: compact ? 6 : 10,
                                    children: [100, 200, 500, 1000, 2000].map((
                                      amount,
                                    ) {
                                      return ActionChip(
                                        label: Text(
                                          'KES $amount',
                                          style: TextStyle(
                                            fontSize: compact ? 11 : 13,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        padding: EdgeInsets.symmetric(
                                          horizontal: compact ? 6 : 10,
                                          vertical: compact ? 2 : 5,
                                        ),
                                        onPressed: () {
                                          amountController.text = amount
                                              .toString();
                                        },
                                      );
                                    }).toList(),
                                  ),
                                ),

                                SizedBox(height: fieldSpacing),

                                // ─────────────────────
                                // CATEGORY
                                // ─────────────────────
                                DropdownButtonFormField<String>(
                                  value: selectedCategory,

                                  decoration: InputDecoration(
                                    labelText: 'Category',
                                    labelStyle: TextStyle(
                                      fontSize: fieldTextSize,
                                    ),
                                    prefixIcon: _buildInputIcon(
                                      context,
                                      icon: categoryIcons[selectedCategory]!,
                                      color: categoryColors[selectedCategory]!,
                                    ),
                                    prefixIconConstraints: BoxConstraints(
                                      minWidth: compact ? 48 : 56,
                                      maxWidth: compact ? 52 : 60,
                                      minHeight: compact ? 40 : 48,
                                      maxHeight: compact ? 40 : 48,
                                    ),
                                    filled: true,
                                    fillColor: surfaceContainer,
                                    border: _fieldBorder(
                                      context,
                                      radius: fieldRadius,
                                      color: primaryColor,
                                    ),
                                    enabledBorder: _fieldBorder(
                                      context,
                                      radius: fieldRadius,
                                      color: primaryColor,
                                    ),
                                    focusedBorder: _fieldBorder(
                                      context,
                                      radius: fieldRadius,
                                      color: primaryColor,
                                      focused: true,
                                    ),
                                  ),

                                  // IMPORTANT:
                                  // The selected item is displayed
                                  // without another icon.
                                  selectedItemBuilder: (context) {
                                    return categories.map((category) {
                                      return Align(
                                        alignment: Alignment.centerLeft,
                                        child: Text(
                                          category,
                                          style: TextStyle(
                                            fontSize: fieldTextSize,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      );
                                    }).toList();
                                  },

                                  items: categories.map((category) {
                                    return DropdownMenuItem<String>(
                                      value: category,
                                      child: Row(
                                        children: [
                                          Icon(
                                            categoryIcons[category],
                                            color: categoryColors[category],
                                            size: compact ? 17 : 20,
                                          ),
                                          SizedBox(width: compact ? 8 : 10),
                                          Text(
                                            category,
                                            style: TextStyle(
                                              fontSize: fieldTextSize,
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }).toList(),

                                  onChanged: (value) {
                                    if (value == null) {
                                      return;
                                    }

                                    setState(() {
                                      selectedCategory = value;
                                    });
                                  },
                                ),

                                SizedBox(height: fieldSpacing),

                                // ─────────────────────
                                // DATE
                                // ─────────────────────
                                TextFormField(
                                  controller: dateController,
                                  readOnly: true,
                                  onTap: pickExpenseDate,
                                  style: TextStyle(fontSize: fieldTextSize),
                                  decoration: InputDecoration(
                                    labelText: 'Expense Date',
                                    hintText: 'Select date',
                                    labelStyle: TextStyle(
                                      fontSize: fieldTextSize,
                                    ),
                                    hintStyle: TextStyle(
                                      fontSize: fieldTextSize,
                                    ),
                                    prefixIcon: _buildInputIcon(
                                      context,
                                      icon: Icons.calendar_month_rounded,
                                      color: Colors.orange,
                                    ),
                                    prefixIconConstraints: BoxConstraints(
                                      minWidth: compact ? 48 : 56,
                                      maxWidth: compact ? 52 : 60,
                                      minHeight: compact ? 40 : 48,
                                      maxHeight: compact ? 40 : 48,
                                    ),
                                    suffixIcon: Icon(
                                      Icons.keyboard_arrow_down_rounded,
                                      size: compact ? 20 : 24,
                                    ),
                                    filled: true,
                                    fillColor: surfaceContainer,
                                    border: _fieldBorder(
                                      context,
                                      radius: fieldRadius,
                                      color: primaryColor,
                                    ),
                                    enabledBorder: _fieldBorder(
                                      context,
                                      radius: fieldRadius,
                                      color: primaryColor,
                                    ),
                                    focusedBorder: _fieldBorder(
                                      context,
                                      radius: fieldRadius,
                                      color: primaryColor,
                                      focused: true,
                                    ),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Select an expense date';
                                    }

                                    return null;
                                  },
                                ),

                                SizedBox(height: fieldSpacing),

                                // ─────────────────────
                                // ADDITIONAL NOTES HEADER
                                // ─────────────────────
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: Row(
                                    children: [
                                      _buildInputIcon(
                                        context,
                                        icon: Icons.sticky_note_2_rounded,
                                        color: Colors.blue,
                                      ),
                                      SizedBox(width: spacing * .35),
                                      Text(
                                        'Additional Notes',
                                        style: TextStyle(
                                          fontSize: sectionTitleSize,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                SizedBox(height: spacing * .45),

                                // ─────────────────────
                                // DESCRIPTION
                                // ─────────────────────
                                TextFormField(
                                  controller: descriptionController,
                                  textInputAction: TextInputAction.done,
                                  maxLines: compact ? 4 : 5,
                                  maxLength: 250,
                                  style: TextStyle(fontSize: fieldTextSize),
                                  decoration: InputDecoration(
                                    labelText: 'Description',
                                    hintText: 'Optional notes...',
                                    labelStyle: TextStyle(
                                      fontSize: fieldTextSize,
                                    ),
                                    hintStyle: TextStyle(
                                      fontSize: fieldTextSize,
                                    ),
                                    prefixIcon: Padding(
                                      padding: EdgeInsets.only(
                                        top: compact ? 10 : 12,
                                        bottom: compact ? 42 : 55,
                                      ),
                                      child: _buildInputIcon(
                                        context,
                                        icon: Icons.notes_rounded,
                                        color: Colors.blue,
                                      ),
                                    ),
                                    prefixIconConstraints: BoxConstraints(
                                      minWidth: compact ? 48 : 56,
                                      maxWidth: compact ? 52 : 60,
                                    ),
                                    alignLabelWithHint: true,
                                    filled: true,
                                    fillColor: surfaceContainer,
                                    border: _fieldBorder(
                                      context,
                                      radius: fieldRadius,
                                      color: primaryColor,
                                    ),
                                    enabledBorder: _fieldBorder(
                                      context,
                                      radius: fieldRadius,
                                      color: primaryColor,
                                    ),
                                    focusedBorder: _fieldBorder(
                                      context,
                                      radius: fieldRadius,
                                      color: primaryColor,
                                      focused: true,
                                    ),
                                  ),
                                  validator: (value) {
                                    if (value != null && value.length > 250) {
                                      return 'Maximum 250 characters';
                                    }

                                    return null;
                                  },
                                ),

                                SizedBox(
                                  height: compact
                                      ? 18
                                      : landscape
                                      ? 22
                                      : 32,
                                ),

                                // ─────────────────────
                                // SAVE BUTTON
                                // ─────────────────────
                                AnimatedScale(
                                  duration: const Duration(milliseconds: 180),
                                  scale: isLoading ? .97 : 1,
                                  curve: Curves.easeOut,
                                  child: SizedBox(
                                    width: double.infinity,
                                    height: compact
                                        ? 48
                                        : landscape
                                        ? 50
                                        : 56,
                                    child: CustomButton(
                                      text: 'Save Expense',
                                      isLoading: isLoading,
                                      onPressed: isLoading ? null : addExpense,
                                    ),
                                  ),
                                ),

                                SizedBox(height: compact ? 4 : spacing),
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
