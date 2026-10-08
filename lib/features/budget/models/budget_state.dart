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

  factory BudgetState.fromBudgetSummary(
    Map<String, dynamic> data, {
    bool isGuest = false,
  }) {
    final budget = double.tryParse(data["budget"]?.toString() ?? '') ?? 0;

    final spent = double.tryParse(data["spent"]?.toString() ?? '') ?? 0;

    final remaining = double.tryParse(data["remaining"]?.toString() ?? '') ?? 0;

    final budgetCount =
        int.tryParse(data["budget_count"]?.toString() ?? '') ?? 0;

    return BudgetState(
      budget: budget,
      spent: spent,
      remaining: remaining,
      isLoading: false,
      hasCachedBudget: budgetCount > 0 || budget > 0,
      isGuest: isGuest,
    );
  }

  BudgetState copyWithInsights(Map<String, dynamic> insights) {
    final Map<String, double> categories = {};
    final Map<String, double> daily = {};

    final dailyData = insights["daily_spending"];

    if (dailyData is Map) {
      dailyData.forEach((day, value) {
        final parsed = double.tryParse(value?.toString() ?? '');

        if (parsed != null) {
          daily[day.toString()] = parsed;
        }
      });
    }

    final categoryData = insights["category_breakdown"];

    if (categoryData is List) {
      for (final item in categoryData) {
        if (item is! Map) continue;

        final category = item["category"]?.toString() ?? "Other";

        final total = double.tryParse(item["total"]?.toString() ?? '');

        if (total != null) {
          categories[category] = total;
        }
      }
    }

    final highestDayData = insights["highest_spending_day"];

    final highestDay = highestDayData is Map
        ? highestDayData["day"]?.toString() ?? ""
        : "";

    final highestDayAmount = highestDayData is Map
        ? double.tryParse(highestDayData["amount"]?.toString() ?? '') ?? 0.0
        : 0.0;

    final averageDaily =
        double.tryParse(insights["average_daily_spending"]?.toString() ?? '') ??
        0;

    final estimatedMonthEnd =
        double.tryParse(
          insights["estimated_month_end_spending"]?.toString() ?? '',
        ) ??
        0;

    final financialScore =
        int.tryParse(insights["financial_health_score"]?.toString() ?? '') ?? 0;

    return copyWith(
      budgetStatus: insights["budget_status"]?.toString() ?? "healthy",

      recommendation: insights["recommendation"]?.toString() ?? "",

      categoryAdvice: insights["category_advice"]?.toString() ?? "",

      categoryTotals: categories,

      dailySpending: daily,

      highestDay: highestDay,

      highestDayAmount: highestDayAmount,

      averageDaily: averageDaily,

      estimatedMonthEnd: estimatedMonthEnd,

      financialScore: financialScore,

      financialLabel:
          insights["financial_health_label"]?.toString() ?? "No Data",
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
    this.highestDayAmount = 0.0,

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
