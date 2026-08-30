import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../models/goal.dart';
import '../services/goals_service.dart';
import '../services/notification_service.dart';

import '../../exceptions/rate_limit_exception.dart';

class GoalsController extends ChangeNotifier {
  final GoalsService goalsService;

  GoalsController({required this.goalsService});

  bool isLoading = true;

  bool needsRefresh = true;

  List<Goal> goals = [];

  Map<int, dynamic> forecasts = {};

  Map<int, dynamic> insights = {};

  Map<String, dynamic> _goalAnalytics = {};
  List<Map<String, dynamic>> _upcomingDeadlines = [];

  Map<String, dynamic> get goalAnalytics => _goalAnalytics;

  List<Map<String, dynamic>> get upcomingDeadlines =>
      List.unmodifiable(_upcomingDeadlines);

  Future<void> initialize({bool forceRefresh = false}) async {
    await loadGoals(forceRefresh: forceRefresh);

    await Future.wait([loadAnalytics(), loadUpcomingDeadlines()]);
  }

  Future<void> loadGoals({bool forceRefresh = false}) async {
    if (!forceRefresh && !needsRefresh && goals.isNotEmpty) {
      return;
    }

    needsRefresh = false;

    if (forceRefresh) {
      goalsService.clearCaches();
    }

    isLoading = true;
    notifyListeners();

    try {
      final data = await goalsService.getGoals();

      final results = await Future.wait([
        goalsService.loadForecasts(data, forceRefresh: forceRefresh),
        goalsService.loadInsights(data, forceRefresh: forceRefresh),
      ]);

      goals = data;
      forecasts = Map<int, dynamic>.from(results[0]);
      insights = Map<int, dynamic>.from(results[1]);
    } catch (e) {
      debugPrint('GoalsController load error: $e');
      rethrow;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refreshSingleGoal(int goalId) async {
    try {
      final result = await goalsService.refreshSingleGoal(goalId);

      final index = goals.indexWhere((goal) => goal.id == goalId);

      if (index != -1) {
        goals[index] = result.goal;
      }

      final updatedForecasts = Map<int, dynamic>.from(forecasts);

      updatedForecasts[goalId] = result.forecast;
      forecasts = updatedForecasts;

      final updatedInsights = Map<int, dynamic>.from(insights);

      updatedInsights[goalId] = result.insight;
      insights = updatedInsights;

      notifyListeners();
    } catch (e) {
      debugPrint('Failed to refresh goal $goalId: $e');
    }
  }

  void invalidateGoal(int goalId) {
    goalsService.clearGoalCache(goalId);

    final updatedForecasts = Map<int, dynamic>.from(forecasts);

    updatedForecasts.remove(goalId);
    forecasts = updatedForecasts;

    final updatedInsights = Map<int, dynamic>.from(insights);

    updatedInsights.remove(goalId);
    insights = updatedInsights;

    notifyListeners();
  }

  void markNeedsRefresh() {
    needsRefresh = true;
    notifyListeners();
  }

  void removeGoal(int goalId) {
    goals.removeWhere((goal) => goal.id == goalId);

    invalidateGoal(goalId);
  }

  void replaceGoals(List<Goal> updatedGoals) {
    goals = updatedGoals;
    notifyListeners();
  }

  Future<void> loadAnalytics() async {
    try {
      final data = await goalsService.loadAnalytics();

      _goalAnalytics = data ?? {};

      notifyListeners();
    } catch (e) {
      debugPrint('Goal analytics error: $e');
    }
  }

  Future<void> loadUpcomingDeadlines() async {
    try {
      final data = await goalsService.loadUpcomingDeadlines();

      for (final goal in data) {
        if (!goalsService.shouldNotifyDeadline(goal)) {
          continue;
        }

        final days = goalsService.getDaysRemaining(goal);

        final goalId = int.tryParse(goal['goal_id']?.toString() ?? '');

        if (goalId == null) {
          continue;
        }

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
      }

      _upcomingDeadlines = List<Map<String, dynamic>>.from(data);

      notifyListeners();
    } on RateLimitException {
      rethrow;
    } catch (e) {
      debugPrint('Failed to load upcoming deadlines: $e');
      rethrow;
    }
  }

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

    invalidateGoal(goalId);

    await refreshSingleGoal(goalId);

    return response;
  }

  Future<void> deleteGoal({required Goal goal, required bool isOnline}) async {
    await goalsService.deleteGoal(goal: goal, isOnline: isOnline);

    invalidateGoal(goal.id);

    goals.removeWhere((g) => g.id == goal.id);

    notifyListeners();
  }

  Future<void> restoreGoal({required Goal goal, required bool isOnline}) async {
    await goalsService.restoreGoal(goal: goal, isOnline: isOnline);

    invalidateGoal(goal.id);

    if (!goals.any((g) => g.id == goal.id)) {
      goals.insert(0, goal);
    }

    notifyListeners();
  }

  Future<void> archiveGoal({required Goal goal, required bool isOnline}) async {
    await goalsService.archiveGoal(goal: goal, isOnline: isOnline);

    invalidateGoal(goal.id);

    await loadGoals(forceRefresh: true);
  }
}
