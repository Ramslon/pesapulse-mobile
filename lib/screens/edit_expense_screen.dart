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

import '../exceptions/rate_limit_exception.dart';

class EditExpenseScreen extends StatefulWidget {
  final Map expense;

  const EditExpenseScreen({super.key, required this.expense});

  @override
  State<EditExpenseScreen> createState() => _EditExpenseScreenState();
}

class _EditExpenseScreenState extends State<EditExpenseScreen> {
  final ExpenseRepository repository = ExpenseRepository();

  late final TextEditingController titleController;
  late final TextEditingController amountController;
  late final TextEditingController dateController;
  late final TextEditingController descriptionController;

  bool isLoading = false;

  final DateFormat dateFormatter = DateFormat('dd MMM yyyy');

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

  late String selectedCategory;

  @override
  void initState() {
    super.initState();

    final originalCategory = widget.expense['category']?.toString();

    selectedCategory = categories.contains(originalCategory)
        ? originalCategory!
        : 'Other';

    titleController = TextEditingController(
      text: widget.expense['title']?.toString() ?? '',
    );

    amountController = TextEditingController(
      text: widget.expense['amount']?.toString() ?? '',
    );

    dateController = TextEditingController(
      text: widget.expense['expense_date']?.toString() ?? '',
    );

    descriptionController = TextEditingController(
      text: widget.expense['description']?.toString() ?? '',
    );
  }

  bool get isFormValid {
    final amount = double.tryParse(amountController.text.trim());

    return titleController.text.trim().length >= 3 &&
        amount != null &&
        amount > 0 &&
        selectedCategory.isNotEmpty &&
        dateController.text.trim().isNotEmpty;
  }

  Future<void> updateExpense() async {
    if (!isFormValid) {
      SnackbarHelper.showError(
        context,
        'Please complete all required fields correctly.',
      );
      return;
    }

    if (isLoading) {
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() {
      isLoading = true;
    });

    try {
      await repository.updateExpense(
        id: widget.expense['id'],
        title: titleController.text.trim(),
        amount: amountController.text.trim(),
        category: selectedCategory,
        expenseDate: dateController.text.trim(),
        description: descriptionController.text.trim(),
      );

      await SyncService.instance.getPendingChanges();

      if (!mounted) {
        return;
      }

      setState(() {
        isLoading = false;
      });

      SnackbarHelper.showSuccess(context, 'Expense updated successfully!');

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
      debugPrint('Error updating expense: $e');

      if (!mounted) {
        return;
      }

      setState(() {
        isLoading = false;
      });

      SnackbarHelper.showError(
        context,
        'We couldn’t update your expense. Please try again.',
      );
    }
  }

  Future<void> pickExpenseDate() async {
    final now = DateTime.now();

    final parsedInitialDate = DateTime.tryParse(dateController.text.trim());

    final initialDate =
        parsedInitialDate != null && !parsedInitialDate.isAfter(now)
        ? parsedInitialDate
        : now;

    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(now.year + 5),
      helpText: 'SELECT EXPENSE DATE',
      cancelText: 'Cancel',
      confirmText: 'Select',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
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

    setState(() {});
  }

  Color _categoryColor(String category) {
    return categoryColors[category] ?? Colors.blueGrey;
  }

  IconData _categoryIcon(String category) {
    return categoryIcons[category] ?? Icons.category_rounded;
  }

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

