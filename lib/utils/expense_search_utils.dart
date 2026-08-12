class ExpenseSearchUtils {
  ExpenseSearchUtils._();

  static List<String> addRecentSearch({
    required List<String> recentSearches,
    required String query,
    int maxSearches = 5,
  }) {
    final trimmedQuery = query.trim();

    if (trimmedQuery.isEmpty) {
      return List<String>.from(recentSearches);
    }

    final updatedSearches = List<String>.from(recentSearches);

    updatedSearches.remove(trimmedQuery);
    updatedSearches.insert(0, trimmedQuery);

    if (updatedSearches.length > maxSearches) {
      updatedSearches.removeRange(maxSearches, updatedSearches.length);
    }

    return updatedSearches;
  }
}
