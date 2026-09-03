import 'package:flutter/foundation.dart';

import '../exceptions/rate_limit_exception.dart';
import '../models/goal.dart';

import '../services/session_service.dart';

import '../repositories/goals_repository.dart';
import '../repositories/goal_analytics_repository.dart';
import '../repositories/goal_deadline_repository.dart';
import '../repositories/goal_insights_repository.dart';
import '../repositories/goals_forecast_repository.dart';

class GoalsService {
  final GoalsRepository goalsRepository;
  final GoalForecastRepository goalsForecastRepository;
  final GoalInsightsRepository goalInsightsRepository;
  final GoalAnalyticsRepository goalAnalyticsRepository;
  final GoalDeadlineRepository goalDeadlineRepository;

  // In-memory caches.
  //
  // These prevent repeatedly reading the same forecast/insight
  // from SQLite during the current app session.
  final Map<int, dynamic> _forecastCache = {};
  final Map<int, dynamic> _insightCache = {};

  GoalsService({
    GoalsRepository? goalsRepository,
    GoalForecastRepository? goalsForecastRepository,
    GoalInsightsRepository? goalInsightsRepository,
    GoalAnalyticsRepository? goalAnalyticsRepository,
    GoalDeadlineRepository? goalDeadlineRepository,
  }) : goalsRepository = goalsRepository ?? GoalsRepository(),
       goalsForecastRepository =
           goalsForecastRepository ?? GoalForecastRepository(),
       goalInsightsRepository =
           goalInsightsRepository ?? GoalInsightsRepository(),
       goalAnalyticsRepository =
           goalAnalyticsRepository ?? GoalAnalyticsRepository(),
       goalDeadlineRepository =
           goalDeadlineRepository ?? GoalDeadlineRepository();

  // ============================================================
  // GOALS - CACHE
  // ============================================================

  /// Loads active goals from the local SQLite database.
  ///
  /// This method never contacts the API.
  Future<List<Goal>> getCachedGoals() async {
    return await goalsRepository.getCachedGoals();
  }

  /// Loads archived goals from the local SQLite database.
  ///
  /// This method never contacts the API.
  Future<List<Map<String, dynamic>>> getCachedArchivedGoals() async {
    return await goalsRepository.getCachedArchivedGoals();
  }

  // ============================================================
  // GOALS - API REFRESH
  // ============================================================

  /// Fetches active and archived goals from Laravel and updates
  /// the local SQLite database.
  Future<List<Goal>> refreshGoals() async {
    return await goalsRepository.refreshGoals();
  }

  // ============================================================
  // FORECAST - CACHE
  // ============================================================

  /// Loads forecasts from memory/SQLite only.
  ///
  /// No API requests are made here.
  Future<Map<int, dynamic>> loadCachedForecasts(List<Goal> goals) async {
    final map = <int, dynamic>{};

    await Future.wait(
      goals.map((goal) async {
        final localId = goal.id;
        final requestId = goal.requestId;

        // First check the in-memory cache.
        if (_forecastCache.containsKey(localId)) {
          map[localId] = _forecastCache[localId];
          return;
        }

        try {
          final forecast = await goalsForecastRepository.getCachedForecast(
            requestId,
          );

          _forecastCache[localId] = forecast;
          map[localId] = forecast;
        } catch (e) {
          debugPrint('Failed to load cached forecast for goal $localId: $e');

          map[localId] = null;
        }
      }),
    );

    return map;
  }

  // ============================================================
  // FORECAST - API REFRESH
  // ============================================================

  /// Refreshes forecasts from Laravel.
  ///
  /// The refreshed results are stored in SQLite and memory.
  Future<Map<int, dynamic>> refreshForecasts(List<Goal> goals) async {
    final map = <int, dynamic>{};

    await Future.wait(
      goals.map((goal) async {
        final localId = goal.id;
        final requestId = goal.requestId;

        try {
          final forecast = await goalsForecastRepository.refreshForecast(
            requestId,
          );

          _forecastCache[localId] = forecast;
          map[localId] = forecast;
        } on RateLimitException {
          rethrow;
        } catch (e) {
          debugPrint('Failed to refresh forecast for goal $localId: $e');

          map[localId] = null;
        }
      }),
    );

    return map;
  }