  Widget _buildSurfaceCard(
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

  Widget _buildExpensePreview(
    BuildContext context, {
    required bool compact,
    required bool landscape,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    final title = titleController.text.trim().isEmpty
        ? 'Expense Title'
        : titleController.text.trim();

    final amount = double.tryParse(amountController.text.trim()) ?? 0.0;

    final parsedDate = DateTime.tryParse(dateController.text.trim());

    final formattedDate = parsedDate == null
        ? 'No date selected'
        : dateFormatter.format(parsedDate);

    final categoryColor = _categoryColor(selectedCategory);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(
        compact
            ? 15
            : landscape
            ? 19
            : 18,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [colorScheme.surface, categoryColor.withOpacity(0.035)],
        ),
        borderRadius: BorderRadius.circular(compact ? 19 : 22),
        border: Border.all(color: categoryColor.withOpacity(0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: compact ? 38 : 42,
                height: compact ? 38 : 42,
                decoration: BoxDecoration(
                  color: categoryColor.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(compact ? 11 : 12),
                ),
                child: Icon(
                  _categoryIcon(selectedCategory),
                  color: categoryColor,
                  size: compact ? 19 : 21,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'LIVE PREVIEW',
                      style: TextStyle(
                        fontSize: compact ? 9 : 9.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.95,
                        color: colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Your updated transaction',
                      style: TextStyle(
                        fontSize: compact ? 12 : 13,
                        fontWeight: FontWeight.w700,
                        color: colorScheme.onSurface.withOpacity(0.64),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.visibility_outlined,
                size: compact ? 18 : 19,
                color: colorScheme.onSurface.withOpacity(0.30),
              ),
            ],
          ),

          SizedBox(height: compact ? 15 : 18),

          Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: compact ? 17 : 20,
              height: 1.15,
              fontWeight: FontWeight.w800,
              color: colorScheme.onSurface,
            ),
          ),

          const SizedBox(height: 6),

          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              '- ${CurrencyFormatter.format(amount)}',
              maxLines: 1,
              style: TextStyle(
                fontSize: compact ? 25 : 29,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.4,
                color: Colors.red.shade600,
              ),
            ),
          ),

          SizedBox(height: compact ? 14 : 16),

          if (landscape)
            Row(
              children: [
                Expanded(
                  child: _buildPreviewMetric(
                    context,
                    icon: _categoryIcon(selectedCategory),
                    title: 'CATEGORY',
                    value: selectedCategory,
                    color: categoryColor,
                    compact: compact,
                  ),
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: _buildPreviewMetric(
                    context,
                    icon: Icons.calendar_month_rounded,
                    title: 'DATE',
                    value: formattedDate,
                    color: Colors.orange,
                    compact: compact,
                  ),
                ),
              ],
            )
          else
            Column(
              children: [
                _buildPreviewMetric(
                  context,
                  icon: _categoryIcon(selectedCategory),
                  title: 'CATEGORY',
                  value: selectedCategory,
                  color: categoryColor,
                  compact: compact,
                ),
                const SizedBox(height: 8),
                _buildPreviewMetric(
                  context,
                  icon: Icons.calendar_month_rounded,
                  title: 'DATE',
                  value: formattedDate,
                  color: Colors.orange,
                  compact: compact,
                ),
              ],
            ),

          if (descriptionController.text.trim().isNotEmpty) ...[
            SizedBox(height: compact ? 11 : 14),
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(compact ? 10 : 12),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest.withOpacity(0.45),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.notes_rounded,
                    size: compact ? 15 : 16,
                    color: colorScheme.onSurface.withOpacity(0.40),
                  ),
                  const SizedBox(width: 7),
                  Expanded(
                    child: Text(
                      descriptionController.text.trim(),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: compact ? 10.5 : 11.5,
                        height: 1.35,
                        fontWeight: FontWeight.w500,
                        color: colorScheme.onSurface.withOpacity(0.62),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPreviewMetric(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String value,
    required Color color,
    required bool compact,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(compact ? 9 : 11),
      decoration: BoxDecoration(
        color: color.withOpacity(0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.09)),
      ),
      child: Row(
        children: [
          Container(
            width: compact ? 29 : 32,
            height: compact ? 29 : 32,
            decoration: BoxDecoration(
              color: color.withOpacity(0.10),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, size: compact ? 14 : 15, color: color),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: compact ? 8.5 : 9,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.7,
                    color: colorScheme.onSurface.withOpacity(0.43),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: compact ? 11 : 12,
                    fontWeight: FontWeight.w700,
                    color: colorScheme.onSurface.withOpacity(0.72),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _buildFieldDecoration(
    BuildContext context, {
    required String label,
    String? hint,
    required IconData icon,
    Color? iconColor,
    String? prefixText,
    Widget? suffixIcon,
    bool alignLabelWithHint = false,
  }) {
    final compact = ResponsiveHelper.useCompactLayout(context);

    final colorScheme = Theme.of(context).colorScheme;

    final fieldRadius = compact ? 13.0 : 16.0;
    final fieldFontSize = compact ? 12.5 : 14.0;

    final color = iconColor ?? colorScheme.primary;

    return InputDecoration(
      labelText: label,
      hintText: hint,

      prefixText: prefixText,
      prefixStyle: TextStyle(
        fontSize: fieldFontSize,
        fontWeight: FontWeight.w700,
        color: colorScheme.onSurface.withOpacity(0.72),
      ),

      labelStyle: TextStyle(
        fontSize: fieldFontSize,
        fontWeight: FontWeight.w600,
        color: colorScheme.onSurface.withOpacity(0.70),
      ),

      floatingLabelStyle: TextStyle(
        fontSize: fieldFontSize,
        fontWeight: FontWeight.w700,
        color: colorScheme.primary,
      ),

      hintStyle: TextStyle(
        fontSize: fieldFontSize,
        fontWeight: FontWeight.w500,
        color: colorScheme.onSurface.withOpacity(0.38),
      ),

      prefixIcon: Padding(
        padding: EdgeInsets.only(left: compact ? 7 : 9, right: compact ? 2 : 4),
        child: InputIconBadge(
          icon: icon,
          color: color,
          size: compact ? 16 : 18,
        ),
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
        borderRadius: BorderRadius.circular(fieldRadius),
        borderSide: BorderSide(color: colorScheme.outline.withOpacity(0.08)),
      ),

      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(fieldRadius),
        borderSide: BorderSide(color: colorScheme.outline.withOpacity(0.08)),
      ),

      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(fieldRadius),
        borderSide: BorderSide(
          color: colorScheme.primary.withOpacity(0.65),
          width: 1.4,
        ),
      ),

      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(fieldRadius),
        borderSide: BorderSide(color: colorScheme.error.withOpacity(0.60)),
      ),

      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(fieldRadius),
        borderSide: BorderSide(color: colorScheme.error, width: 1.3),
      ),
    );
  }

  Widget _buildInputField({
    required BuildContext context,
    required TextEditingController controller,
    required String label,
    required IconData icon,
    Color? iconColor,
    TextInputType keyboardType = TextInputType.text,
    String? prefixText,
    String? hintText,
    int maxLines = 1,
    TextInputAction textInputAction = TextInputAction.next,
    bool readOnly = false,
    VoidCallback? onTap,
    ValueChanged<String>? onChanged,
  }) {
    final compact = ResponsiveHelper.useCompactLayout(context);

    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      maxLines: maxLines,
      readOnly: readOnly,
      onTap: onTap,
      onChanged: onChanged,
      style: TextStyle(
        fontSize: compact ? 12.5 : 14.5,
        fontWeight: FontWeight.w500,
      ),
      decoration: _buildFieldDecoration(
        context,
        label: label,
        hint: hintText,
        icon: icon,
        iconColor: iconColor,
        prefixText: prefixText,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final compact = ResponsiveHelper.useCompactLayout(context);

    final landscape = ResponsiveHelper.isLandscape(context);

    final desktop = ResponsiveHelper.isDesktop(context);

    final spacing = ResponsiveHelper.spacing(context);

    final sectionSpacing = ResponsiveHelper.sectionSpacing(context);

    final horizontalPadding = compact
        ? ResponsiveHelper.horizontalPadding(context)
        : landscape
        ? 24.0
        : ResponsiveHelper.horizontalPadding(context);

    final titleSize = desktop
        ? 31.0
        : landscape
        ? 27.0
        : compact
        ? 24.0
        : 29.0;

    final subtitleSize = compact
        ? 12.0
        : landscape
        ? 12.5
        : 14.0;

    return AppScaffold(
      showOfflineBanner: true,
      showSyncIcon: true,
      appBar: AdaptiveAppBar(
        titleWidget: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.edit_note_rounded, size: compact ? 20 : 23),
            SizedBox(width: compact ? 6 : 8),
            Text(
              'Edit Expense',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: compact ? 17 : 19,
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
                      ? 1050
                      : landscape
                      ? 920
                      : 720,
                ),
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    horizontalPadding,
                    compact ? 15 : 20,
                    horizontalPadding,
                    compact ? 20 : 28,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ─────────────────────────────
                      // PAGE INTRO
                      // ─────────────────────────────
                      _buildSurfaceCard(
                        context,
                        compact: compact,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Container(
                              width: compact ? 48 : 56,
                              height: compact ? 48 : 56,
                              decoration: BoxDecoration(
                                color: Colors.deepPurple.withOpacity(0.10),
                                borderRadius: BorderRadius.circular(
                                  compact ? 14 : 16,
                                ),
                              ),
                              child: const Icon(
                                Icons.edit_note_rounded,
                                color: Colors.deepPurple,
                              ),
                            ),

                            SizedBox(width: compact ? 11 : 14),

                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'UPDATE TRANSACTION',
                                    style: TextStyle(
                                      fontSize: compact ? 9 : 10,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 1,
                                      color: Colors.deepPurple,
                                    ),
                                  ),
                                  const SizedBox(height: 5),
                                  Text(
                                    'Edit your expense',
                                    style: TextStyle(
                                      fontSize: titleSize,
                                      height: 1.04,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: -0.5,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurface,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Keep your spending history accurate by updating the details below.',
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: subtitleSize,
                                      height: 1.35,
                                      fontWeight: FontWeight.w500,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurface.withOpacity(0.55),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: sectionSpacing),

                      // ─────────────────────────────
                      // LANDSCAPE: PREVIEW + FORM
                      // PORTRAIT: PREVIEW THEN FORM
                      // ─────────────────────────────
                      if (landscape)
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 4,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildSectionHeader(
                                    context,
                                    icon: Icons.visibility_outlined,
                                    color: Colors.teal,
                                    eyebrow: 'PREVIEW',
                                    title: 'Updated expense',
                                    compact: compact,
                                  ),
                                  const SizedBox(height: 12),
                                  _buildExpensePreview(
                                    context,
                                    compact: compact,
                                    landscape: landscape,
                                  ),
                                ],
                              ),
                            ),

                            SizedBox(width: spacing),

                            Expanded(
                              flex: 6,
                              child: _buildEditForm(
                                context,
                                compact: compact,
                                landscape: landscape,
                              ),
                            ),
                          ],
                        )
                      else ...[
                        _buildSectionHeader(
                          context,
                          icon: Icons.visibility_outlined,
                          color: Colors.teal,
                          eyebrow: 'PREVIEW',
                          title: 'Updated expense',
                          compact: compact,
                        ),

                        SizedBox(height: compact ? 10 : 12),

                        _buildExpensePreview(
                          context,
                          compact: compact,
                          landscape: landscape,
                        ),

                        SizedBox(height: sectionSpacing),

                        _buildEditForm(
                          context,
                          compact: compact,
                          landscape: landscape,
                        ),
                      ],

                      SizedBox(height: compact ? 10 : 16),
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

  Widget _buildEditForm(
    BuildContext context, {
    required bool compact,
    required bool landscape,
  }) {
    final spacing = ResponsiveHelper.spacing(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          context,
          icon: Icons.receipt_long_rounded,
          color: Theme.of(context).colorScheme.primary,
          eyebrow: 'TRANSACTION DETAILS',
          title: 'What would you like to change?',
          compact: compact,
        ),

        SizedBox(height: compact ? 10 : 12),

        _buildSurfaceCard(
          context,
          compact: compact,
          child: Column(
            children: [
              if (landscape)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _buildInputField(
                        context: context,
                        controller: titleController,
                        label: 'Expense Title',
                        hintText: 'e.g. Grocery Shopping',
                        icon: Icons.edit_note_rounded,
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                    SizedBox(width: spacing),
                    Expanded(
                      child: _buildInputField(
                        context: context,
                        controller: amountController,
                        label: 'Amount',
                        hintText: 'Enter amount',
                        prefixText: 'KES ',
                        icon: Icons.payments_rounded,
                        iconColor: Colors.green,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                  ],
                )
              else ...[
                _buildInputField(
                  context: context,
                  controller: titleController,
                  label: 'Expense Title',
                  hintText: 'e.g. Grocery Shopping',
                  icon: Icons.edit_note_rounded,
                  onChanged: (_) => setState(() {}),
                ),

                _buildInputField(
                  context: context,
                  controller: amountController,
                  label: 'Amount',
                  hintText: 'Enter amount',
                  prefixText: 'KES ',
                  icon: Icons.payments_rounded,
                  iconColor: Colors.green,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ],

              _buildCategoryField(
                context,
                compact: compact,
                landscape: landscape,
              ),

              SizedBox(height: spacing),

              _buildInputField(
                context: context,
                controller: dateController,
                label: 'Expense Date',
                hintText: 'Select date',
                icon: Icons.calendar_month_rounded,
                iconColor: Colors.orange,
                readOnly: true,
                onTap: pickExpenseDate,
              ),

              SizedBox(height: spacing),

              _buildInputField(
                context: context,
                controller: descriptionController,
                label: 'Description',
                hintText: 'Optional notes...',
                icon: Icons.notes_rounded,
                maxLines: compact ? 4 : 5,
                textInputAction: TextInputAction.done,
                onChanged: (_) => setState(() {}),
              ),

              SizedBox(height: compact ? 7 : 10),

              // ─────────────────────────────
              // UPDATE BUTTON
              // ─────────────────────────────
              AnimatedScale(
                duration: const Duration(milliseconds: 180),
                scale: isLoading ? 0.975 : 1,
                child: SizedBox(
                  width: double.infinity,
                  height: compact
                      ? 50
                      : landscape
                      ? 52
                      : 56,
                  child: ElevatedButton.icon(
                    onPressed: isFormValid && !isLoading ? updateExpense : null,
                    icon: isLoading
                        ? SizedBox(
                            width: compact ? 18 : 20,
                            height: compact ? 18 : 20,
                            child: const CircularProgressIndicator(
                              strokeWidth: 2.4,
                              color: Colors.white,
                            ),
                          )
                        : Icon(
                            Icons.check_circle_outline_rounded,
                            size: compact ? 19 : 21,
                          ),
                    label: Text(
                      isLoading ? 'Updating...' : 'Update Expense',
                      style: TextStyle(
                        fontSize: compact ? 13 : 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(compact ? 15 : 17),
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 5),

              Text(
                'Changes are saved to your spending history.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: compact ? 9.5 : 10.5,
                  fontWeight: FontWeight.w500,
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(0.40),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryField(
    BuildContext context, {
    required bool compact,
    required bool landscape,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    final selectedColor = _categoryColor(selectedCategory);

    return DropdownButtonFormField<String>(
      initialValue: selectedCategory,
      isExpanded: true,
      decoration: _buildFieldDecoration(
        context,
        label: 'Category',
        icon: _categoryIcon(selectedCategory),
        iconColor: selectedColor,
      ),
      selectedItemBuilder: (context) {
        return categories.map((category) {
          return Align(
            alignment: Alignment.centerLeft,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  category,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: compact ? 12.5 : 14,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          );
        }).toList();
      },
      items: categories.map((category) {
        final color = _categoryColor(category);

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
                  _categoryIcon(category),
                  color: color,
                  size: compact ? 15 : 17,
                ),
              ),
              SizedBox(width: compact ? 8 : 10),
              Text(
                category,
                style: TextStyle(
                  fontSize: compact ? 12.5 : 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        );
      }).toList(),
      dropdownColor: colorScheme.surface,
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
}
