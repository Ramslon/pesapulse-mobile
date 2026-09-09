import '../services/expense_service.dart';
import 'package:flutter/foundation.dart';
import '../repositories/expense_repository.dart';

class ExpenseController {
  final ExpenseService service;
  final ExpenseRepository expenseRepository;

  ExpenseController({
    ExpenseService? service,
    ExpenseRepository? expenseRepository,
  }) : service = service ?? ExpenseService(),
       expenseRepository = expenseRepository ?? ExpenseRepository();

  bool isFetchingMore = false;

  bool hasMore = true;

  int currentPage = 1;

  Future<List<Map<String, dynamic>>> fetchExpenses() async {
    if (isFetchingMore || !hasMore) {
      return [];
    }

    isFetchingMore = true;

    try {
      final Map<String, dynamic> response;

      if (currentPage == 1) {
        debugPrint(
          'ExpenseController: using shared initial expenses request...',
        );

        response = await expenseRepository.refreshExpenses();
      } else {
        response = await service.getExpenses(page: currentPage);
      }

      final List<Map<String, dynamic>> newExpenses =
          (response['data'] as List? ?? [])
              .map((expense) => Map<String, dynamic>.from(expense))
              .toList();

      currentPage++;

      hasMore = response['next_page_url'] != null;

      return newExpenses;
    } finally {
      isFetchingMore = false;
    }
  }

  void resetPagination() {
    currentPage = 1;
    hasMore = true;
    isFetchingMore = false;
  }

  Future<void> deleteExpense(dynamic id) {
    return service.deleteExpense(id);
  }
}
