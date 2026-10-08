import 'package:flutter/foundation.dart';

import 'package:pesapulse_mobile/repositories/budget_repository.dart';
import 'package:pesapulse_mobile/repositories/financial_insights_repository.dart';
import 'package:pesapulse_mobile/services/startup_refresh_coordinator.dart';
import 'package:pesapulse_mobile/services/session_service.dart';

import '../models/budget_state.dart';

class BudgetController {
  final BudgetRepository budgetRepository;
  final FinancialInsightsRepository insightsRepository;

  BudgetController({
    required this.budgetRepository,
    required this.insightsRepository,
  });

  // ---------------------------------------------------------------------------
  // LOAD BUDGET SUMMARY
  // ---------------------------------------------------------------------------

  Future<Map<String, dynamic>> loadBudget({int? month, int? year}) async {
    return await budgetRepository.getBudgetSummary(month: month, year: year);
  }

  // ---------------------------------------------------------------------------
  // LOAD FINANCIAL INSIGHTS
  // ---------------------------------------------------------------------------

  Future<Map<String, dynamic>> loadInsights({int? month, int? year}) async {
    return await insightsRepository.getInsights(month: month, year: year);
  }

  // ---------------------------------------------------------------------------
  // LOAD BUDGET + INSIGHTS
  // ---------------------------------------------------------------------------

  Future<BudgetState> loadAll({int? month, int? year}) async {
    debugPrint(
      'BudgetController: requesting budget-summary '
      'month=$month year=$year...',
    );

    final periodKey = _periodKey(month: month, year: year);

    final budgetData = await StartupRefreshCoordinator.instance.run(
      'budget-summary-$periodKey',
      () async {
        return await budgetRepository.getBudgetSummary(
          month: month,
          year: year,
        );
      },
    );

    debugPrint(
      'BudgetController: budget-summary completed '
      'month=$month year=$year.',
    );

    BudgetState state = BudgetState.fromBudgetSummary(
      budgetData,
      isGuest: await SessionService.isGuest(),
    );

    // Insights are supplementary.
    //
    // If they fail, the budget itself should still remain usable.
    try {
      final insights = await StartupRefreshCoordinator.instance.run(
        'financial-insights-$periodKey',
        () async {
          return await insightsRepository.getInsights(month: month, year: year);
        },
      );

      state = state.copyWithInsights(insights);
    } catch (error) {
      debugPrint(
        'BudgetController: financial insights failed '
        'for $periodKey: $error',
      );

      // Keep budget state even if insights fail.
    }

    return state;
  }

  // ---------------------------------------------------------------------------
  // SAVE BUDGET
  // ---------------------------------------------------------------------------

  Future<BudgetState> saveBudget({
    required double amount,
    int? month,
    int? year,
  }) async {
    final resolvedMonth = month ?? DateTime.now().month;
    final resolvedYear = year ?? DateTime.now().year;

    await budgetRepository.saveBudget(
      amount: amount,
      month: resolvedMonth,
      year: resolvedYear,
    );

    // Reload the same period that was saved.
    return await loadAll(month: month, year: year);
  }

  // ---------------------------------------------------------------------------
  // DELETE BUDGET
  // ---------------------------------------------------------------------------

  Future<BudgetState> deleteBudget({int? month, int? year}) async {
    final resolvedMonth = month ?? DateTime.now().month;
    final resolvedYear = year ?? DateTime.now().year;

    await budgetRepository.deleteBudget(
      month: resolvedMonth,
      year: resolvedYear,
    );

    // Reload the same period after deletion.
    //
    // This is important for historical budgets because the user should remain
    // on the selected month rather than being sent to an empty/default state.
    return await loadAll(month: month, year: year);
  }

  // ---------------------------------------------------------------------------
  // PERIOD KEY
  // ---------------------------------------------------------------------------

  String _periodKey({int? month, int? year}) {
    if (month == null || year == null) {
      return 'current';
    }

    return '$year-${month.toString().padLeft(2, '0')}';
  }
}
