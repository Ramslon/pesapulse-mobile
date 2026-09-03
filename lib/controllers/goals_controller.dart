import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../models/goal.dart';
import '../services/goals_service.dart';
import '../services/notification_service.dart';
import '../services/session_service.dart';

import '../../exceptions/rate_limit_exception.dart';

class GoalsController extends ChangeNotifier {
  final GoalsService goalsService;

  GoalsController({required this.goalsService});

  // ============================================================
  // STATE
  // ============================================================

  bool isLoading = true;

  bool needsRefresh = true;

  bool isGuest = false;

  bool _refreshInProgress = false;

  bool _cacheLoaded = false;

  List<Goal> goals = [];

  Map<int, dynamic> forecasts = {};

  Map<int, dynamic> insights = {};

  Map<String, dynamic> _goalAnalytics = {};

  List<Map<String, dynamic>> _upcomingDeadlines = [];

  Map<String, dynamic> get goalAnalytics => _goalAnalytics;

  List<Map<String, dynamic>> get upcomingDeadlines =>
      List.unmodifiable(_upcomingDeadlines);

  // ============================================================
  // INITIALIZATION
  // ============================================================

  /// Initializes the Goals screen using local cached data first.
  ///
  /// The screen does NOT wait for the API before displaying data.
  ///
  /// For authenticated users, a background refresh is started
  /// after cached data has been loaded.
  Future<void> initialize({bool forceRefresh = false}) async {
    if (_refreshInProgress && !forceRefresh) {
      return;
    }

    try {
      isGuest = await SessionService.isGuest();

      if (isGuest) {
        // Guests should only use local data.
        await _loadCachedData();

        isLoading = false;
        notifyListeners();

        return;
      }

      // --------------------------------------------------------
      // CACHE-FIRST
      // --------------------------------------------------------

      await _loadCachedData();

      isLoading = false;
      notifyListeners();

      // --------------------------------------------------------
      // BACKGROUND REFRESH
      // --------------------------------------------------------

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!hasListeners) return;

        _refreshInBackground(forceRefresh: forceRefresh);
      });
    } catch (e) {
      debugPrint('Failed to initialize GoalsController: $e');

      isLoading = false;
      notifyListeners();

      rethrow;
    }
  }

  // ============================================================
  // CACHE-FIRST DATA LOADING
  // ============================================================

  Future<void> _loadCachedData() async {
    try {
      final results = await Future.wait([
        goalsService.getCachedGoals(),
        goalsService.getCachedAnalytics(),
        goalsService.getCachedUpcomingDeadlines(),
      ]);

      final cachedGoals = results[0] as List<Goal>;

      final cachedAnalytics = results[1] as Map<String, dynamic>;

      final cachedDeadlines = results[2] as List<Map<String, dynamic>>;

      goals = cachedGoals;

      _goalAnalytics = cachedAnalytics;

      _upcomingDeadlines = cachedDeadlines;

      // Forecasts and insights are derived data.
      //
      // Load them from memory/SQLite/local calculation.
      final derivedResults = await Future.wait([
        goalsService.loadCachedForecasts(goals),
        goalsService.loadCachedInsights(goals),
      ]);

      forecasts = Map<int, dynamic>.from(derivedResults[0] as Map);

      insights = Map<int, dynamic>.from(derivedResults[1] as Map);

      _cacheLoaded = true;

      needsRefresh = false;

      debugPrint('Loaded cached goals data.');
    } catch (e) {
      debugPrint('Failed to load cached goals data: $e');

      // If cached goals cannot be loaded, allow the screen to
      // continue into the background/API refresh path.
      //
      // Do not throw here because cache-first loading should
      // degrade gracefully.
    }
  }

  // ============================================================
  // BACKGROUND REFRESH
  // ============================================================

  Future<void> _refreshInBackground({bool forceRefresh = false}) async {
    if (_refreshInProgress) {
      return;
    }

    if (isGuest) {
      return;
    }

    _refreshInProgress = true;

    try {
      if (forceRefresh) {
        goalsService.clearCaches();
      }

      // --------------------------------------------------------
      // Refresh goals first
      // --------------------------------------------------------

      final refreshedGoals = await goalsService.refreshGoals();

      if (!hasListeners) {
        return;
      }

      goals = refreshedGoals;

      needsRefresh = false;

      notifyListeners();

      // --------------------------------------------------------
      // Refresh derived goal data in parallel
      // --------------------------------------------------------

      final derivedResults = await Future.wait([
        goalsService.refreshForecasts(goals),
        goalsService.refreshInsights(goals),
        goalsService.refreshAnalytics(),
        goalsService.refreshUpcomingDeadlines(),
      ]);

      if (!hasListeners) {
        return;
      }

      forecasts = Map<int, dynamic>.from(derivedResults[0] as Map);

      insights = Map<int, dynamic>.from(derivedResults[1] as Map);

      _goalAnalytics = Map<String, dynamic>.from(derivedResults[2] as Map);

      _upcomingDeadlines = (derivedResults[3] as List)
          .map<Map<String, dynamic>>((item) => Map<String, dynamic>.from(item))
          .toList();

      await _processDeadlineNotifications();

      if (!hasListeners) {
        return;
      }

      isLoading = false;

      notifyListeners();

      debugPrint('Goals background refresh completed.');
    } on RateLimitException catch (e) {
      debugPrint('Goals background refresh rate limited: ${e.message}');

      // Keep cached data visible.
      //
      // Do not replace it with an error state.
    } catch (e) {
      debugPrint('Goals background refresh failed: $e');

      // Cached data remains available.
    } finally {
      _refreshInProgress = false;

      if (hasListeners) {
        isLoading = false;
        notifyListeners();
      }
    }
  }

  // ============================================================
  // MANUAL REFRESH
  // ============================================================

  Future<void> refresh() async {
    if (_refreshInProgress) {
      return;
    }

    if (isGuest) {
      await _loadCachedData();

      if (hasListeners) {
        notifyListeners();
      }

      return;
    }

    try {
      await _refreshInBackground(forceRefresh: true);
    } on RateLimitException {
      rethrow;
    }
  }

  // ============================================================
  // SINGLE GOAL REFRESH
  // ============================================================

  Future<void> refreshSingleGoal(int goalId) async {
    try {
      final result = await goalsService.refreshSingleGoal(goalId);

      final index = goals.indexWhere((goal) => goal.id == goalId);

      if (index != -1) {
        final updatedGoals = List<Goal>.from(goals);

        updatedGoals[index] = result.goal;

        goals = updatedGoals;
      }

      final updatedForecasts = Map<int, dynamic>.from(forecasts);

      updatedForecasts[goalId] = result.forecast;

      forecasts = updatedForecasts;

      final updatedInsights = Map<int, dynamic>.from(insights);

      updatedInsights[goalId] = result.insight;

      insights = updatedInsights;

      if (hasListeners) {
        notifyListeners();
      }
    } on RateLimitException {
      rethrow;
    } catch (e) {
      debugPrint('Failed to refresh goal $goalId: $e');
    }
  }

  // ============================================================
  // INVALIDATE SINGLE GOAL
  // ============================================================

  void invalidateGoal(int goalId) {
    goalsService.clearGoalCache(goalId);

    final updatedForecasts = Map<int, dynamic>.from(forecasts);

    updatedForecasts.remove(goalId);

    forecasts = updatedForecasts;

    final updatedInsights = Map<int, dynamic>.from(insights);

    updatedInsights.remove(goalId);

    insights = updatedInsights;

    if (hasListeners) {
      notifyListeners();
    }
  }

  // ============================================================
  // MARK REFRESH REQUIRED
  // ============================================================

  void markNeedsRefresh() {
    needsRefresh = true;

    if (hasListeners) {
      notifyListeners();
    }
  }

  // ============================================================
  // REMOVE GOAL
  // ============================================================

  void removeGoal(int goalId) {
    final updatedGoals = List<Goal>.from(goals);

    updatedGoals.removeWhere((goal) => goal.id == goalId);

    goals = updatedGoals;

    invalidateGoal(goalId);
  }

  // ============================================================
  // REPLACE GOALS
  // ============================================================

  void replaceGoals(List<Goal> updatedGoals) {
    goals = List<Goal>.from(updatedGoals);

    needsRefresh = false;

    if (hasListeners) {
      notifyListeners();
    }
  }

  // ============================================================
  // ANALYTICS
  // ============================================================

  Future<void> loadAnalytics() async {
    try {
      final data = await goalsService.getCachedAnalytics();

      _goalAnalytics = data;

      if (hasListeners) {
        notifyListeners();
      }
    } on RateLimitException {
      rethrow;
    } catch (e) {
      debugPrint('Goal analytics cache error: $e');
    }
  }

  // ============================================================
  // DEADLINES
  // ============================================================

  Future<void> loadUpcomingDeadlines() async {
    try {
      final data = await goalsService.getCachedUpcomingDeadlines();

      _upcomingDeadlines = List<Map<String, dynamic>>.from(data);

      await _processDeadlineNotifications();

      if (hasListeners) {
        notifyListeners();
      }
    } on RateLimitException {
      rethrow;
    } catch (e) {
      debugPrint('Failed to load cached upcoming deadlines: $e');
    }
  }

  // ============================================================
  // DEADLINE NOTIFICATIONS
  // ============================================================

  Future<void> _processDeadlineNotifications() async {
    for (final goal in _upcomingDeadlines) {
      if (!goalsService.shouldNotifyDeadline(goal)) {
        continue;
      }

      final days = goalsService.getDaysRemaining(goal);

      final goalId = int.tryParse(goal['goal_id']?.toString() ?? '');

      if (goalId == null) {
        continue;
      }

      try {
        final shouldShow =
            await NotificationService.shouldShowGoalDeadlineNotification(
              goalId,
              days,
            );

        if (!shouldShow) {
          continue;
        }

        await NotificationService.showNotification(
          id: NotificationService.goalNotificationId(goalId),
          title: '🎯 Goal Deadline Approaching',
          body: days == 0
              ? '${goal['title']} is due today.'
              : days == 1
              ? '${goal['title']} is due tomorrow.'
              : '${goal['title']} is due in $days days.',
        );

        await NotificationService.markGoalDeadlineNotificationShown(
          goalId,
          days,
        );
      } catch (e) {
        // A notification failure should not prevent goals
        // from being displayed or refreshed.
        debugPrint('Goal deadline notification failed: $e');
      }
    }
  }

  // ============================================================
  // ADD SAVINGS
  // ============================================================

  Future<Map<String, dynamic>> addSavings({
    required int goalId,
    required double amount,
    required bool isOnline,
  }) async {
    final goal = goals.firstWhere((goal) => goal.id == goalId);

    final response = await goalsService.addSavings(
      goal: goal,
      amount: amount,
      isOnline: isOnline,
    );

    // ----------------------------------------------------------
    // Update the goal immediately when the operation is offline.
    // ----------------------------------------------------------

    final isGuest = await SessionService.isGuest();

    if (!isOnline || isGuest) {
      final updatedGoals = List<Goal>.from(goals);

      final index = updatedGoals.indexWhere((item) => item.id == goalId);

      if (index != -1) {
        final current = updatedGoals[index];

        final savedAmount = current.savedAmount + amount;

        final percentage = current.targetAmount <= 0
            ? 0.0
            : ((savedAmount / current.targetAmount) * 100)
                  .clamp(0.0, 100.0)
                  .toDouble();

        updatedGoals[index] = Goal(
          id: current.id,
          serverId: current.serverId,
          isSynced: 0,
          title: current.title,
          targetAmount: current.targetAmount,
          savedAmount: savedAmount,
          targetDate: current.targetDate,
          achievement: current.achievement,
          completedPercentage: percentage,
          createdAt: current.createdAt,
          completedAt: savedAmount >= current.targetAmount
              ? DateTime.now().toIso8601String()
              : current.completedAt,
          updatedAt: DateTime.now().toIso8601String(),
          isArchived: current.isArchived,
          isDeleted: current.isDeleted,
        );

        goals = updatedGoals;
      }

      clearGoalCache(goalId);

      if (hasListeners) {
        notifyListeners();
      }

      return response;
    }

    // ----------------------------------------------------------
    // Online operation
    // ----------------------------------------------------------

    clearGoalCache(goalId);

    await refreshSingleGoal(goalId);

    return response;
  }

  // ============================================================
  // DELETE
  // ============================================================

  Future<void> deleteGoal({required Goal goal, required bool isOnline}) async {
    await goalsService.deleteGoal(goal: goal, isOnline: isOnline);

    removeGoal(goal.id);
  }

  // ============================================================
  // RESTORE
  // ============================================================

  Future<void> restoreGoal({required Goal goal, required bool isOnline}) async {
    await goalsService.restoreGoal(goal: goal, isOnline: isOnline);

    clearGoalCache(goal.id);

    if (!goals.any((item) => item.id == goal.id)) {
      goals.insert(0, goal);
    }

    needsRefresh = true;

    if (hasListeners) {
      notifyListeners();
    }
  }

  // ============================================================
  // ARCHIVE
  // ============================================================

  Future<void> archiveGoal({required Goal goal, required bool isOnline}) async {
    await goalsService.archiveGoal(goal: goal, isOnline: isOnline);

    clearGoalCache(goal.id);

    goals.removeWhere((item) => item.id == goal.id);

    needsRefresh = true;

    if (hasListeners) {
      notifyListeners();
    }
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    goals.clear();
    forecasts.clear();
    insights.clear();
    _goalAnalytics.clear();
    _upcomingDeadlines.clear();

    super.dispose();
  }

  void clearGoalCache(int goalId) {
    goalsService.clearGoalCache(goalId);

    final updatedForecasts = Map<int, dynamic>.from(forecasts);

    updatedForecasts.remove(goalId);

    forecasts = updatedForecasts;

    final updatedInsights = Map<int, dynamic>.from(insights);

    updatedInsights.remove(goalId);

    insights = updatedInsights;

    if (hasListeners) {
      notifyListeners();
    }
  }
}
