import '../repositories/expense_repository.dart';

class ExpenseService {
  final ExpenseRepository repository;

  ExpenseService({ExpenseRepository? repository})
    : repository = repository ?? ExpenseRepository();

  Future<Map<String, dynamic>> getExpenses({required int page}) {
    return repository.getExpenses(page: page);
  }

  Future<void> deleteExpense(dynamic id) {
    return repository.deleteExpense(id);
  }
}
