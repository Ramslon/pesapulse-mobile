import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../widgets/empty_state.dart';
import '../../screens/add_expense_screen.dart';
import '../../utils/responsive_helper.dart';
import '../../core/utils/currency_formatter.dart';

import 'budget_section_header.dart';

class BudgetBreakdownCard extends StatefulWidget {
  final Map<String, double> categoryTotals;
  final double totalSpent;

  const BudgetBreakdownCard({
    super.key,
    required this.categoryTotals,
    required this.totalSpent,
  });

  @override
  State<BudgetBreakdownCard> createState() => _BudgetBreakdownCardState();
}

class _BudgetBreakdownCardState extends State<BudgetBreakdownCard> {
  String? selectedCategory;

  static const List<Color> colors = [
    Colors.green,
    Colors.blue,
    Colors.orange,
    Colors.purple,
    Colors.red,
    Colors.teal,
    Colors.indigo,
    Colors.pink,
  ];

  @override
  void didUpdateWidget(covariant BudgetBreakdownCard oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Clear selection if the selected category no longer exists.
    if (selectedCategory != null &&
        !widget.categoryTotals.containsKey(selectedCategory)) {
      selectedCategory = null;
    }
  }

  Color _categoryColor(String category) {
    final categories = widget.categoryTotals.keys.toList();
    final index = categories.indexOf(category);

    if (index < 0) {
      return colors.first;
    }

    return colors[index % colors.length];
  }

  void _selectCategory(String category) {
    setState(() {
      selectedCategory = selectedCategory == category ? null : category;
    });
  }

  double _percentageFor(String category) {
    final amount = widget.categoryTotals[category] ?? 0;

    if (widget.totalSpent <= 0) {
      return 0;
    }

    return (amount / widget.totalSpent) * 100;
  }