  // ============================================================
  // INSIGHTS - CACHE
  // ============================================================

  /// Loads insights from memory/SQLite only.
  ///
  /// No API requests are made here.
  Future<Map<int, dynamic>> loadCachedInsights(List<Goal> goals) async {
    final map = <int, dynamic>{};

    await Future.wait(
      goals.map((goal) async {
        final localId = goal.id;
        final requestId = goal.requestId;

        // First check the in-memory cache.
        if (_insightCache.containsKey(localId)) {
          map[localId] = _insightCache[localId];
          return;
        }

        try {
          final insight = await goalInsightsRepository.getCachedInsights(
            requestId,
          );

          _insightCache[localId] = insight;
          map[localId] = insight;
        } catch (e) {
          debugPrint('Failed to load cached insight for goal $localId: $e');

          map[localId] = null;
        }
      }),
    );

    return map;
  }

  // ============================================================
  // INSIGHTS - API REFRESH
  // ============================================================

  /// Refreshes insights from Laravel.
  ///
  /// The refreshed results are stored in SQLite and memory.
  Future<Map<int, dynamic>> refreshInsights(List<Goal> goals) async {
    final map = <int, dynamic>{};

    await Future.wait(
      goals.map((goal) async {
        final localId = goal.id;
        final requestId = goal.requestId;

        try {
          final insight = await goalInsightsRepository.refreshInsights(
            requestId,
          );

          _insightCache[localId] = insight;
          map[localId] = insight;
        } on RateLimitException {
          rethrow;
        } catch (e) {
          debugPrint('Failed to refresh insight for goal $localId: $e');

          map[localId] = null;
        }
      }),
    );

    return map;
  }

  // ============================================================
  // ANALYTICS - CACHE
  // ============================================================

  /// Loads goal analytics from SQLite/local calculation only.
  Future<Map<String, dynamic>> getCachedAnalytics() async {
    return await goalAnalyticsRepository.getCachedGoalAnalytics();
  }

  // ============================================================
  // ANALYTICS - API REFRESH
  // ============================================================

  /// Refreshes goal analytics from Laravel.
  Future<Map<String, dynamic>> refreshAnalytics() async {
    return await goalAnalyticsRepository.refreshGoalAnalytics();
  }

  // ============================================================
  // DEADLINES - CACHE
  // ============================================================

