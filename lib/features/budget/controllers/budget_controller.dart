import 'package:pesapulse_mobile/repositories/budget_repository.dart';
import 'package:pesapulse_mobile/repositories/financial_insights_repository.dart';
import 'package:pesapulse_mobile/services/startup_refresh_coordinator.dart';
import '../models/budget_state.dart';
import 'package:flutter/foundation.dart';

class BudgetController {
  final BudgetRepository budgetRepository;
  final FinancialInsightsRepository insightsRepository;

  BudgetController({
    required this.budgetRepository,
    required this.insightsRepository,
  });

  Future<Map<String, dynamic>> loadBudget() async {
    return await budgetRepository.getBudgetSummary();
  }

  Future<Map<String, dynamic>> loadInsights() async {
    return await insightsRepository.getInsights();
  }

  Future<BudgetState> deleteBudget() async {
    await budgetRepository.deleteBudget();

    return const BudgetState();
  }

  Future<BudgetState> loadAll() async {
    debugPrint('BudgetController: requesting budget-summary...');

    final budgetData = await StartupRefreshCoordinator.instance.run(
      'budget-summary',
      () async {
        return await budgetRepository.getBudgetSummary();
      },
    );

    debugPrint('BudgetController: budget-summary completed.');

    BudgetState state = BudgetState.fromBudgetSummary(budgetData);

    try {
      final insights = await StartupRefreshCoordinator.instance.run(
        'financial-insights',
        () async {
          return await insightsRepository.getInsights();
        },
      );

      state = state.copyWithInsights(insights);
    } catch (_) {
      // Keep the budget visible even if insights fail.
    }

    return state;
  }

  Future<BudgetState> saveBudget({required double amount}) async {
    await budgetRepository.saveBudget(amount: amount);

    return await loadAll();
  }
}
