import '../services/expense_service.dart';

class ExpenseController {
  final ExpenseService service;

  ExpenseController({ExpenseService? service})
    : service = service ?? ExpenseService();

  bool isFetchingMore = false;
  bool hasMore = true;
  int currentPage = 1;

  Future<List<Map<String, dynamic>>> fetchExpenses() async {
    if (isFetchingMore || !hasMore) {
      return [];
    }

    isFetchingMore = true;

    try {
      final response = await service.getExpenses(page: currentPage);

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
