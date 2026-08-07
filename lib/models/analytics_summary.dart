class AnalyticsSummary {
  final List expenses;

  final double totalSpending;

  final Map<String, double> categoryTotals;

  final Map<int, double> monthlyTotals;

  final int totalGoals;

  final int completedGoals;

  final int activeGoals;

  final double completionRate;

  final double healthScore;

  final String healthStatus;

  final double budgetAmount;

  final double budgetSpent;

  final double budgetRemaining;

  final double budgetUsage;

  final String budgetStatus;

  final String recommendation;

  final String categoryAdvice;

  final String topCategory;

  final List<String> insights;

  const AnalyticsSummary({
    required this.expenses,
    required this.totalSpending,
    required this.categoryTotals,
    required this.monthlyTotals,
    required this.totalGoals,
    required this.completedGoals,
    required this.activeGoals,
    required this.completionRate,
    required this.healthScore,
    required this.healthStatus,
    required this.budgetAmount,
    required this.budgetSpent,
    required this.budgetRemaining,
    required this.budgetUsage,
    required this.budgetStatus,
    required this.recommendation,
    required this.categoryAdvice,
    required this.topCategory,
    required this.insights,
  });
}
