import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

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

  static const Color _foodColor = Color(0xFFF59E0B);
  static const Color _transportColor = Color(0xFF2563EB);
  static const Color _shoppingColor = Color(0xFF7C3AED);
  static const Color _billsColor = Color(0xFFE53935);
  static const Color _entertainmentColor = Color(0xFFDB2777);
  static const Color _healthColor = Color(0xFF16A34A);
  static const Color _educationColor = Color(0xFF0891B2);
  static const Color _otherColor = Color(0xFF64748B);

  @override
  void didUpdateWidget(covariant BudgetBreakdownCard oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (selectedCategory != null &&
        !widget.categoryTotals.containsKey(selectedCategory)) {
      setState(() {
        selectedCategory = null;
      });
    }
  }

  List<MapEntry<String, double>> get _sortedCategories {
    return widget.categoryTotals.entries
        .where((entry) => entry.value > 0)
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value));
  }

  Color _categoryColor(String category) {
    final normalized = category.trim().toLowerCase();

    switch (normalized) {
      case 'food':
      case 'groceries':
      case 'restaurant':
      case 'restaurants':
        return _foodColor;

      case 'transport':
      case 'transportation':
      case 'travel':
        return _transportColor;

      case 'shopping':
        return _shoppingColor;

      case 'bills':
      case 'utilities':
        return _billsColor;

      case 'entertainment':
        return _entertainmentColor;

      case 'health':
      case 'medical':
        return _healthColor;

      case 'education':
        return _educationColor;

      default:
        final index = _sortedCategories.indexWhere(
          (entry) => entry.key == category,
        );

        const fallbackColors = [
          _foodColor,
          _transportColor,
          _shoppingColor,
          _billsColor,
          _entertainmentColor,
          _healthColor,
          _educationColor,
          _otherColor,
        ];

        if (index < 0) {
          return _otherColor;
        }

        return fallbackColors[index % fallbackColors.length];
    }
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
    final categories = _sortedCategories;

    final index = categories.indexWhere((entry) => entry.key == category);

    return index < 0 ? 0 : index + 1;
  }

  @override
  Widget build(BuildContext context) {
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
          title: 'Budget Breakdown',
          subtitle: 'See where your spending is being allocated',
        ),

        SizedBox(
          height: compact
              ? 14
              : tablet
              ? 18
              : 20,
        ),

        _buildCard(
          context,
          compact: compact,
          tablet: tablet,
          desktop: desktop,
          landscape: landscape,
          cardPadding: cardPadding,
          sectionSpacing: sectionSpacing,
        ),
      ],
    );
  }

  Widget _buildCard(
    BuildContext context, {
    required bool compact,
    required bool tablet,
    required bool desktop,
    required bool landscape,
    required double cardPadding,
    required double sectionSpacing,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final radius = desktop
        ? 22.0
        : compact
        ? 17.0
        : 20.0;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: colorScheme.outline.withOpacity(0.08)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(
              theme.brightness == Brightness.dark ? 0.07 : 0.035,
            ),
            blurRadius: desktop ? 20 : 14,
            offset: const Offset(0, 6),
          ),
        ],
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
    final categories = _sortedCategories;

    if (categories.isEmpty) {
      return _buildEmptyState(context, compact: compact, tablet: tablet);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSummaryHeader(
          context,
          categories: categories,
          compact: compact,
          desktop: desktop,
        ),

        SizedBox(
          height: compact
              ? 12
              : desktop
              ? 18
              : 15,
        ),

        _buildChart(
          context,
          categories: categories,
          compact: compact,
          tablet: tablet,
          desktop: desktop,
          landscape: landscape,
        ),

        SizedBox(height: compact ? 13 : 17),

        AnimatedSwitcher(
          duration: const Duration(milliseconds: 260),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          child: selectedCategory == null
              ? _buildChartHint(context, compact: compact)
              : KeyedSubtree(
                  key: ValueKey(selectedCategory),
                  child: _buildSelectedCategoryDetails(
                    context,
                    category: selectedCategory!,
                    compact: compact,
                    desktop: desktop,
                  ),
                ),
        ),

        SizedBox(height: compact ? 14 : 18),

        Divider(
          height: 1,
          color: Theme.of(context).colorScheme.outline.withOpacity(0.08),
        ),

        SizedBox(height: compact ? 12 : 15),

        _buildCategoryList(
          context,
          categories: categories,
          compact: compact,
          desktop: desktop,
        ),
      ],
    );
  }

  Widget _buildSummaryHeader(
    BuildContext context, {
    required List<MapEntry<String, double>> categories,
    required bool compact,
    required bool desktop,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final topCategory = categories.first.key;
    final topAmount = categories.first.value;
    final topPercentage = _percentageFor(topCategory);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Spending Allocation',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: colorScheme.onSurface,
                  fontSize: desktop
                      ? 15
                      : compact
                      ? 12.5
                      : 14,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.1,
                ),
              ),

              const SizedBox(height: 3),

              Text(
                '$topCategory is your largest spending category',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: colorScheme.onSurfaceVariant.withOpacity(0.65),
                  fontSize: desktop
                      ? 11.5
                      : compact
                      ? 9.5
                      : 10.5,
                  height: 1.25,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(width: 10),

        Container(
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 8 : 10,
            vertical: compact ? 5 : 6,
          ),
          decoration: BoxDecoration(
            color: _categoryColor(topCategory).withOpacity(0.08),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: _categoryColor(topCategory).withOpacity(0.10),
            ),
          ),
          child: Column(
            children: [
              Text(
                CurrencyFormatter.format(topAmount),
                maxLines: 1,
                style: TextStyle(
                  color: colorScheme.onSurface,
                  fontSize: compact ? 9.5 : 11,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${topPercentage.toStringAsFixed(0)}%',
                style: TextStyle(
                  color: _categoryColor(topCategory),
                  fontSize: compact ? 8 : 9,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildChart(
    BuildContext context, {
    required List<MapEntry<String, double>> categories,
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
      width: double.infinity,
      height: chartHeight,
      child: PieChart(
        PieChartData(
          sectionsSpace: compact ? 2 : 3,
          centerSpaceRadius: compact
              ? 38
              : tablet
              ? 44
              : 50,
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

              _selectCategory(categories[touchedIndex].key);
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
    required List<MapEntry<String, double>> categories,
    required bool compact,
    required bool tablet,
  }) {
    final normalRadius = compact
        ? 46.0
        : tablet
        ? 55.0
        : 63.0;

    final selectedRadius = compact
        ? 53.0
        : tablet
        ? 63.0
        : 71.0;

    final surface = Theme.of(context).colorScheme.surface;

    return List.generate(categories.length, (index) {
      final category = categories[index].key;
      final amount = categories[index].value;
      final color = _categoryColor(category);

      final isSelected = selectedCategory == category;

      return PieChartSectionData(
        color: color,
        value: amount,
        radius: isSelected ? selectedRadius : normalRadius,
        title: '',
        showTitle: false,
        borderSide: isSelected
            ? BorderSide(color: surface, width: compact ? 3 : 4)
            : BorderSide.none,
      );
    });
  }

  Widget _buildChartHint(BuildContext context, {required bool compact}) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 10 : 13,
        vertical: compact ? 9 : 11,
      ),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withOpacity(0.42),
        borderRadius: BorderRadius.circular(compact ? 12 : 14),
      ),
      child: Row(
        children: [
          Container(
            width: compact ? 27 : 30,
            height: compact ? 27 : 30,
            decoration: BoxDecoration(
              color: colorScheme.primary.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.touch_app_rounded,
              size: compact ? 14 : 16,
              color: colorScheme.primary,
            ),
          ),

          SizedBox(width: compact ? 8 : 9),

          Expanded(
            child: Text(
              'Tap a category to inspect its spending share and rank.',
              style: TextStyle(
                color: colorScheme.onSurfaceVariant.withOpacity(0.68),
                fontSize: compact ? 9.5 : 10.5,
                height: 1.3,
                fontWeight: FontWeight.w500,
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
    required bool desktop,
  }) {
    final theme = Theme.of(context);
    final color = _categoryColor(category);

    final amount = widget.categoryTotals[category] ?? 0;

    final percentage = _percentageFor(category);

    final rank = _rankFor(category);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(
        desktop
            ? 15
            : compact
            ? 11
            : 14,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(
          theme.brightness == Brightness.dark ? 0.10 : 0.055,
        ),
        borderRadius: BorderRadius.circular(compact ? 14 : 16),
        border: Border.all(color: color.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: compact ? 34 : 40,
                height: compact ? 34 : 40,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.11),
                  borderRadius: BorderRadius.circular(compact ? 10 : 12),
                ),
                child: Icon(
                  Icons.category_rounded,
                  color: color,
                  size: compact ? 17 : 20,
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
                      style: TextStyle(
                        color: theme.colorScheme.onSurface,
                        fontSize: compact ? 13 : 14.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),

                    const SizedBox(height: 2),

                    Text(
                      'Selected spending category',
                      style: TextStyle(
                        color: theme.colorScheme.onSurfaceVariant.withOpacity(
                          0.58,
                        ),
                        fontSize: compact ? 9 : 10,
                      ),
                    ),
                  ],
                ),
              ),

              InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () {
                  setState(() {
                    selectedCategory = null;
                  });
                },
                child: Padding(
                  padding: const EdgeInsets.all(5),
                  child: Icon(
                    Icons.close_rounded,
                    size: compact ? 17 : 19,
                    color: theme.colorScheme.onSurfaceVariant.withOpacity(0.60),
                  ),
                ),
              ),
            ],
          ),

          SizedBox(height: compact ? 10 : 13),

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

              SizedBox(width: compact ? 7 : 9),

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

              SizedBox(width: compact ? 7 : 9),

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
    final colorScheme = theme.colorScheme;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 7 : 9,
        vertical: compact ? 8 : 10,
      ),
      decoration: BoxDecoration(
        color: colorScheme.surface.withOpacity(0.62),
        borderRadius: BorderRadius.circular(compact ? 10 : 12),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: compact ? 15 : 17),

          SizedBox(height: compact ? 4 : 5),

          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              maxLines: 1,
              style: TextStyle(
                color: colorScheme.onSurface,
                fontSize: compact ? 11.5 : 13,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),

          const SizedBox(height: 2),

          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: colorScheme.onSurfaceVariant.withOpacity(0.55),
              fontSize: compact ? 8.5 : 9.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryList(
    BuildContext context, {
    required List<MapEntry<String, double>> categories,
    required bool compact,
    required bool desktop,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Categories',
              style: TextStyle(
                color: colorScheme.onSurface,
                fontSize: desktop
                    ? 14
                    : compact
                    ? 11.5
                    : 13,
                fontWeight: FontWeight.w800,
              ),
            ),

            const Spacer(),

            Text(
              '${categories.length} categories',
              style: TextStyle(
                color: colorScheme.onSurfaceVariant.withOpacity(0.55),
                fontSize: desktop
                    ? 10
                    : compact
                    ? 8.5
                    : 9.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),

        SizedBox(height: compact ? 9 : 11),

        Column(
          children: [
            for (int index = 0; index < categories.length; index++)
              Padding(
                padding: EdgeInsets.only(
                  bottom: index == categories.length - 1
                      ? 0
                      : compact
                      ? 7
                      : 9,
                ),
                child: _buildCategoryItem(
                  context,
                  category: categories[index].key,
                  amount: categories[index].value,
                  color: _categoryColor(categories[index].key),
                  rank: index + 1,
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
    required int rank,
    required bool compact,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

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
            horizontal: compact ? 9 : 11,
            vertical: compact ? 9 : 10,
          ),
          decoration: BoxDecoration(
            color: isSelected
                ? color.withOpacity(
                    theme.brightness == Brightness.dark ? 0.11 : 0.065,
                  )
                : colorScheme.surfaceContainerHighest.withOpacity(0.32),
            borderRadius: BorderRadius.circular(compact ? 12 : 14),
            border: Border.all(
              color: isSelected ? color.withOpacity(0.25) : Colors.transparent,
            ),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: compact ? 27 : 31,
                    height: compact ? 27 : 31,
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.10),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '$rank',
                        style: TextStyle(
                          color: color,
                          fontSize: compact ? 9 : 10,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),

                  SizedBox(width: compact ? 9 : 10),

                  Expanded(
                    child: Text(
                      category,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: colorScheme.onSurface,
                        fontSize: compact ? 11 : 12.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),

                  const SizedBox(width: 8),

                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      CurrencyFormatter.format(amount),
                      maxLines: 1,
                      style: TextStyle(
                        color: colorScheme.onSurface,
                        fontSize: compact ? 10.5 : 12,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),

                  const SizedBox(width: 5),

                  Icon(
                    isSelected
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.chevron_right_rounded,
                    size: compact ? 17 : 19,
                    color: isSelected
                        ? color
                        : colorScheme.onSurfaceVariant.withOpacity(0.42),
                  ),
                ],
              ),

              SizedBox(height: compact ? 6 : 7),

              Row(
                children: [
                  const SizedBox(width: 36),

                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: LinearProgressIndicator(
                        minHeight: compact ? 4 : 5,
                        value: (percentage / 100).clamp(0.0, 1.0),
                        backgroundColor: colorScheme.outline.withOpacity(0.07),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          color.withOpacity(isSelected ? 0.95 : 0.70),
                        ),
                      ),
                    ),
                  ),

                  SizedBox(width: compact ? 7 : 9),

                  SizedBox(
                    width: compact ? 34 : 40,
                    child: Text(
                      '${percentage.toStringAsFixed(0)}%',
                      textAlign: TextAlign.end,
                      style: TextStyle(
                        color: colorScheme.onSurfaceVariant.withOpacity(0.58),
                        fontSize: compact ? 8.5 : 9.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: EdgeInsets.symmetric(
        vertical: compact
            ? 12
            : tablet
            ? 18
            : 22,
      ),
      child: Column(
        children: [
          Container(
            width: compact ? 54 : 64,
            height: compact ? 54 : 64,
            decoration: BoxDecoration(
              color: colorScheme.primary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(compact ? 16 : 19),
            ),
            child: Icon(
              Icons.pie_chart_outline_rounded,
              color: colorScheme.primary,
              size: compact ? 25 : 29,
            ),
          ),

          SizedBox(height: compact ? 10 : 12),

          Text(
            'No Spending Data',
            style: TextStyle(
              color: colorScheme.onSurface,
              fontSize: compact ? 13 : 15,
              fontWeight: FontWeight.w800,
            ),
          ),

          const SizedBox(height: 5),

          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 340),
            child: Text(
              'Add some expenses to see how your spending is distributed across categories.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colorScheme.onSurfaceVariant.withOpacity(0.67),
                fontSize: compact ? 10.5 : 11.5,
                height: 1.4,
              ),
            ),
          ),

          SizedBox(height: compact ? 13 : 16),

          SizedBox(
            height: compact ? 36 : 40,
            child: ElevatedButton.icon(
              icon: Icon(Icons.add_rounded, size: compact ? 16 : 18),
              label: Text(
                'Add Expense',
                style: TextStyle(
                  fontSize: compact ? 11 : 12.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AddExpenseScreen()),
                );
              },
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: compact ? 12 : 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
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
      return landscape ? 220 : 245;
    }

    if (tablet) {
      return landscape ? 175 : 220;
    }

    if (compact) {
      return landscape ? 140 : 185;
    }

    return landscape ? 150 : 215;
  }
}
