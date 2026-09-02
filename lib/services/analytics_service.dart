import '../models/analytics_summary.dart';
import '../models/analytics_period.dart';

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
    final Map<String, double> monthlyTotals = {};

    for (final expense in expenses) {
      final amount = double.tryParse(expense["amount"].toString()) ?? 0;

      totalSpending += amount;

      final category = expense["category"] ?? "Other";

      categoryTotals[category] = (categoryTotals[category] ?? 0) + amount;

      final date = DateTime.parse(expense["created_at"]);

      final monthKey = '${date.year}-${date.month.toString().padLeft(2, '0')}';

      monthlyTotals[monthKey] = (monthlyTotals[monthKey] ?? 0) + amount;
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

    // Category totals are calculated from the already-filtered expenses.
    // This keeps analytics consistent with the selected time period.
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

  List<dynamic> _filterExpensesByPeriod(
    List<dynamic> expenses,
    AnalyticsPeriod period,
  ) {
    if (period == AnalyticsPeriod.allTime) {
      return expenses;
    }

    final now = DateTime.now();

    late DateTime startDate;
    late DateTime endDate;

    switch (period) {
      case AnalyticsPeriod.thisMonth:
        startDate = DateTime(now.year, now.month, 1);
        endDate = DateTime(now.year, now.month + 1, 1);
        break;

      case AnalyticsPeriod.lastMonth:
        startDate = DateTime(now.year, now.month - 1, 1);
        endDate = DateTime(now.year, now.month, 1);
        break;

      case AnalyticsPeriod.last3Months:
        startDate = DateTime(now.year, now.month - 2, 1);
        endDate = DateTime(now.year, now.month + 1, 1);
        break;

      case AnalyticsPeriod.last6Months:
        startDate = DateTime(now.year, now.month - 5, 1);
        endDate = DateTime(now.year, now.month + 1, 1);
        break;

      case AnalyticsPeriod.thisYear:
        startDate = DateTime(now.year, 1, 1);
        endDate = DateTime(now.year + 1, 1, 1);
        break;

      case AnalyticsPeriod.allTime:
        return expenses;
    }

    return expenses.where((expense) {
      try {
        final date = DateTime.parse(expense['created_at'].toString());

        return !date.isBefore(startDate) && date.isBefore(endDate);
      } catch (_) {
        return false;
      }
    }).toList();
  }

  Future<AnalyticsSummary> loadAnalytics({
    AnalyticsPeriod period = AnalyticsPeriod.thisMonth,
  }) async {
    final analytics = await repository.refreshAnalytics();

    return processAnalyticsData(analytics: analytics, period: period);
  }

  Future<AnalyticsSummary> processAnalyticsData({
    required Map<String, dynamic> analytics,
    required AnalyticsPeriod period,
  }) async {
    final allExpenses = analytics["expenses"]["data"] ?? [];

    final filteredExpenses = _filterExpensesByPeriod(allExpenses, period);

    return processAnalytics(
      expenses: filteredExpenses,
      goalAnalytics: analytics["goalAnalytics"],
      financialInsights: analytics["financialInsights"],
    );
  }
}