  int _rankFor(String category) {
    final sorted = widget.categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sorted.indexWhere((entry) => entry.key == category) + 1;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final compact = ResponsiveHelper.useCompactLayout(context);
    final tablet = ResponsiveHelper.isTablet(context);
    final desktop = ResponsiveHelper.isDesktop(context);
    final landscape = ResponsiveHelper.isLandscape(context);

    final cardPadding = ResponsiveHelper.cardPadding(context);
    final sectionSpacing = ResponsiveHelper.sectionSpacing(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const BudgetSectionHeader(
          title: "Budget Breakdown",
          subtitle: "Tap a category to see more details",
        ),

        SizedBox(
          height: compact
              ? 14
              : tablet
              ? 18
              : 20,
        ),

        Card(
          elevation: 0,
          color: theme.colorScheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(
              compact
                  ? 16
                  : tablet
                  ? 18
                  : 20,
            ),
          ),
          child: Padding(
            padding: EdgeInsets.all(cardPadding),
            child: _buildContent(
              context,
              compact: compact,
              tablet: tablet,
              desktop: desktop,
              landscape: landscape,
              sectionSpacing: sectionSpacing,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildContent(
    BuildContext context, {
    required bool compact,
    required bool tablet,
    required bool desktop,
    required bool landscape,
    required double sectionSpacing,
  }) {
    if (widget.categoryTotals.isEmpty) {
      return _buildEmptyState(context, compact: compact, tablet: tablet);
    }

    final categories = widget.categoryTotals.keys.toList();

    return Column(
      children: [
        _buildChart(
          context,
          categories: categories,
          compact: compact,
          tablet: tablet,
          desktop: desktop,
          landscape: landscape,
        ),

        SizedBox(height: compact ? 14 : 18),

        AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          child: selectedCategory == null
              ? _buildChartHint(context, compact: compact)
              : _buildSelectedCategoryDetails(
                  context,
                  category: selectedCategory!,
                  compact: compact,
                ),
        ),

        SizedBox(height: compact ? 14 : 18),

        Divider(
          height: 1,
          color: Theme.of(context).dividerColor.withOpacity(.55),
        ),

        SizedBox(height: compact ? 12 : 16),

        _buildCategoryList(
          context,
          compact: compact,
          sectionSpacing: sectionSpacing,
        ),
      ],
    );
  }

  Widget _buildChart(
    BuildContext context, {
    required List<String> categories,
    required bool compact,
    required bool tablet,
    required bool desktop,
    required bool landscape,
  }) {
    final chartHeight = _chartHeight(
      compact: compact,
      tablet: tablet,
      desktop: desktop,
      landscape: landscape,
    );

    return SizedBox(
      height: chartHeight,
      width: double.infinity,
      child: PieChart(
        PieChartData(
          sectionsSpace: compact ? 2 : 3,
          centerSpaceRadius: compact
              ? 38
              : tablet
              ? 46
              : 52,
          sections: _buildPieSections(
            context,
            categories: categories,
            compact: compact,
            tablet: tablet,
          ),
          pieTouchData: PieTouchData(
            enabled: true,
            touchCallback: (event, response) {
              if (response == null ||
                  response.touchedSection == null ||
                  !event.isInterestedForInteractions) {
                return;
              }

              final touchedIndex = response.touchedSection!.touchedSectionIndex;

              if (touchedIndex < 0 || touchedIndex >= categories.length) {
                return;
              }

              _selectCategory(categories[touchedIndex]);
            },
          ),
        ),
        swapAnimationDuration: const Duration(milliseconds: 300),
        swapAnimationCurve: Curves.easeOutCubic,
      ),
    );
  }

  List<PieChartSectionData> _buildPieSections(
    BuildContext context, {
    required List<String> categories,
    required bool compact,
    required bool tablet,
  }) {
    return List.generate(categories.length, (index) {
      final category = categories[index];
      final amount = widget.categoryTotals[category] ?? 0;
      final color = colors[index % colors.length];

      final isSelected = selectedCategory == category;

      final normalRadius = compact
          ? 48.0
          : tablet
          ? 58.0
          : 66.0;

      final selectedRadius = compact
          ? 56.0
          : tablet
          ? 66.0
          : 74.0;

      return PieChartSectionData(
        color: color,
        value: amount,
        radius: isSelected ? selectedRadius : normalRadius,

        // Important:
        // Do NOT display category/amount inside the pie chart.
        title: '',

        showTitle: false,

        borderSide: isSelected
            ? BorderSide(
                color: Theme.of(context).colorScheme.surface,
                width: compact ? 3 : 4,
              )
            : BorderSide.none,
      );
    });
  }

  Widget _buildChartHint(BuildContext context, {required bool compact}) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 12 : 16,
        vertical: compact ? 10 : 12,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withOpacity(.45),
        borderRadius: BorderRadius.circular(compact ? 12 : 14),
      ),
      child: Row(
        children: [
          Icon(
            Icons.touch_app_rounded,
            size: compact ? 18 : 20,
            color: theme.colorScheme.primary,
          ),
          SizedBox(width: compact ? 8 : 10),
          Expanded(
            child: Text(
              'Tap a section of the chart or a category below to view its details.',
              style: theme.textTheme.bodySmall?.copyWith(
                fontSize: compact ? 11 : 12,
                color: theme.colorScheme.onSurface.withOpacity(.65),
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedCategoryDetails(
    BuildContext context, {
    required String category,
    required bool compact,
  }) {
    final theme = Theme.of(context);
    final color = _categoryColor(category);

    final amount = widget.categoryTotals[category] ?? 0;
    final percentage = _percentageFor(category);
    final rank = _rankFor(category);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(compact ? 12 : 16),
      decoration: BoxDecoration(
        color: color.withOpacity(.08),
        borderRadius: BorderRadius.circular(compact ? 14 : 16),
        border: Border.all(color: color.withOpacity(.20)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: compact ? 38 : 44,
                height: compact ? 38 : 44,
                decoration: BoxDecoration(
                  color: color.withOpacity(.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.category_rounded,
                  color: color,
                  size: compact ? 20 : 23,
                ),
              ),

              SizedBox(width: compact ? 10 : 12),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      category,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontSize: compact ? 14 : 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Category details',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontSize: compact ? 10 : 11,
                        color: theme.colorScheme.onSurface.withOpacity(.55),
                      ),
                    ),
                  ],
                ),
              ),

              IconButton(
                tooltip: 'Close details',
                visualDensity: VisualDensity.compact,
                onPressed: () {
                  setState(() {
                    selectedCategory = null;
                  });
                },
                icon: const Icon(Icons.close_rounded),
              ),
            ],
          ),

          SizedBox(height: compact ? 12 : 16),

          Row(
            children: [
              Expanded(
                child: _buildDetailMetric(
                  context,
                  icon: Icons.payments_rounded,
                  label: 'Spent',
                  value: CurrencyFormatter.format(amount),
                  color: color,
                  compact: compact,
                ),
              ),

              SizedBox(width: compact ? 8 : 12),

              Expanded(
                child: _buildDetailMetric(
                  context,
                  icon: Icons.pie_chart_rounded,
                  label: 'Share',
                  value: '${percentage.toStringAsFixed(1)}%',
                  color: color,
                  compact: compact,
                ),
              ),

              SizedBox(width: compact ? 8 : 12),

              Expanded(
                child: _buildDetailMetric(
                  context,
                  icon: Icons.leaderboard_rounded,
                  label: 'Rank',
                  value: '#$rank',
                  color: color,
                  compact: compact,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailMetric(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    required bool compact,
  }) {
    final theme = Theme.of(context);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 10,
        vertical: compact ? 9 : 11,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withOpacity(.65),
        borderRadius: BorderRadius.circular(compact ? 10 : 12),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: compact ? 16 : 18),

          SizedBox(height: compact ? 4 : 6),

          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              maxLines: 1,
              style: theme.textTheme.titleSmall?.copyWith(
                fontSize: compact ? 12 : 13,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          const SizedBox(height: 2),

          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(
              fontSize: compact ? 9 : 10,
              color: theme.colorScheme.onSurface.withOpacity(.55),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryList(
    BuildContext context, {
    required bool compact,
    required double sectionSpacing,
  }) {
    final categories = widget.categoryTotals.entries.toList();

    return Column(
      children: [
        Row(
          children: [
            Icon(
              Icons.category_rounded,
              size: compact ? 18 : 20,
              color: Theme.of(context).colorScheme.primary,
            ),

            SizedBox(width: compact ? 7 : 8),

            Text(
              'Categories',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontSize: compact ? 12 : 14,
                fontWeight: FontWeight.bold,
              ),
            ),

            const Spacer(),

            Text(
              '${categories.length} categories',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontSize: compact ? 9 : 10,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(.5),
              ),
            ),
          ],
        ),

        SizedBox(height: compact ? 10 : 12),

        Column(
          children: [
            for (int index = 0; index < categories.length; index++)
              Padding(
                padding: EdgeInsets.only(
                  bottom: index == categories.length - 1
                      ? 0
                      : compact
                      ? 8
                      : 10,
                ),
                child: _buildCategoryItem(
                  context,
                  category: categories[index].key,
                  amount: categories[index].value,
                  color: colors[index % colors.length],
                  compact: compact,
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildCategoryItem(
    BuildContext context, {
    required String category,
    required double amount,
    required Color color,
    required bool compact,
  }) {
    final theme = Theme.of(context);
    final isSelected = selectedCategory == category;
    final percentage = _percentageFor(category);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(compact ? 12 : 14),
        onTap: () => _selectCategory(category),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 10 : 12,
            vertical: compact ? 9 : 11,
          ),
          decoration: BoxDecoration(
            color: isSelected
                ? color.withOpacity(.12)
                : theme.colorScheme.surfaceContainerHighest.withOpacity(.35),
            borderRadius: BorderRadius.circular(compact ? 12 : 14),
            border: Border.all(
              color: isSelected ? color.withOpacity(.35) : Colors.transparent,
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: compact ? 30 : 34,
                height: compact ? 30 : 34,
                decoration: BoxDecoration(
                  color: color.withOpacity(.14),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.category_rounded,
                  size: compact ? 15 : 17,
                  color: color,
                ),
              ),

              SizedBox(width: compact ? 9 : 11),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      category,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontSize: compact ? 11 : 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),

                    const SizedBox(height: 2),

                    Text(
                      '${percentage.toStringAsFixed(1)}% of spending',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontSize: compact ? 9 : 10,
                        color: theme.colorScheme.onSurface.withOpacity(.50),
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(width: compact ? 8 : 12),

              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  CurrencyFormatter.format(amount),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontSize: compact ? 11 : 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              SizedBox(width: compact ? 4 : 6),

              Icon(
                isSelected
                    ? Icons.keyboard_arrow_up_rounded
                    : Icons.chevron_right_rounded,
                size: compact ? 18 : 20,
                color: isSelected
                    ? color
                    : theme.colorScheme.onSurface.withOpacity(.4),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(
    BuildContext context, {
    required bool compact,
    required bool tablet,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(
        vertical: compact
            ? 10
            : tablet
            ? 16
            : 20,
      ),
      child: EmptyState(
        icon: Icons.pie_chart_outline_rounded,
        title: "No Spending Data",
        message: "Add some expenses to view category analysis.",
        action: ElevatedButton.icon(
          icon: Icon(Icons.receipt_long_rounded, size: compact ? 18 : 20),
          label: Text(
            "Add Expense",
            style: TextStyle(fontSize: compact ? 13 : 14),
          ),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AddExpenseScreen()),
            );
          },
        ),
      ),
    );
  }

  double _chartHeight({
    required bool compact,
    required bool tablet,
    required bool desktop,
    required bool landscape,
  }) {
    if (desktop) {
      return landscape ? 230 : 270;
    }

    if (tablet) {
      return landscape ? 185 : 240;
    }

    if (compact) {
      return landscape ? 145 : 195;
    }

    return landscape ? 155 : 225;
  }
}
