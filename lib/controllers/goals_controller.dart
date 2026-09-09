import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../models/goal.dart';
import '../services/goals_service.dart';
import '../services/notification_service.dart';
import '../services/session_service.dart';
import '../services/startup_refresh_coordinator.dart';

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

  bool _mutationInProgress = false;

  bool get mutationInProgress => _mutationInProgress;

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
  Future<void> reloadFromCache() async {
    try {
      debugPrint('GoalsController: reloading goals from local cache.');

      await _loadCachedData();

      debugPrint(
        'GoalsController: local cache reload completed. '
        'goals=${goals.length}, '
        'ids=${goals.map((g) => g.id).toList()}',
      );

      notifyListeners();
    } catch (e, stackTrace) {
      debugPrint('GoalsController: failed to reload local cache: $e');
      debugPrint('$stackTrace');

      rethrow;
    }
  }

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

      // ----------------------------------------------------------
      // Goals are the source of truth for the current goal counts.
      // ----------------------------------------------------------

      goals = cachedGoals;

      final totalGoals = cachedGoals.length;

      final completedGoals = cachedGoals
          .where((goal) => goal.percentage >= 100)
          .length;

      final activeGoals = totalGoals - completedGoals;

      final completionRate = totalGoals == 0
          ? 0.0
          : (completedGoals / totalGoals) * 100.0;

      // Preserve other cached analytics fields, but always
      // overwrite the goal statistics with the current SQLite state.
      _goalAnalytics = {
        ...cachedAnalytics,
        'total_goals': totalGoals,
        'completed_goals': completedGoals,
        'active_goals': activeGoals,
        'completion_rate': completionRate,
      };

      _upcomingDeadlines = cachedDeadlines;

      // ----------------------------------------------------------
      // Forecasts and insights remain derived/cache data.
      // ----------------------------------------------------------

      final derivedResults = await Future.wait([
        goalsService.loadCachedForecasts(goals),
        goalsService.loadCachedInsights(goals),
      ]);

      forecasts = Map<int, dynamic>.from(derivedResults[0] as Map);

      insights = Map<int, dynamic>.from(derivedResults[1] as Map);

      _cacheLoaded = true;
      needsRefresh = false;

      debugPrint(
        'Loaded cached goals data. '
        'total=$totalGoals, '
        'completed=$completedGoals, '
        'active=$activeGoals, '
        'completionRate=$completionRate',
      );
    } catch (e) {
      debugPrint('Failed to load cached goals data: $e');

      // Cache-first loading should degrade gracefully.
    }
  }
  // ============================================================
  // BACKGROUND REFRESH
  // ============================================================

  Future<void> _refreshInBackground({bool forceRefresh = false}) async {
    if (_refreshInProgress) {
      debugPrint('Goals background refresh skipped: already in progress.');
      return;
    }

    if (isGuest) {
      debugPrint('Goals background refresh skipped: guest user.');
      return;
    }

    _refreshInProgress = true;

    try {
      // --------------------------------------------------------
      // CLEAR CACHES FOR FORCED REFRESH
      // --------------------------------------------------------

      if (forceRefresh) {
        debugPrint('Goals forced refresh: clearing caches.');
        goalsService.clearCaches();
      }

      // --------------------------------------------------------
      // REFRESH GOALS
      // --------------------------------------------------------

      debugPrint('Goals refresh: requesting goals...');

      final refreshedGoals = await StartupRefreshCoordinator.instance.run(
        'goals',
        () async {
          return await goalsService.refreshGoals();
        },
      );
      if (!hasListeners) {
        return;
      }

      goals = refreshedGoals;

      needsRefresh = false;

      notifyListeners();

      debugPrint('Goals refresh: goals completed (${goals.length} goals).');

      // --------------------------------------------------------
      // REFRESH ALL DERIVED DATA WITH ONE API REQUEST
      // --------------------------------------------------------
      //
      // This replaces:
      //
      // /goals/{id}/forecast
      // /goals/{id}/insights
      // /goals/analytics
      // /goals/upcoming-deadlines
      //
      // with:
      //
      // /goals/derived-data
      //
      // --------------------------------------------------------

      debugPrint('Goals refresh: requesting derived data...');

      final derivedData = await StartupRefreshCoordinator.instance.run(
        'goals-derived-data',
        () async {
          return await goalsService.refreshDerivedData();
        },
      );

      if (!hasListeners) {
        return;
      }

      // --------------------------------------------------------
      // FORECASTS
      // --------------------------------------------------------

      final rawForecasts = derivedData['forecasts'];

      if (rawForecasts is Map) {
        final parsedForecasts = <int, dynamic>{};

        for (final entry in rawForecasts.entries) {
          final goalId = int.tryParse(entry.key.toString());

          if (goalId == null) {
            debugPrint(
              'Goals refresh: ignoring invalid forecast goal ID '
              '${entry.key}.',
            );

            continue;
          }

          parsedForecasts[goalId] = entry.value;
        }

        forecasts = parsedForecasts;
      } else {
        forecasts = {};
      }

      // --------------------------------------------------------
      // INSIGHTS
      // --------------------------------------------------------

      final rawInsights = derivedData['insights'];

      if (rawInsights is Map) {
        final parsedInsights = <int, dynamic>{};

        for (final entry in rawInsights.entries) {
          final goalId = int.tryParse(entry.key.toString());

          if (goalId == null) {
            debugPrint(
              'Goals refresh: ignoring invalid insight goal ID '
              '${entry.key}.',
            );

            continue;
          }

          parsedInsights[goalId] = entry.value;
        }

        insights = parsedInsights;
      } else {
        insights = {};
      }

      // --------------------------------------------------------
      // GOAL ANALYTICS
      // --------------------------------------------------------

      final rawAnalytics = derivedData['analytics'];

      if (rawAnalytics is Map) {
        _goalAnalytics = Map<String, dynamic>.from(rawAnalytics);
      } else {
        _goalAnalytics = {};
      }

      // --------------------------------------------------------
      // UPCOMING DEADLINES
      // --------------------------------------------------------

      final rawDeadlines = derivedData['upcoming_deadlines'];

      if (rawDeadlines is List) {
        _upcomingDeadlines = rawDeadlines
            .whereType<Map>()
            .map<Map<String, dynamic>>(
              (item) => Map<String, dynamic>.from(item),
            )
            .toList();
      } else {
        _upcomingDeadlines = [];
      }

      // --------------------------------------------------------
      // PROCESS DEADLINE NOTIFICATIONS
      // --------------------------------------------------------

      await _processDeadlineNotifications();

      if (!hasListeners) {
        return;
      }

      // --------------------------------------------------------
      // COMPLETE
      // --------------------------------------------------------

      isLoading = false;

      notifyListeners();

      debugPrint('Goals background refresh completed successfully.');
    } on RateLimitException catch (e) {
      debugPrint('Goals background refresh rate limited: ${e.message}');

      // Keep cached data visible.
    } catch (e, stackTrace) {
      debugPrint('Goals background refresh failed: $e');

      debugPrint('Goals background refresh stack trace: $stackTrace');

      // Keep cached data visible.
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
    try {
      debugPrint(
        'GoalsController: adding savings '
        'goal=$goalId, amount=$amount, online=$isOnline',
      );

      // Find the current goal from the controller's cached list.
      final index = goals.indexWhere((goal) => goal.id == goalId);

      if (index == -1) {
        throw Exception('Goal not found.');
      }

      final goal = goals[index];

      // The service/repository is responsible for all savings business logic:
      // - calculating the new saved amount
      // - calculating percentage
      // - determining completion
      // - setting completed_at
      // - persisting the change locally
      // - marking offline changes as unsynced
      // - queuing offline synchronization
      final response = await goalsService.addSavings(
        goal: goal,
        amount: amount,
        isOnline: isOnline,
      );

      await reloadFromCache();
      // Savings can make this goal's forecast/insight cache stale.
      clearGoalCache(goalId);

      notifyListeners();

      debugPrint(
        'GoalsController: savings added successfully '
        'goal=$goalId',
      );

      return response;
    } catch (e) {
      debugPrint(
        'GoalsController: failed to add savings '
        'goal=$goalId: $e',
      );

      rethrow;
    }
  }
  // ============================================================
  // DELETE
  // ============================================================

  Future<void> deleteGoal({required Goal goal, required bool isOnline}) async {
    _mutationInProgress = true;

    try {
      await goalsService.deleteGoal(goal: goal, isOnline: isOnline);

      await reloadFromCache();

      needsRefresh = false;
    } finally {
      _mutationInProgress = false;
    }
  }
  // ============================================================
  // RESTORE
  // ============================================================

  Future<void> restoreGoal({required Goal goal, required bool isOnline}) async {
    _mutationInProgress = true;

    try {
      await goalsService.restoreGoal(goal: goal, isOnline: isOnline);

      await reloadFromCache();

      needsRefresh = false;
    } finally {
      _mutationInProgress = false;
    }
  }
  // ============================================================
  // ARCHIVE
  // ============================================================

  Future<void> archiveGoal({required Goal goal, required bool isOnline}) async {
    _mutationInProgress = true;

    try {
      await goalsService.archiveGoal(goal: goal, isOnline: isOnline);

      await reloadFromCache();

      needsRefresh = false;
    } finally {
      _mutationInProgress = false;
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