  /// Loads upcoming deadlines from SQLite/local calculation only.
  Future<List<Map<String, dynamic>>> getCachedUpcomingDeadlines() async {
    final data = await goalDeadlineRepository.getCachedUpcomingDeadlines();

    return data
        .map<Map<String, dynamic>>((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  // ============================================================
  // DEADLINES - API REFRESH
  // ============================================================

  /// Refreshes upcoming deadlines from Laravel.
  Future<List<Map<String, dynamic>>> refreshUpcomingDeadlines() async {
    final data = await goalDeadlineRepository.refreshUpcomingDeadlines();

    return data
        .map<Map<String, dynamic>>((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  // ============================================================
  // DEADLINE HELPERS
  // ============================================================

  int getDaysRemaining(Map<String, dynamic> deadline) {
    return (deadline['days_remaining'] as num?)?.toInt() ??
        int.tryParse(deadline['days_remaining']?.toString() ?? '') ??
        0;
  }

  bool shouldNotifyDeadline(Map<String, dynamic> deadline) {
    final days = getDaysRemaining(deadline);

    return days >= 0 && days <= 3;
  }

  // ============================================================
  // SAVINGS
  // ============================================================

  Future<Map<String, dynamic>> addSavings({
    required Goal goal,
    required double amount,
    required bool isOnline,
  }) async {
    final ownerId = await SessionService.currentOwnerId();

    // ----------------------------------------------------------
    // Guest users ALWAYS save locally.
    // Internet availability must not change this.
    // ----------------------------------------------------------

    if (ownerId == 'guest') {
      final response = await goalsRepository.updateGoalProgressOffline(
        goal.id,
        amount,
      );

      // The local goal has changed, so invalidate derived data.
      clearGoalCache(goal.id);

      return response;
    }

    // ----------------------------------------------------------
    // Authenticated user + Internet
    // ----------------------------------------------------------

    if (isOnline) {
      final response = await goalsRepository.updateGoalProgressOnline(
        goal.id,
        goal.requestId,
        amount,
      );

      // The goal has changed, so its forecast and insight are
      // no longer guaranteed to represent the current state.
      clearGoalCache(goal.id);

      return {...response, "offline": false};
    }

    // ----------------------------------------------------------
    // Authenticated user + Offline
    // ----------------------------------------------------------

    final response = await goalsRepository.updateGoalProgressOffline(
      goal.id,
      amount,
    );

    clearGoalCache(goal.id);

    return response;
  }
  // ============================================================
  // DELETE
  // ============================================================

  Future<void> deleteGoal({required Goal goal, required bool isOnline}) async {
    await goalsRepository.deleteGoal(
      goal.id,
      serverGoalId: goal.serverId,
      isOnline: isOnline,
    );

    clearGoalCache(goal.id);
  }

  // ============================================================
  // ARCHIVE
  // ============================================================

  Future<void> archiveGoal({required Goal goal, required bool isOnline}) async {
    await goalsRepository.archiveGoal(
      goal.id,
      serverGoalId: goal.serverId,
      isOnline: isOnline,
    );

    clearGoalCache(goal.id);
  }

  // ============================================================
  // RESTORE
  // ============================================================

  Future<void> restoreGoal({required Goal goal, required bool isOnline}) async {
    if (!isOnline) {
      await goalsRepository.restoreGoalOffline(goal.id);
    } else if (goal.serverId != null) {
      await goalsRepository.restoreGoalOnline(goal.id, goal.serverId!);
    } else {
      throw Exception('Cannot restore goal: server ID is missing.');
    }

    clearGoalCache(goal.id);
  }

  // ============================================================
  // SINGLE GOAL REFRESH
  // ============================================================

  /// Refreshes one goal and its derived data.
  ///
  /// This is primarily useful after operations such as adding
  /// savings to a goal.
  Future<GoalRefreshResult> refreshSingleGoal(int goalId) async {
    final latestGoals = await goalsRepository.getCachedGoals();

    final goalIndex = latestGoals.indexWhere((goal) => goal.id == goalId);

    if (goalIndex == -1) {
      throw Exception('Goal not found');
    }

    final goal = latestGoals[goalIndex];

    // Invalidate the old derived data first.
    clearGoalCache(goalId);

    final results = await Future.wait([
      goalsForecastRepository.refreshForecast(goal.requestId),
      goalInsightsRepository.refreshInsights(goal.requestId),
    ]);

    final forecast = results[0];
    final insight = results[1];

    _forecastCache[goalId] = forecast;
    _insightCache[goalId] = insight;

    return GoalRefreshResult(goal: goal, forecast: forecast, insight: insight);
  }

  // ============================================================
  // CACHE INVALIDATION
  // ============================================================

  void clearGoalCache(int goalId) {
    _forecastCache.remove(goalId);
    _insightCache.remove(goalId);
  }

  void clearCaches() {
    _forecastCache.clear();
    _insightCache.clear();
  }
}

class GoalRefreshResult {
  final Goal goal;
  final dynamic forecast;
  final dynamic insight;

  const GoalRefreshResult({
    required this.goal,
    required this.forecast,
    required this.insight,
  });
}
