import '../models/goal.dart';
import '../repositories/goal_analytics_repository.dart';
import '../repositories/goal_deadline_repository.dart';
import '../repositories/goal_insights_repository.dart';
import '../repositories/goals_forecast_repository.dart';
import '../repositories/goals_repository.dart';

class GoalsService {
  final GoalsRepository goalsRepository;
  final GoalForecastRepository goalsForecastRepository;
  final GoalInsightsRepository goalInsightsRepository;
  final GoalAnalyticsRepository goalAnalyticsRepository;
  final GoalDeadlineRepository goalDeadlineRepository;

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

  int getDaysRemaining(Map<String, dynamic> deadline) {
    return (deadline['days_remaining'] as num?)?.toInt() ??
        int.tryParse(deadline['days_remaining']?.toString() ?? '') ??
        0;
  }

  bool shouldNotifyDeadline(Map<String, dynamic> deadline) {
    final days = getDaysRemaining(deadline);
    return days >= 0 && days <= 3;
  }

  Future<List<Goal>> getGoals() async {
    return await goalsRepository.getGoals();
  }

  Future<Map<int, dynamic>> loadForecasts(
    List<Goal> goals, {
    bool forceRefresh = false,
  }) async {
    if (forceRefresh) {
      _forecastCache.clear();
    }

    final map = <int, dynamic>{};

    await Future.wait(
      goals.map((goal) async {
        final localId = goal.id;

        if (_forecastCache.containsKey(localId)) {
          map[localId] = _forecastCache[localId];
          return;
        }

        try {
          final forecast = await goalsForecastRepository.getForecast(
            goal.requestId,
          );

          _forecastCache[localId] = forecast;
          map[localId] = forecast;
        } catch (_) {
          map[localId] = null;
        }
      }),
    );

    return map;
  }

  Future<Map<int, dynamic>> loadInsights(
    List<Goal> goals, {
    bool forceRefresh = false,
  }) async {
    if (forceRefresh) {
      _insightCache.clear();
    }

    final map = <int, dynamic>{};

    await Future.wait(
      goals.map((goal) async {
        final localId = goal.id;

        if (_insightCache.containsKey(localId)) {
          map[localId] = _insightCache[localId];
          return;
        }

        try {
          final insight = await goalInsightsRepository.getInsights(
            goal.requestId,
          );

          _insightCache[localId] = insight;
          map[localId] = insight;
        } catch (_) {
          map[localId] = null;
        }
      }),
    );

    return map;
  }

  Future<Map<String, dynamic>?> loadAnalytics() async {
    return await goalAnalyticsRepository.getGoalAnalytics();
  }

  Future<List<Map<String, dynamic>>> loadUpcomingDeadlines() async {
    final data = await goalDeadlineRepository.getUpcomingDeadlines();

    return data
        .map<Map<String, dynamic>>((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  Future<Map<String, dynamic>?> refreshGoalForecast(int goalId) async {
    try {
      final forecast = await goalsForecastRepository.getForecast(goalId);

      _forecastCache[goalId] = forecast;

      return forecast;
    } catch (_) {
      return null;
    }
  }

  Future<Map<String, dynamic>?> refreshGoalInsight(int goalId) async {
    try {
      final insight = await goalInsightsRepository.getInsights(goalId);

      _insightCache[goalId] = insight;

      return insight;
    } catch (_) {
      return null;
    }
  }

  void clearGoalCache(int goalId) {
    _forecastCache.remove(goalId);
    _insightCache.remove(goalId);
  }

  void clearCaches() {
    _forecastCache.clear();
    _insightCache.clear();
  }

  Future<Map<String, dynamic>?> addSavings({
    required Goal goal,
    required double amount,
    required bool isOnline,
  }) async {
    if (isOnline) {
      return await goalsRepository.updateGoalProgressOnline(
        goal.id,
        goal.requestId,
        amount,
      );
    }

    await goalsRepository.updateGoalProgressOffline(goal.id, amount);

    return null;
  }

  Future<void> deleteGoal({required Goal goal, required bool isOnline}) async {
    await goalsRepository.deleteGoal(
      goal.id,
      serverGoalId: goal.serverId,
      isOnline: isOnline,
    );
  }

  Future<void> archiveGoal({required Goal goal, required bool isOnline}) async {
    await goalsRepository.archiveGoal(
      goal.id,
      serverGoalId: goal.serverId,
      isOnline: isOnline,
    );
  }

  Future<void> restoreGoal({required Goal goal, required bool isOnline}) async {
    if (isOnline && goal.serverId != null) {
      await goalsRepository.restoreGoalOnline(goal.serverId!);
    } else {
      await goalsRepository.restoreGoalOffline(goal.id);
    }
  }

  Future<GoalRefreshResult> refreshSingleGoal(int goalId) async {
    final latestGoals = await goalsRepository.getGoals();

    final goalIndex = latestGoals.indexWhere((goal) => goal.id == goalId);

    if (goalIndex == -1) {
      throw Exception('Goal not found');
    }

    final goal = latestGoals[goalIndex];

    final results = await Future.wait([
      _refreshForecastForGoal(goal),
      _refreshInsightForGoal(goal),
    ]);

    return GoalRefreshResult(
      goal: goal,
      forecast: results[0],
      insight: results[1],
    );
  }

  Future<Map<String, dynamic>?> _refreshForecastForGoal(Goal goal) async {
    try {
      final forecast = await goalsForecastRepository.getForecast(
        goal.requestId,
      );

      _forecastCache[goal.id] = forecast;

      return forecast;
    } catch (_) {
      _forecastCache[goal.id] = null;
      return null;
    }
  }

  Future<Map<String, dynamic>?> _refreshInsightForGoal(Goal goal) async {
    try {
      final insight = await goalInsightsRepository.getInsights(goal.requestId);

      _insightCache[goal.id] = insight;

      return insight;
    } catch (_) {
      _insightCache[goal.id] = null;
      return null;
    }
  }
}

class GoalRefreshResult {
  final Goal goal;
  final Map<String, dynamic>? forecast;
  final Map<String, dynamic>? insight;

  const GoalRefreshResult({
    required this.goal,
    required this.forecast,
    required this.insight,
  });
}
