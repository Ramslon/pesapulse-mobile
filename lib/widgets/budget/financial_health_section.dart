import 'package:flutter/material.dart';
import '../financial_health_card.dart';
import 'budget_section_header.dart';

class FinancialHealthSection extends StatelessWidget {
  final int financialScore;
  final String financialLabel;

  final double percentageUsed;
  final double budget;
  final double spent;

  final Widget budgetAlert;
  final String categoryAdvice;

  const FinancialHealthSection({
    super.key,
    required this.financialScore,
    required this.financialLabel,
    required this.percentageUsed,
    required this.budget,
    required this.spent,
    required this.budgetAlert,
    required this.categoryAdvice,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    const smallSpacing = 8.0;
    const sectionSpacing = 20.0;
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const BudgetSectionHeader(
          title: "Financial Health",
          subtitle: "Your overall money management score",
        ),

        SizedBox(height: isLandscape ? 12 : sectionSpacing),

        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.9, end: 1),
          duration: const Duration(milliseconds: 700),
          curve: Curves.easeOutBack,
          builder: (context, scale, child) {
            return Transform.scale(scale: scale, child: child);
          },
          child: FinancialHealthCard(
            score: financialScore,
            label: financialLabel,
          ),
        ),

        SizedBox(height: smallSpacing),

        Text(
          "This score is calculated using your budget usage, spending consistency, and savings potential.",
          style: TextStyle(
            color: colorScheme.onSurface.withOpacity(0.7),
            fontSize: 14,
          ),
        ),
        SizedBox(height: isLandscape ? 12 : sectionSpacing),

        Text(
          "${percentageUsed.toStringAsFixed(1)}% Used",
          textAlign: TextAlign.center,
        ),

        SizedBox(height: smallSpacing),

        LinearProgressIndicator(
          value: budget > 0 ? (spent / budget).clamp(0.0, 1.0) : 0,

          color: percentageUsed >= 100
              ? colorScheme.primary
              : percentageUsed >= 80
              ? colorScheme.primary
              : colorScheme.primary,
          minHeight: 10,
          borderRadius: BorderRadius.circular(10),
        ),
        const SizedBox(height: 12),
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: const Duration(milliseconds: 1200),
          builder: (context, opacity, child) {
            return Opacity(opacity: opacity, child: child);
          },
          child: budgetAlert,
        ),

        if (categoryAdvice.isNotEmpty)
          Card(
            margin: const EdgeInsets.only(top: 20),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.lightbulb),
                  const SizedBox(width: 10),
                  Expanded(child: Text(categoryAdvice)),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
