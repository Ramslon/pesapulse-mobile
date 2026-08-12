class ExpenseFilters {
  ExpenseFilters._();

  /// Filters expenses by search query, category, and date filter,
  /// then applies the selected sort.
  static List<Map<String, dynamic>> filter({
    required List<Map<String, dynamic>> expenses,
    required String searchQuery,
    required String selectedCategory,
    required String selectedDateFilter,
    required String selectedSort,
    required String Function(String date) formatDate,
  }) {
    List<Map<String, dynamic>> result = List<Map<String, dynamic>>.from(
      expenses,
    );

    // ─────────────────────────────────────────────
    // Search
    // ─────────────────────────────────────────────

    final query = searchQuery.trim().toLowerCase();

    if (query.isNotEmpty) {
      result = result.where((expense) {
        final title = (expense["title"] ?? "").toString().toLowerCase();

        final category = (expense["category"] ?? "").toString().toLowerCase();

        final description = (expense["description"] ?? "")
            .toString()
            .toLowerCase();

        final amount = (expense["amount"] ?? "").toString().toLowerCase();

        final date = formatDate(
          expense["expense_date"].toString(),
        ).toLowerCase();

        return title.contains(query) ||
            category.contains(query) ||
            description.contains(query) ||
            amount.contains(query) ||
            date.contains(query);
      }).toList();
    }

    // ─────────────────────────────────────────────
    // Category
    // ─────────────────────────────────────────────

    if (selectedCategory != "All") {
      final selected = selectedCategory.trim().toLowerCase();

      result = result.where((expense) {
        final category = (expense["category"] ?? "")
            .toString()
            .trim()
            .toLowerCase();

        return category == selected;
      }).toList();
    }

    // ─────────────────────────────────────────────
    // Date
    // ─────────────────────────────────────────────

    result = _applyDateFilter(result, selectedDateFilter);

    // ─────────────────────────────────────────────
    // Sort
    // ─────────────────────────────────────────────

    _sortExpenses(result, selectedSort);

    return result;
  }

  static List<Map<String, dynamic>> _applyDateFilter(
    List<Map<String, dynamic>> expenses,
    String selectedDateFilter,
  ) {
    final now = DateTime.now();

    final today = DateTime(now.year, now.month, now.day);

    return expenses.where((expense) {
      final rawDate = expense["expense_date"];

      if (rawDate == null) return false;

      final parsedDate = DateTime.tryParse(rawDate.toString());

      if (parsedDate == null) return false;

      final date = DateTime(parsedDate.year, parsedDate.month, parsedDate.day);

      switch (selectedDateFilter) {
        case "Today":
          return date == today;

        case "This Week":
          final startOfWeek = today.subtract(Duration(days: today.weekday - 1));

          final endOfWeek = startOfWeek.add(const Duration(days: 6));

          return !date.isBefore(startOfWeek) && !date.isAfter(endOfWeek);

        case "This Month":
          return date.year == today.year && date.month == today.month;

        case "All":
        default:
          return true;
      }
    }).toList();
  }

  static void _sortExpenses(
    List<Map<String, dynamic>> expenses,
    String selectedSort,
  ) {
    switch (selectedSort) {
      case "Newest":
        expenses.sort(
          (a, b) => _parseDate(
            b["expense_date"],
          ).compareTo(_parseDate(a["expense_date"])),
        );
        break;

      case "Oldest":
        expenses.sort(
          (a, b) => _parseDate(
            a["expense_date"],
          ).compareTo(_parseDate(b["expense_date"])),
        );
        break;

      case "Highest Amount":
        expenses.sort(
          (a, b) =>
              _parseAmount(b["amount"]).compareTo(_parseAmount(a["amount"])),
        );
        break;

      case "Lowest Amount":
        expenses.sort(
          (a, b) =>
              _parseAmount(a["amount"]).compareTo(_parseAmount(b["amount"])),
        );
        break;

      case "A-Z":
        expenses.sort(
          (a, b) => a["title"].toString().toLowerCase().compareTo(
            b["title"].toString().toLowerCase(),
          ),
        );
        break;

      case "Z-A":
        expenses.sort(
          (a, b) => b["title"].toString().toLowerCase().compareTo(
            a["title"].toString().toLowerCase(),
          ),
        );
        break;
    }
  }

  static DateTime _parseDate(dynamic value) {
    return DateTime.tryParse(value?.toString() ?? "") ?? DateTime(1970);
  }

  static double _parseAmount(dynamic value) {
    return double.tryParse(value?.toString() ?? "") ?? 0;
  }
}
