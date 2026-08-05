class BudgetState {
  final bool isLoading;
  final bool hasCachedBudget;
  final bool isGuest;

  final double budget;
  final double spent;
  final double remaining;

  final Map<String, double> categoryTotals;
  final Map<String, double> dailySpending;

  final String highestDay;
  final double highestDayAmount;

  final double averageDaily;
  final double estimatedMonthEnd;

  final int financialScore;
  final String financialLabel;

  final String recommendation;
  final String categoryAdvice;
  final String budgetStatus;

  factory BudgetState.fromBudgetSummary(Map<String, dynamic> data) {
    final budget = double.tryParse(data["budget"].toString()) ?? 0;

    final spent = double.tryParse(data["spent"].toString()) ?? 0;

    final remaining = double.tryParse(data["remaining"].toString()) ?? 0;

    return BudgetState(
      budget: budget,
      spent: spent,
      remaining: remaining,
      isLoading: false,
      hasCachedBudget: true,
    );
  }

  BudgetState copyWithInsights(Map<String, dynamic> insights) {
    final Map<String, double> categories = {};
    final Map<String, double> daily = {};

    if (insights["daily_spending"] != null) {
      insights["daily_spending"].forEach((day, value) {
        daily[day] = (value as num).toDouble();
      });
    }

    if (insights["category_breakdown"] != null) {
      for (final item in insights["category_breakdown"]) {
        categories[item["category"]] = (item["total"] as num).toDouble();
      }
    }

    return copyWith(
      budgetStatus: insights["budget_status"] ?? "healthy",

      recommendation: insights["recommendation"] ?? "",

      categoryAdvice: insights["category_advice"] ?? "",

      categoryTotals: categories,

      dailySpending: daily,

      highestDay: insights["highest_spending_day"]["day"] ?? "",

      highestDayAmount: (insights["highest_spending_day"]["amount"] as num)
          .toDouble(),

      averageDaily: (insights["average_daily_spending"] as num).toDouble(),

      estimatedMonthEnd: (insights["estimated_month_end_spending"] as num)
          .toDouble(),

      financialScore: insights["financial_health_score"],

      financialLabel: insights["financial_health_label"],
    );
  }

  const BudgetState({
    this.isLoading = true,
    this.hasCachedBudget = true,
    this.isGuest = false,

    this.budget = 0,
    this.spent = 0,
    this.remaining = 0,

    this.categoryTotals = const {},
    this.dailySpending = const {},

    this.highestDay = '',
    this.highestDayAmount = 0,

    this.averageDaily = 0,
    this.estimatedMonthEnd = 0,

    this.financialScore = 100,
    this.financialLabel = '',

    this.recommendation = '',
    this.categoryAdvice = '',
    this.budgetStatus = 'healthy',
  });

  BudgetState copyWith({
    bool? isLoading,
    bool? hasCachedBudget,
    bool? isGuest,

    double? budget,
    double? spent,
    double? remaining,

    Map<String, double>? categoryTotals,
    Map<String, double>? dailySpending,

    String? highestDay,
    double? highestDayAmount,

    double? averageDaily,
    double? estimatedMonthEnd,

    int? financialScore,
    String? financialLabel,

    String? recommendation,
    String? categoryAdvice,
    String? budgetStatus,
  }) {
    return BudgetState(
      isLoading: isLoading ?? this.isLoading,
      hasCachedBudget: hasCachedBudget ?? this.hasCachedBudget,
      isGuest: isGuest ?? this.isGuest,

      budget: budget ?? this.budget,
      spent: spent ?? this.spent,
      remaining: remaining ?? this.remaining,

      categoryTotals: categoryTotals ?? this.categoryTotals,
      dailySpending: dailySpending ?? this.dailySpending,

      highestDay: highestDay ?? this.highestDay,
      highestDayAmount: highestDayAmount ?? this.highestDayAmount,

      averageDaily: averageDaily ?? this.averageDaily,
      estimatedMonthEnd: estimatedMonthEnd ?? this.estimatedMonthEnd,

      financialScore: financialScore ?? this.financialScore,

      financialLabel: financialLabel ?? this.financialLabel,

      recommendation: recommendation ?? this.recommendation,

      categoryAdvice: categoryAdvice ?? this.categoryAdvice,

      budgetStatus: budgetStatus ?? this.budgetStatus,
    );
  }
}
