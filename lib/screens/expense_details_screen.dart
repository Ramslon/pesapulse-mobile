import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../screens/edit_expense_screen.dart';
import '../exceptions/rate_limit_exception.dart';
import '../repositories/expense_repository.dart';
import '../widgets/app/adaptive_app_bar.dart';
import '../widgets/app/app_scaffold.dart';
import '../utils/responsive_helper.dart';
import '../core/utils/currency_formatter.dart';

class ExpenseDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> expense;

  const ExpenseDetailsScreen({super.key, required this.expense});

  @override
  State<ExpenseDetailsScreen> createState() => _ExpenseDetailsScreenState();
}

class _ExpenseDetailsScreenState extends State<ExpenseDetailsScreen> {
  Map<String, dynamic> get expense => widget.expense;

  final ExpenseRepository repository = ExpenseRepository();

  Future<void> _confirmDelete() async {
    final compact = ResponsiveHelper.useCompactLayout(context);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        final theme = Theme.of(dialogContext);
        final colorScheme = theme.colorScheme;

        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(compact ? 18 : 22),
          ),
          titlePadding: EdgeInsets.fromLTRB(
            compact ? 20 : 24,
            compact ? 20 : 24,
            compact ? 20 : 24,
            8,
          ),
          contentPadding: EdgeInsets.fromLTRB(
            compact ? 20 : 24,
            0,
            compact ? 20 : 24,
            8,
          ),
          actionsPadding: EdgeInsets.fromLTRB(
            compact ? 14 : 18,
            4,
            compact ? 14 : 18,
            compact ? 12 : 16,
          ),
          title: Row(
            children: [
              Container(
                width: compact ? 38 : 42,
                height: compact ? 38 : 42,
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.delete_outline_rounded,
                  color: Colors.red,
                ),
              ),
              const SizedBox(width: 11),
              const Expanded(
                child: Text(
                  'Delete Expense',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
          content: Text(
            'Are you sure you want to permanently delete this expense? This action cannot be undone.',
            style: TextStyle(
              height: 1.4,
              color: colorScheme.onSurface.withOpacity(0.65),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: Colors.red.shade600,
              ),
              onPressed: () => Navigator.pop(dialogContext, true),
              icon: const Icon(Icons.delete_outline_rounded, size: 18),
              label: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    try {
      await repository.deleteExpense(expense['id'] as int);

      if (!mounted) return;

      Navigator.pop(context, true);
    } on RateLimitException catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message)));
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to delete expense: $e')));
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
        return Colors.blueGrey;
    }
  }

  IconData categoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'food':
        return Icons.restaurant_rounded;
      case 'transport':
        return Icons.directions_car_rounded;
      case 'shopping':
        return Icons.shopping_bag_rounded;
      case 'bills':
        return Icons.receipt_long_rounded;
      case 'health':
        return Icons.favorite_rounded;
      case 'education':
        return Icons.school_rounded;
      case 'entertainment':
        return Icons.movie_rounded;
      default:
        return Icons.account_balance_wallet_rounded;
    }
  }

  String formatDate(String? date) {
    if (date == null || date.trim().isEmpty) {
      return 'Date unavailable';
    }

    final parsedDate = DateTime.tryParse(date);

    if (parsedDate == null) {
      return date;
    }

    return DateFormat('dd MMMM yyyy').format(parsedDate);
  }

  Widget _buildDetailCard(
    BuildContext context, {
    required IconData icon,
    required Color accentColor,
    required String title,
    required String value,
    required bool compact,
    required bool landscape,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final radius = compact ? 16.0 : 18.0;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(compact ? 13 : 16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: colorScheme.outline.withOpacity(0.07)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.025),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: compact ? 38 : 42,
            height: compact ? 38 : 42,
            decoration: BoxDecoration(
              color: accentColor.withOpacity(0.09),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, size: compact ? 18 : 20, color: accentColor),
          ),

          SizedBox(width: compact ? 10 : 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title.toUpperCase(),
                  style: TextStyle(
                    fontSize: compact ? 9 : 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.75,
                    color: colorScheme.onSurface.withOpacity(0.46),
                  ),
                ),

                const SizedBox(height: 5),

                Text(
                  value,
                  maxLines: title == 'Description' ? 6 : 3,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: compact ? 13 : 14,
                    height: 1.35,
                    fontWeight: FontWeight.w700,
                    color: colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroSummary(
    BuildContext context, {
    required String category,
    required Color categoryAccent,
    required double amount,
    required String formattedDate,
    required String title,
    required bool compact,
    required bool landscape,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final heroRadius = compact ? 22.0 : 26.0;

    final iconContainerSize = compact
        ? 66.0
        : landscape
        ? 78.0
        : 76.0;

    final iconSize = compact
        ? 31.0
        : landscape
        ? 37.0
        : 35.0;

    final amountSize = compact
        ? 30.0
        : landscape
        ? 38.0
        : 36.0;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(
        compact
            ? 17
            : landscape
            ? 22
            : 20,
      ),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(heroRadius),
        border: Border.all(color: categoryAccent.withOpacity(0.13)),
        boxShadow: [
          BoxShadow(
            color: categoryAccent.withOpacity(0.055),
            blurRadius: 22,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'EXPENSE',
                  style: TextStyle(
                    fontSize: compact ? 9 : 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1,
                    color: colorScheme.primary,
                  ),
                ),
              ),

              const Spacer(),

              Icon(
                Icons.receipt_long_rounded,
                size: compact ? 17 : 19,
                color: colorScheme.onSurface.withOpacity(0.30),
              ),
            ],
          ),

          SizedBox(height: compact ? 17 : 20),

          Container(
            width: iconContainerSize,
            height: iconContainerSize,
            decoration: BoxDecoration(
              color: categoryAccent.withOpacity(0.11),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              categoryIcon(category),
              color: categoryAccent,
              size: iconSize,
            ),
          ),

          SizedBox(height: compact ? 14 : 17),

          TweenAnimationBuilder<double>(
            duration: const Duration(milliseconds: 800),
            tween: Tween(begin: 0, end: amount),
            curve: Curves.easeOutCubic,
            builder: (context, value, child) {
              return FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  '- ${CurrencyFormatter.format(value)}',
                  maxLines: 1,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: amountSize,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.6,
                    color: Colors.red.shade600,
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: 9),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
            decoration: BoxDecoration(
              color: categoryAccent.withOpacity(0.09),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  categoryIcon(category),
                  size: compact ? 13 : 14,
                  color: categoryAccent,
                ),
                const SizedBox(width: 6),
                Text(
                  category,
                  style: TextStyle(
                    color: categoryAccent,
                    fontSize: compact ? 11 : 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: compact ? 10 : 12),

          Text(
            formattedDate,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: compact ? 11 : 12,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface.withOpacity(0.50),
            ),
          ),

          const SizedBox(height: 14),

          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(
              horizontal: compact ? 10 : 12,
              vertical: compact ? 9 : 10,
            ),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withOpacity(0.42),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.description_outlined,
                  size: compact ? 15 : 16,
                  color: colorScheme.onSurface.withOpacity(0.40),
                ),
                const SizedBox(width: 7),
                Expanded(
                  child: Text(
                    title.isEmpty ? 'Untitled expense' : title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: compact ? 11.5 : 12.5,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface.withOpacity(0.68),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(
    BuildContext context, {
    required String title,
    required IconData icon,
    required bool compact,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        Container(
          width: compact ? 29 : 32,
          height: compact ? 29 : 32,
          decoration: BoxDecoration(
            color: colorScheme.primary.withOpacity(0.09),
            borderRadius: BorderRadius.circular(9),
          ),
          child: Icon(
            icon,
            size: compact ? 14 : 15,
            color: colorScheme.primary,
          ),
        ),

        const SizedBox(width: 9),

        Text(
          title,
          style: TextStyle(
            fontSize: compact ? 12.5 : 14,
            fontWeight: FontWeight.w800,
            color: colorScheme.onSurface,
          ),
        ),

        const SizedBox(width: 10),

        Expanded(
          child: Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  colorScheme.outline.withOpacity(0.12),
                  colorScheme.outline.withOpacity(0.02),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton(
    BuildContext context, {
    required bool compact,
    required bool edit,
    required VoidCallback onPressed,
  }) {
    if (edit) {
      return SizedBox(
        height: compact ? 50 : 54,
        child: FilledButton.icon(
          onPressed: onPressed,
          icon: Icon(Icons.edit_outlined, size: compact ? 18 : 20),
          label: Text(
            'Edit Expense',
            style: TextStyle(
              fontSize: compact ? 13 : 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          style: FilledButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(compact ? 15 : 17),
            ),
          ),
        ),
      );
    }

    return SizedBox(
      height: compact ? 50 : 54,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(
          Icons.delete_outline_rounded,
          color: Colors.red.shade600,
          size: compact ? 18 : 20,
        ),
        label: Text(
          'Delete',
          style: TextStyle(
            color: Colors.red.shade600,
            fontSize: compact ? 13 : 14,
            fontWeight: FontWeight.w700,
          ),
        ),
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: Colors.red.shade600.withOpacity(0.45)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(compact ? 15 : 17),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final compact = ResponsiveHelper.useCompactLayout(context);

    final landscape = ResponsiveHelper.isLandscape(context);

    final horizontalPadding = compact
        ? ResponsiveHelper.horizontalPadding(context)
        : landscape
        ? 28.0
        : 24.0;

    final category = (expense['category'] ?? 'Other').toString();

    final categoryAccent = categoryColor(category);

    final amount = double.tryParse(expense['amount']?.toString() ?? '') ?? 0.0;

    final title = expense['title']?.toString() ?? '';

    final description =
        expense['description'] == null ||
            expense['description'].toString().trim().isEmpty
        ? 'No description provided.'
        : expense['description'].toString().trim();

    final formattedDate = formatDate(expense['expense_date']?.toString());

    final details = [
      _ExpenseDetailData(
        title: 'Expense Title',
        value: title.isEmpty ? 'Untitled expense' : title,
        icon: Icons.title_rounded,
        color: Colors.indigo,
      ),
      _ExpenseDetailData(
        title: 'Category',
        value: category,
        icon: categoryIcon(category),
        color: categoryAccent,
      ),
      _ExpenseDetailData(
        title: 'Expense Date',
        value: formattedDate,
        icon: Icons.calendar_today_rounded,
        color: Colors.blue,
      ),
      _ExpenseDetailData(
        title: 'Description',
        value: description,
        icon: Icons.notes_rounded,
        color: Colors.teal,
      ),
    ];

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
              'Expense Details',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),

      body: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: landscape ? 1050 : 760),
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                horizontalPadding,
                compact ? 15 : 20,
                horizontalPadding,
                compact ? 14 : 20,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeroSummary(
                    context,
                    category: category,
                    categoryAccent: categoryAccent,
                    amount: amount,
                    formattedDate: formattedDate,
                    title: title,
                    compact: compact,
                    landscape: landscape,
                  ),

                  SizedBox(height: compact ? 21 : 26),

                  _buildSectionHeader(
                    context,
                    title: 'Expense Information',
                    icon: Icons.info_outline_rounded,
                    compact: compact,
                  ),

                  SizedBox(height: compact ? 11 : 14),

                  if (landscape)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            children: [
                              _buildDetailCard(
                                context,
                                icon: details[0].icon,
                                accentColor: details[0].color,
                                title: details[0].title,
                                value: details[0].value,
                                compact: compact,
                                landscape: landscape,
                              ),
                              _buildDetailCard(
                                context,
                                icon: details[2].icon,
                                accentColor: details[2].color,
                                title: details[2].title,
                                value: details[2].value,
                                compact: compact,
                                landscape: landscape,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            children: [
                              _buildDetailCard(
                                context,
                                icon: details[1].icon,
                                accentColor: details[1].color,
                                title: details[1].title,
                                value: details[1].value,
                                compact: compact,
                                landscape: landscape,
                              ),
                              _buildDetailCard(
                                context,
                                icon: details[3].icon,
                                accentColor: details[3].color,
                                title: details[3].title,
                                value: details[3].value,
                                compact: compact,
                                landscape: landscape,
                              ),
                            ],
                          ),
                        ),
                      ],
                    )
                  else
                    Column(
                      children: details.map((detail) {
                        return _buildDetailCard(
                          context,
                          icon: detail.icon,
                          accentColor: detail.color,
                          title: detail.title,
                          value: detail.value,
                          compact: compact,
                          landscape: landscape,
                        );
                      }).toList(),
                    ),

                  SizedBox(height: compact ? 8 : 12),
                ],
              ),
            ),
          ),
        ),
      ),

      bottomNavigationBar: SafeArea(
        minimum: EdgeInsets.fromLTRB(
          horizontalPadding,
          compact ? 8 : 12,
          horizontalPadding,
          compact ? 8 : 12,
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: landscape ? 760 : double.infinity,
          ),
          child: landscape
              ? Row(
                  children: [
                    Expanded(
                      child: _buildActionButton(
                        context,
                        compact: compact,
                        edit: true,
                        onPressed: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  EditExpenseScreen(expense: expense),
                            ),
                          );

                          if (result == true && mounted) {
                            Navigator.pop(context, true);
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildActionButton(
                        context,
                        compact: compact,
                        edit: false,
                        onPressed: _confirmDelete,
                      ),
                    ),
                  ],
                )
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: _buildActionButton(
                        context,
                        compact: compact,
                        edit: true,
                        onPressed: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  EditExpenseScreen(expense: expense),
                            ),
                          );

                          if (result == true && mounted) {
                            Navigator.pop(context, true);
                          }
                        },
                      ),
                    ),

                    const SizedBox(height: 8),

                    SizedBox(
                      width: double.infinity,
                      child: _buildActionButton(
                        context,
                        compact: compact,
                        edit: false,
                        onPressed: _confirmDelete,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

class _ExpenseDetailData {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _ExpenseDetailData({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });
}
