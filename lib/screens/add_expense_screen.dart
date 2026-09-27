import 'package:flutter/material.dart';

import '../widgets/custom_button.dart';
import '../widgets/input_icon_badge.dart';
import '../widgets/app/adaptive_app_bar.dart';
import '../widgets/app/app_scaffold.dart';

import '../utils/responsive_helper.dart';
import '../utils/snackbar_helper.dart';

import '../services/notification_service.dart';
import '../repositories/expense_repository.dart';

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
    'Other': Colors.blueGrey,
  };

  String selectedCategory = 'Food';

  bool isLoading = false;

  // ─────────────────────────────────────────────
  // HELPERS
  // ─────────────────────────────────────────────

  String _todayAsIsoDate() {
    final now = DateTime.now();

    return '${now.year}-'
        '${now.month.toString().padLeft(2, '0')}-'
        '${now.day.toString().padLeft(2, '0')}';
  }

  Future<void> addExpense() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (isLoading) {
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() {
      isLoading = true;
    });

    final repository = ExpenseRepository();

    try {
      await repository.createExpense(
        title: titleController.text.trim(),
        amount: amountController.text.trim(),
        category: selectedCategory,
        expenseDate: dateController.text.trim(),
        description: descriptionController.text.trim(),
      );

      // Keep budget-alert evaluation in the background.
      NotificationService.checkBudgetAlerts();

      if (!mounted) {
        return;
      }

      SnackbarHelper.showSuccess(context, 'Expense saved successfully!');

      Navigator.pop(context, true);
    } on RateLimitException catch (e) {
      debugPrint('Expense rate limit: ${e.message}');

      if (!mounted) {
        return;
      }

      setState(() {
        isLoading = false;
      });

      SnackbarHelper.showRateLimited(
        context,
        message: e.message,
        remaining: e.remaining,
        retryAfter: e.retryAfter,
      );
    } catch (e) {
      debugPrint('Error saving expense: $e');

      if (!mounted) {
        return;
      }

      setState(() {
        isLoading = false;
      });

      SnackbarHelper.showError(
        context,
        'We couldn’t save your expense. Please try again',
      );
    }
  }

  Future<void> pickExpenseDate() async {
    final now = DateTime.now();

    final pickedDate = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(2020),
      lastDate: DateTime(now.year + 5),
      helpText: 'SELECT EXPENSE DATE',
      cancelText: 'Cancel',
      confirmText: 'Select',
      builder: (context, child) {
        final theme = Theme.of(context);

        return Theme(
          data: theme.copyWith(
            datePickerTheme: DatePickerThemeData(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate == null) {
      return;
    }

    dateController.text =
        '${pickedDate.year}-'
        '${pickedDate.month.toString().padLeft(2, '0')}-'
        '${pickedDate.day.toString().padLeft(2, '0')}';
  }

  void clearForm() {
    titleController.clear();
    amountController.clear();
    categoryController.clear();
    descriptionController.clear();

    dateController.text = _todayAsIsoDate();

    setState(() {
      selectedCategory = 'Food';
    });

    FocusScope.of(context).unfocus();
  }

  // ─────────────────────────────────────────────
  // RESPONSIVE ICON
  // ─────────────────────────────────────────────

  Widget _buildInputIcon(
    BuildContext context, {
    required IconData icon,
    required Color color,
  }) {
    final compact = ResponsiveHelper.useCompactLayout(context);

    final landscape = ResponsiveHelper.isLandscape(context);

    final size = compact
        ? 16.0
        : landscape
        ? 17.0
        : 19.0;

    return InputIconBadge(icon: icon, color: color, size: size);
  }

  // ─────────────────────────────────────────────
  // FIELD DECORATION
  // ─────────────────────────────────────────────

  InputDecoration _fieldDecoration(
    BuildContext context, {
    required String label,
    String? hint,
    required IconData icon,
    required Color iconColor,
    required double radius,
    required double fontSize,
    Widget? suffixIcon,
    String? prefixText,
    bool alignLabelWithHint = false,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final compact = ResponsiveHelper.useCompactLayout(context);

    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixText: prefixText,
      prefixStyle: TextStyle(
        fontSize: fontSize,
        fontWeight: FontWeight.w700,
        color: colorScheme.onSurface.withOpacity(0.72),
      ),
      labelStyle: TextStyle(fontSize: fontSize, fontWeight: FontWeight.w600),
      floatingLabelStyle: TextStyle(
        fontSize: fontSize,
        fontWeight: FontWeight.w700,
        color: colorScheme.primary,
      ),
      hintStyle: TextStyle(
        fontSize: fontSize,
        fontWeight: FontWeight.w500,
        color: colorScheme.onSurface.withOpacity(0.38),
      ),
      prefixIcon: Padding(
        padding: EdgeInsets.only(left: compact ? 7 : 9, right: compact ? 2 : 4),
        child: _buildInputIcon(context, icon: icon, color: iconColor),
      ),
      prefixIconConstraints: BoxConstraints(
        minWidth: compact ? 49 : 56,
        maxWidth: compact ? 55 : 62,
        minHeight: compact ? 42 : 48,
        maxHeight: compact ? 42 : 48,
      ),
      suffixIcon: suffixIcon,
      alignLabelWithHint: alignLabelWithHint,
      filled: true,
      fillColor: colorScheme.surfaceContainerHighest.withOpacity(0.54),
      contentPadding: EdgeInsets.symmetric(
        horizontal: compact ? 13 : 15,
        vertical: compact ? 13 : 15,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radius),
        borderSide: BorderSide(color: colorScheme.outline.withOpacity(0.08)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radius),
        borderSide: BorderSide(color: colorScheme.outline.withOpacity(0.08)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radius),
        borderSide: BorderSide(
          color: colorScheme.primary.withOpacity(0.65),
          width: 1.4,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radius),
        borderSide: BorderSide(color: colorScheme.error.withOpacity(0.60)),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radius),
        borderSide: BorderSide(color: colorScheme.error, width: 1.3),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // SECTION HEADER
  // ─────────────────────────────────────────────

  Widget _buildSectionHeader(
    BuildContext context, {
    required IconData icon,
    required Color color,
    required String eyebrow,
    required String title,
    required bool compact,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        Container(
          width: compact ? 34 : 38,
          height: compact ? 34 : 38,
          decoration: BoxDecoration(
            color: color.withOpacity(0.10),
            borderRadius: BorderRadius.circular(compact ? 10 : 11),
          ),
          child: Icon(icon, color: color, size: compact ? 17 : 19),
        ),

        const SizedBox(width: 10),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                eyebrow,
                style: TextStyle(
                  fontSize: compact ? 9 : 9.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.9,
                  color: color,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                title,
                style: TextStyle(
                  fontSize: compact ? 13 : 14,
                  fontWeight: FontWeight.w800,
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────
  // FORM SECTION CARD
  // ─────────────────────────────────────────────

  Widget _buildSectionCard(
    BuildContext context, {
    required Widget child,
    required bool compact,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(compact ? 13 : 17),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(compact ? 18 : 21),
        border: Border.all(color: colorScheme.outline.withOpacity(0.07)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.025),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: child,
    );
  }

  // ─────────────────────────────────────────────
  // QUICK AMOUNT
  // ─────────────────────────────────────────────

  Widget _buildQuickAmountChip(BuildContext context, int amount, bool compact) {
    final colorScheme = Theme.of(context).colorScheme;

    final selected = amountController.text == amount.toString();

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {
          amountController.text = amount.toString();

          amountController.selection = TextSelection.collapsed(
            offset: amountController.text.length,
          );

          setState(() {});
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 10 : 12,
            vertical: compact ? 7 : 8,
          ),
          decoration: BoxDecoration(
            color: selected
                ? colorScheme.primary
                : colorScheme.surfaceContainerHighest.withOpacity(0.55),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected
                  ? colorScheme.primary
                  : colorScheme.outline.withOpacity(0.08),
            ),
          ),
          child: Text(
            'KES $amount',
            style: TextStyle(
              fontSize: compact ? 10.5 : 11.5,
              fontWeight: FontWeight.w700,
              color: selected
                  ? colorScheme.onPrimary
                  : colorScheme.onSurface.withOpacity(0.68),
            ),
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // CATEGORY FIELD
  // ─────────────────────────────────────────────

  Widget _buildCategoryField(
    BuildContext context, {
    required double radius,
    required double fieldFontSize,
    required bool compact,
  }) {
    final categoryColor = categoryColors[selectedCategory] ?? Colors.blueGrey;

    return DropdownButtonFormField<String>(
      initialValue: selectedCategory,
      isExpanded: true,
      decoration: _fieldDecoration(
        context,
        label: 'Category',
        icon: categoryIcons[selectedCategory] ?? Icons.category_rounded,
        iconColor: categoryColor,
        radius: radius,
        fontSize: fieldFontSize,
      ),
      selectedItemBuilder: (context) {
        return categories.map((category) {
          return Align(
            alignment: Alignment.centerLeft,
            child: Text(
              category,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: fieldFontSize,
                fontWeight: FontWeight.w600,
              ),
            ),
          );
        }).toList();
      },
      items: categories.map((category) {
        final color = categoryColors[category] ?? Colors.blueGrey;

        return DropdownMenuItem<String>(
          value: category,
          child: Row(
            children: [
              Container(
                width: compact ? 30 : 34,
                height: compact ? 30 : 34,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(
                  categoryIcons[category],
                  color: color,
                  size: compact ? 15 : 17,
                ),
              ),
              SizedBox(width: compact ? 8 : 10),
              Text(
                category,
                style: TextStyle(
                  fontSize: fieldFontSize,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        );
      }).toList(),
      dropdownColor: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(16),
      icon: const Icon(Icons.keyboard_arrow_down_rounded),
      onChanged: (value) {
        if (value == null) {
          return;
        }

        setState(() {
          selectedCategory = value;
        });
      },
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

    final horizontalPadding = ResponsiveHelper.horizontalPadding(context);

    final colorScheme = Theme.of(context).colorScheme;

    final primaryColor = colorScheme.primary;

    final fieldFontSize = desktop
        ? 15.0
        : tablet
        ? 14.5
        : compact
        ? 12.5
        : landscape
        ? 13.0
        : 14.5;

    final fieldRadius = compact
        ? 13.0
        : landscape
        ? 14.0
        : 16.0;

    final pageTitleSize = desktop
        ? 31.0
        : tablet
        ? 29.0
        : compact
        ? 24.0
        : landscape
        ? 25.0
        : 29.0;

    final subtitleSize = compact
        ? 12.0
        : landscape
        ? 12.5
        : 14.0;

    final sectionSpacing = compact
        ? 17.0
        : landscape
        ? 18.0
        : 23.0;

    return AppScaffold(
      showOfflineBanner: true,
      showSyncIcon: true,
      appBar: AdaptiveAppBar(
        titleWidget: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.add_card_rounded,
              size: compact
                  ? 20
                  : landscape
                  ? 22
                  : 23,
            ),
            SizedBox(width: compact ? 6 : 8),
            Text(
              'Add Expense',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: compact
                    ? 17
                    : landscape
                    ? 18
                    : 19,
              ),
            ),
          ],
        ),
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: desktop
                      ? 900
                      : landscape
                      ? 860
                      : 720,
                ),
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    horizontalPadding,
                    compact ? 15 : 20,
                    horizontalPadding,
                    compact ? 20 : 28,
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ─────────────────────────────
                        // PAGE INTRODUCTION
                        // ─────────────────────────────
                        _buildSectionCard(
                          context,
                          compact: compact,
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Container(
                                width: compact ? 48 : 56,
                                height: compact ? 48 : 56,
                                decoration: BoxDecoration(
                                  color: primaryColor.withOpacity(0.10),
                                  borderRadius: BorderRadius.circular(
                                    compact ? 14 : 16,
                                  ),
                                ),
                                child: Icon(
                                  Icons.add_card_rounded,
                                  color: primaryColor,
                                  size: compact ? 24 : 28,
                                ),
                              ),

                              SizedBox(width: compact ? 11 : 14),

                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'NEW TRANSACTION',
                                      style: TextStyle(
                                        fontSize: compact ? 9 : 10,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 1,
                                        color: primaryColor,
                                      ),
                                    ),

                                    const SizedBox(height: 5),

                                    Text(
                                      'Record a new expense',
                                      style: TextStyle(
                                        fontSize: pageTitleSize,
                                        fontWeight: FontWeight.w900,
                                        height: 1.02,
                                        letterSpacing: -0.5,
                                        color: colorScheme.onSurface,
                                      ),
                                    ),

                                    const SizedBox(height: 6),

                                    Text(
                                      'Keep your spending up to date and your financial picture accurate.',
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: subtitleSize,
                                        height: 1.35,
                                        fontWeight: FontWeight.w500,
                                        color: colorScheme.onSurface
                                            .withOpacity(0.55),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(width: 8),

                              IconButton(
                                tooltip: 'Clear form',
                                onPressed: clearForm,
                                icon: Icon(
                                  Icons.refresh_rounded,
                                  size: compact ? 19 : 21,
                                  color: colorScheme.onSurface.withOpacity(
                                    0.42,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        SizedBox(height: sectionSpacing),

                        // ─────────────────────────────
                        // CORE EXPENSE INFORMATION
                        // ─────────────────────────────
                        _buildSectionHeader(
                          context,
                          icon: Icons.receipt_long_rounded,
                          color: primaryColor,
                          eyebrow: 'TRANSACTION DETAILS',
                          title: 'What did you spend?',
                          compact: compact,
                        ),

                        SizedBox(height: spacing * 0.65),

                        _buildSectionCard(
                          context,
                          compact: compact,
                          child: Column(
                            children: [
                              // TITLE + AMOUNT
                              if (landscape)
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: _buildTitleField(
                                        context,
                                        compact: compact,
                                        fieldFontSize: fieldFontSize,
                                        fieldRadius: fieldRadius,
                                        primaryColor: primaryColor,
                                      ),
                                    ),
                                    SizedBox(width: spacing),
                                    Expanded(
                                      child: _buildAmountField(
                                        context,
                                        compact: compact,
                                        fieldFontSize: fieldFontSize,
                                        fieldRadius: fieldRadius,
                                      ),
                                    ),
                                  ],
                                )
                              else ...[
                                _buildTitleField(
                                  context,
                                  compact: compact,
                                  fieldFontSize: fieldFontSize,
                                  fieldRadius: fieldRadius,
                                  primaryColor: primaryColor,
                                ),

                                SizedBox(height: compact ? 12 : 15),

                                _buildAmountField(
                                  context,
                                  compact: compact,
                                  fieldFontSize: fieldFontSize,
                                  fieldRadius: fieldRadius,
                                ),
                              ],

                              SizedBox(height: compact ? 7 : 9),

                              // QUICK AMOUNTS
                              Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  'QUICK AMOUNTS',
                                  style: TextStyle(
                                    fontSize: compact ? 9 : 9.5,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.8,
                                    color: colorScheme.onSurface.withOpacity(
                                      0.43,
                                    ),
                                  ),
                                ),
                              ),

                              SizedBox(height: compact ? 7 : 8),

                              Align(
                                alignment: Alignment.centerLeft,
                                child: Wrap(
                                  spacing: compact ? 6 : 8,
                                  runSpacing: compact ? 6 : 8,
                                  children: [100, 200, 500, 1000, 2000]
                                      .map(
                                        (amount) => _buildQuickAmountChip(
                                          context,
                                          amount,
                                          compact,
                                        ),
                                      )
                                      .toList(),
                                ),
                              ),

                              SizedBox(height: compact ? 14 : 18),

                              // CATEGORY + DATE
                              if (landscape)
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: _buildCategoryField(
                                        context,
                                        radius: fieldRadius,
                                        fieldFontSize: fieldFontSize,
                                        compact: compact,
                                      ),
                                    ),
                                    SizedBox(width: spacing),
                                    Expanded(
                                      child: _buildDateField(
                                        context,
                                        compact: compact,
                                        fieldFontSize: fieldFontSize,
                                        fieldRadius: fieldRadius,
                                      ),
                                    ),
                                  ],
                                )
                              else ...[
                                _buildCategoryField(
                                  context,
                                  radius: fieldRadius,
                                  fieldFontSize: fieldFontSize,
                                  compact: compact,
                                ),

                                SizedBox(height: compact ? 12 : 15),

                                _buildDateField(
                                  context,
                                  compact: compact,
                                  fieldFontSize: fieldFontSize,
                                  fieldRadius: fieldRadius,
                                ),
                              ],
                            ],
                          ),
                        ),

                        SizedBox(height: sectionSpacing),

                        // ─────────────────────────────
                        // NOTES
                        // ─────────────────────────────
                        _buildSectionHeader(
                          context,
                          icon: Icons.sticky_note_2_rounded,
                          color: Colors.blue,
                          eyebrow: 'OPTIONAL',
                          title: 'Add context to this expense',
                          compact: compact,
                        ),

                        SizedBox(height: spacing * 0.65),

                        _buildSectionCard(
                          context,
                          compact: compact,
                          child: TextFormField(
                            controller: descriptionController,
                            textInputAction: TextInputAction.done,
                            maxLines: compact ? 4 : 5,
                            maxLength: 250,
                            style: TextStyle(
                              fontSize: fieldFontSize,
                              fontWeight: FontWeight.w500,
                            ),
                            decoration: _fieldDecoration(
                              context,
                              label: 'Description',
                              hint: 'Optional notes about this expense...',
                              icon: Icons.notes_rounded,
                              iconColor: Colors.blue,
                              radius: fieldRadius,
                              fontSize: fieldFontSize,
                              alignLabelWithHint: true,
                            ),
                            validator: (value) {
                              if (value != null && value.length > 250) {
                                return 'Maximum 250 characters';
                              }

                              return null;
                            },
                          ),
                        ),

                        SizedBox(height: compact ? 18 : 23),

                        // ─────────────────────────────
                        // SAVE
                        // ─────────────────────────────
                        AnimatedScale(
                          duration: const Duration(milliseconds: 180),
                          scale: isLoading ? 0.975 : 1,
                          curve: Curves.easeOut,
                          child: SizedBox(
                            width: double.infinity,
                            height: compact
                                ? 50
                                : landscape
                                ? 52
                                : 56,
                            child: CustomButton(
                              text: 'Save Expense',
                              isLoading: isLoading,
                              onPressed: isLoading ? null : addExpense,
                            ),
                          ),
                        ),

                        const SizedBox(height: 5),

                        Center(
                          child: Text(
                            'Your expense will be added to your spending history.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: compact ? 9.5 : 10.5,
                              fontWeight: FontWeight.w500,
                              color: colorScheme.onSurface.withOpacity(0.40),
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
      ),
    );
  }

  Widget _buildTitleField(
    BuildContext context, {
    required bool compact,
    required double fieldFontSize,
    required double fieldRadius,
    required Color primaryColor,
  }) {
    return TextFormField(
      controller: titleController,
      textInputAction: TextInputAction.next,
      style: TextStyle(fontSize: fieldFontSize, fontWeight: FontWeight.w500),
      decoration: _fieldDecoration(
        context,
        label: 'Expense Title',
        hint: 'e.g. Grocery Shopping',
        icon: Icons.edit_note_rounded,
        iconColor: primaryColor,
        radius: fieldRadius,
        fontSize: fieldFontSize,
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
    );
  }

  Widget _buildAmountField(
    BuildContext context, {
    required bool compact,
    required double fieldFontSize,
    required double fieldRadius,
  }) {
    return TextFormField(
      controller: amountController,
      textInputAction: TextInputAction.next,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      onChanged: (_) {
        setState(() {});
      },
      style: TextStyle(fontSize: fieldFontSize, fontWeight: FontWeight.w700),
      decoration: _fieldDecoration(
        context,
        label: 'Amount',
        hint: 'Enter amount',
        icon: Icons.payments_rounded,
        iconColor: Colors.green,
        radius: fieldRadius,
        fontSize: fieldFontSize,
        prefixText: 'KES ',
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Please enter an amount';
        }

        final amount = double.tryParse(value.trim());

        if (amount == null) {
          return 'Enter a valid number';
        }

        if (amount <= 0) {
          return 'Amount must be greater than zero';
        }

        return null;
      },
    );
  }

  Widget _buildDateField(
    BuildContext context, {
    required bool compact,
    required double fieldFontSize,
    required double fieldRadius,
  }) {
    return TextFormField(
      controller: dateController,
      readOnly: true,
      onTap: pickExpenseDate,
      style: TextStyle(fontSize: fieldFontSize, fontWeight: FontWeight.w600),
      decoration: _fieldDecoration(
        context,
        label: 'Expense Date',
        hint: 'Select date',
        icon: Icons.calendar_month_rounded,
        iconColor: Colors.orange,
        radius: fieldRadius,
        fontSize: fieldFontSize,
        suffixIcon: Icon(
          Icons.keyboard_arrow_down_rounded,
          size: compact ? 20 : 22,
        ),
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Select an expense date';
        }

        return null;
      },
    );
  }

  @override
  void initState() {
    super.initState();

    dateController.text = _todayAsIsoDate();
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
}
