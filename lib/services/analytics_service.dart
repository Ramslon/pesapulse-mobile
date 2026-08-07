import '../models/analytics_summary.dart';

import '../repositories/analytics_repository.dart';

class AnalyticsService {
  final AnalyticsRepository repository;

  AnalyticsService(this.repository);
  AnalyticsSummary processAnalytics({
    required List expenses,
    required Map<String, dynamic> goalAnalytics,
    required Map<String, dynamic> financialInsights,
  }) {
    double totalSpending = 0;

    final Map<String, double> categoryTotals = {};

    final Map<int, double> monthlyTotals = {};

    for (final expense in expenses) {
      final amount = double.tryParse(expense["amount"].toString()) ?? 0;

      totalSpending += amount;

      final category = expense["category"] ?? "Other";

      categoryTotals[category] = (categoryTotals[category] ?? 0) + amount;

      final date = DateTime.parse(expense["created_at"]);

      monthlyTotals[date.month] = (monthlyTotals[date.month] ?? 0) + amount;
    }

    final totalGoals =
        int.tryParse(goalAnalytics["total_goals"].toString()) ?? 0;

    final completedGoals =
        int.tryParse(goalAnalytics["completed_goals"].toString()) ?? 0;

    final activeGoals =
        int.tryParse(goalAnalytics["active_goals"].toString()) ?? 0;

    final completionRate =
        double.tryParse(goalAnalytics["completion_rate"].toString()) ?? 0;

    final budgetAmount =
        double.tryParse(financialInsights["budget"].toString()) ?? 0;

    final budgetSpent =
        double.tryParse(financialInsights["spent"].toString()) ?? 0;

    final budgetRemaining =
        double.tryParse(financialInsights["remaining"].toString()) ?? 0;

    final budgetUsage =
        double.tryParse(financialInsights["usage_percentage"].toString()) ?? 0;

    final budgetStatus = financialInsights["status"] ?? "";

    final recommendation = financialInsights["recommendation"] ?? "";

    final categoryAdvice = financialInsights["category_advice"] ?? "";

    final topCategory = financialInsights["top_category"] ?? "";

    if (financialInsights["category_breakdown"] != null) {
      categoryTotals.clear();

      for (final item in financialInsights["category_breakdown"]) {
        categoryTotals[item["category"]] = (item["total"] as num).toDouble();
      }
    }

    final health = calculateHealthScore(
      completionRate: completionRate,
      totalGoals: totalGoals,
      activeGoals: activeGoals,
      totalSpending: totalSpending,
    );

    final insights = generateInsights(
      categoryTotals: categoryTotals,
      completionRate: completionRate,
      healthScore: health.score,
    );

    return AnalyticsSummary(
      expenses: expenses,
      totalSpending: totalSpending,
      categoryTotals: categoryTotals,
      monthlyTotals: monthlyTotals,
      totalGoals: totalGoals,
      completedGoals: completedGoals,
      activeGoals: activeGoals,
      completionRate: completionRate,
      healthScore: health.score,
      healthStatus: health.status,
      budgetAmount: budgetAmount,
      budgetSpent: budgetSpent,
      budgetRemaining: budgetRemaining,
      budgetUsage: budgetUsage,
      budgetStatus: budgetStatus,
      recommendation: recommendation,
      categoryAdvice: categoryAdvice,
      topCategory: topCategory,
      insights: insights,
    );
  }

  ({double score, String status}) calculateHealthScore({
    required double completionRate,
    required int totalGoals,
    required int activeGoals,
    required double totalSpending,
  }) {
    double score = 0;

    score += completionRate * .5;

    if (totalGoals > 0) {
      score += ((totalGoals - activeGoals) / totalGoals) * 25;
    }

    if (totalSpending > 0) {
      score += 25;
    }

    score = score.clamp(0, 100);

    String status;

    if (score >= 80) {
      status = "Excellent";
    } else if (score >= 60) {
      status = "Good";
    } else if (score >= 40) {
      status = "Fair";
    } else {
      status = "Needs Improvement";
    }

    return (score: score, status: status);
  }

  List<String> generateInsights({
    required Map<String, double> categoryTotals,
    required double completionRate,
    required double healthScore,
  }) {
    final List<String> insights = [];

    if (categoryTotals.isNotEmpty) {
      final highest = categoryTotals.entries.reduce(
        (a, b) => a.value > b.value ? a : b,
      );

      insights.add(
        "Highest spending category: ${highest.key} (KES ${highest.value.toStringAsFixed(0)})",
      );
    }

    if (completionRate == 100) {
      insights.add("Excellent! All your financial goals have been completed.");
    } else if (completionRate >= 50) {
      insights.add("Good progress on your financial goals.");
    } else {
      insights.add(
        "Consider increasing savings contributions toward your goals.",
      );
    }

    if (healthScore >= 80) {
      insights.add("Your financial health is excellent.");
    } else {
      insights.add("There is room to improve your financial health score.");
    }

    return insights;
  }

  Future<AnalyticsSummary> loadAnalytics() async {
    final analytics = await repository.getAnalytics();

    return processAnalytics(
      expenses: analytics["expenses"]["data"] ?? [],
      goalAnalytics: analytics["goalAnalytics"],
      financialInsights: analytics["financialInsights"],
    );
  }
}
