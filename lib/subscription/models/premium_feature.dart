enum PremiumFeature {
  advancedBudgetInsights,
  advancedAnalytics,
  spendingForecast,
  advancedGoalTracking,
  advancedGoalForecast,
  budgetSimulation,
  historicalInsights,
}

extension PremiumFeatureExtension on PremiumFeature {
  String get title {
    switch (this) {
      case PremiumFeature.advancedBudgetInsights:
        return 'Advanced Budget Insights';

      case PremiumFeature.advancedAnalytics:
        return 'Advanced Analytics';

      case PremiumFeature.spendingForecast:
        return 'Spending Forecast';

      case PremiumFeature.advancedGoalTracking:
        return 'Advanced Goal Tracking';

      case PremiumFeature.advancedGoalForecast:
        return 'Goal Forecast';

      case PremiumFeature.budgetSimulation:
        return 'Budget Simulation';

      case PremiumFeature.historicalInsights:
        return 'Historical Insights';
    }
  }

  String get description {
    switch (this) {
      case PremiumFeature.advancedBudgetInsights:
        return 'Get deeper recommendations and smarter budget insights.';

      case PremiumFeature.advancedAnalytics:
        return 'Unlock deeper spending trends, comparisons and reports.';

      case PremiumFeature.spendingForecast:
        return 'See projected spending and estimated month-end totals.';

      case PremiumFeature.advancedGoalTracking:
        return 'Track goal progress with advanced savings insights.';

      case PremiumFeature.advancedGoalForecast:
        return 'Predict when you are likely to reach your savings goal.';

      case PremiumFeature.budgetSimulation:
        return 'Explore different spending and budget scenarios.';

      case PremiumFeature.historicalInsights:
        return 'Compare your financial performance across previous periods.';
    }
  }
}
