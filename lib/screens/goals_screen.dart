import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../services/sync_events.dart';
import '../services/goals_service.dart';

import '../widgets/goal_loading_skeleton.dart';
import '../widgets/empty_state_helper.dart';
import '../widgets/app/adaptive_app_bar.dart';
import '../widgets/app/app_scaffold.dart';
import '../widgets/goals/goals_overview_card.dart';
import '../widgets/goals/goals_stats_grid.dart';
import '../widgets/goals/upcoming_deadlines_card.dart';
import '../widgets/goals/goal_list_item.dart';

import 'add_goals_screen.dart';
import 'archived_goals_screen.dart';

import '../controllers/goals_controller.dart';

class GoalsScreen extends StatefulWidget {
  const GoalsScreen({super.key});

  @override
  State<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends State<GoalsScreen>
    with AutomaticKeepAliveClientMixin {
  bool isGuest = false;

  final GoalsService goalsService = GoalsService();

  late final GoalsController goalsController;

  late VoidCallback _goalRefreshListener;

  final currency = NumberFormat.currency(
    locale: 'en_KE',
    symbol: 'KES ',
    decimalDigits: 0,
  );

  @override
  void initState() {
    super.initState();

    goalsController = GoalsController(goalsService: goalsService);

    goalsController.addListener(_onGoalsControllerChanged);

    _initializeGoalsScreen();

    _goalRefreshListener = () async {
      if (!mounted) return;

      await _initializeGoalsScreen(forceRefresh: true);
    };

    SyncEvents.instance.goalsRefresh.addListener(_goalRefreshListener);
  }

  void _onGoalsControllerChanged() {
    if (!mounted) return;

    setState(() {});
  }

  @override
  void dispose() {
    SyncEvents.instance.goalsRefresh.removeListener(_goalRefreshListener);

    goalsController.removeListener(_onGoalsControllerChanged);

    goalsController.dispose();

    super.dispose();
  }

  Future<void> _initializeGoalsScreen({bool forceRefresh = false}) async {
    try {
      await goalsController.initialize(forceRefresh: forceRefresh);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final goals = goalsController.goals;

    final screenSize = MediaQuery.of(context).size;

    final screenHeight = screenSize.height;

    final sectionSpacing = screenHeight * .035;

    if (goalsController.isLoading) {
      return const GoalLoadingSkeleton();
    }
    return AppScaffold(
      appBar: const AdaptiveAppBar(title: null),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: "goalFab",
        elevation: 4,
        icon: const Icon(Icons.flag_outlined),
        label: const Text(
          "New Goal",
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddGoalScreen()),
          );

          if (result == true) {
            goalsController.markNeedsRefresh();

            await _initializeGoalsScreen(forceRefresh: true);
          }
        },
      ),

      body: RefreshIndicator(
        onRefresh: () => _initializeGoalsScreen(forceRefresh: true),
        child: goals.isEmpty
            ? ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  const SizedBox(height: 120),
                  buildEmptyState(
                    context,
                    EmptyStateType.goals,
                    isGuest: isGuest, // optional, if you want guest awareness
                  ),
                ],
              )
            : ListView(
                key: const PageStorageKey("goals"),
                padding: const EdgeInsets.all(16),
                children: [
                  GoalsOverviewCard(
                    totalGoals:
                        goalsController.goalAnalytics['total_goals'] ?? 0,
                    onArchivedGoals: () async {
                      final changed = await Navigator.push<bool>(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ArchivedGoalsScreen(),
                        ),
                      );

                      if (changed == true) {
                        goalsController.markNeedsRefresh();

                        await _initializeGoalsScreen(forceRefresh: true);
                      }
                    },
                  ),

                  SizedBox(height: sectionSpacing),

                  GoalsStatsGrid(
                    totalGoals:
                        goalsController.goalAnalytics['total_goals'] ?? 0,
                    completedGoals:
                        goalsController.goalAnalytics['completed_goals'] ?? 0,
                    activeGoals:
                        goalsController.goalAnalytics['active_goals'] ?? 0,
                    completionRate:
                        (goalsController.goalAnalytics['completion_rate'] ?? 0)
                            .toDouble(),
                  ),

                  SizedBox(height: sectionSpacing),
                  UpcomingDeadlinesCard(
                    upcomingDeadlines: goalsController.upcomingDeadlines,
                  ),

                  ...goals.map<Widget>(
                    (goal) => GoalListItem(
                      goal: goal,
                      goalsController: goalsController,
                      currency: currency,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
