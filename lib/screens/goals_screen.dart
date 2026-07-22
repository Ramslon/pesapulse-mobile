import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pesapulse_mobile/widgets/sync_status_icon.dart';
import '../services/api_services.dart';
import '../services/notification_service.dart';
import '../services/sync_events.dart';

import '../widgets/goal_loading_skeleton.dart';
import '../widgets/goal_stat_card.dart';
import '../widgets/goal_empty_state.dart';
import '../widgets/fade_slide_animation.dart';

import 'add_goals_screen.dart';
import 'archived_goals_screen.dart';

import '../repositories/goals_repository.dart';
import '../repositories/goals_forecast_repository.dart';
import '../repositories/goal_insights_repository.dart';
import '../repositories/goal_analytics_repository.dart';
import '../repositories/goal_deadline_repository.dart';

import 'package:provider/provider.dart';
import '../providers/connectivity_provider.dart';

class GoalsScreen extends StatefulWidget {
  const GoalsScreen({super.key});

  @override
  State<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends State<GoalsScreen>
    with AutomaticKeepAliveClientMixin {
  bool isLoading = true;

  List goals = [];

  List upcomingDeadlines = [];

  Map<int, dynamic> goalInsights = {};

  Map<String, dynamic>? goalAnalytics = {};

  Map<int, dynamic> forecasts = {};

  final currency = NumberFormat.currency(
    locale: 'en_KE',
    symbol: 'KES ',
    decimalDigits: 0,
  );

  final GoalsRepository goalsRepository = GoalsRepository();

  final GoalForecastRepository goalsForecastRepository =
      GoalForecastRepository();

  final GoalInsightsRepository goalInsightsRepository =
      GoalInsightsRepository();

  final GoalAnalyticsRepository goalAnalyticsRepository =
      GoalAnalyticsRepository();

  final GoalDeadlineRepository goalDeadlineRepository =
      GoalDeadlineRepository();

  late VoidCallback _goalRefreshListener;
  @override
  void initState() {
    super.initState();

    loadGoals();
    loadUpcomingDeadlines();
    loadGoalsAnalytics();

    _goalRefreshListener = () async {
      if (!mounted || isLoading) return;

      await loadGoals();
      await loadGoalsAnalytics();
      await loadUpcomingDeadlines();
    };

    SyncEvents.instance.goalsRefresh.addListener(_goalRefreshListener);
  }

  @override
  void dispose() {
    SyncEvents.instance.goalsRefresh.removeListener(_goalRefreshListener);
    super.dispose();
  }

  Future<void> loadGoals() async {
    setState(() {
      isLoading = true;
    });

    try {
      final data = await goalsRepository.getGoals();

      final Map<int, dynamic> loadedForecasts = {};

      for (final goal in data) {
        // Use server_id for synced goals, local id for offline goals
        final forecastId = goal["is_synced"] == 1 && goal["server_id"] != null
            ? goal["server_id"]
            : goal["id"];

        try {
          loadedForecasts[goal["id"]] = await goalsForecastRepository
              .getForecast(forecastId);
        } catch (e) {
          debugPrint("Forecast failed for goal ${goal['id']}: $e");

          loadedForecasts[goal["id"]] = null;
        }
      }

      if (!mounted) return;

      setState(() {
        goals = data;
        forecasts = loadedForecasts;
        isLoading = false;
      });

      await loadGoalInsights();
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Future<void> loadGoalsAnalytics() async {
    try {
      final data = await goalAnalyticsRepository.getGoalAnalytics();

      if (!mounted) return;

      setState(() {
        goalAnalytics = data;
      });
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  Future<void> loadGoalInsights() async {
    try {
      final Map<int, dynamic> insightsMap = {};

      for (final goal in goals) {
        final insightId = goal["is_synced"] == 1 && goal["server_id"] != null
            ? goal["server_id"]
            : goal["id"];

        try {
          insightsMap[goal["id"]] = await goalInsightsRepository.getInsights(
            insightId,
          );
        } catch (e) {
          debugPrint("Insights failed for goal ${goal['id']}: $e");

          insightsMap[goal["id"]] = null;
        }
      }

      if (!mounted) return;

      setState(() {
        goalInsights = insightsMap;
      });
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  Future<void> loadUpcomingDeadlines() async {
    try {
      final data = await goalDeadlineRepository.getUpcomingDeadlines();

      for (final goal in data) {
        final days =
            (goal["days_remaining"] as num?)?.toInt() ??
            int.tryParse(goal["days_remaining"].toString()) ??
            0;

        // Notify only for goals due today or within the next 3 days
        if (days >= 0 && days <= 3) {
          await NotificationService.showNotification(
            title: "🎯 Goal Deadline Approaching",
            body: "${goal['title']} is due in $days day(s)",
          );
        }
      }

      if (!mounted) return;

      setState(() {
        upcomingDeadlines = data;
      });
    } catch (e) {
      debugPrint("Upcoming deadlines error: $e");
    }
  }

  Future<void> showAddSavingsDialog(int goalId) async {
    final controller = TextEditingController();

    showDialog(
      context: context,

      builder: (context) {
        return AlertDialog(
          title: const Text('Add Savings'),

          content: TextField(
            controller: controller,

            keyboardType: TextInputType.number,

            decoration: const InputDecoration(labelText: 'Amount'),
          ),

          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },

              child: const Text('Cancel'),
            ),

            ElevatedButton(
              onPressed: () async {
                final amount = double.tryParse(controller.text) ?? 0;

                final connectivity = context.read<ConnectivityProvider>();

                Map<String, dynamic>? response;

                if (connectivity.isOnline) {
                  response = await ApiService.updateGoalProgress(
                    goalId,
                    amount,
                  );
                } else {
                  await goalsRepository.updateGoalProgressOffline(
                    goalId,
                    amount,
                  );
                }

                final milestone = response?['milestone'];

                if (!mounted) return;

                Navigator.pop(context);

                if (!connectivity.isOnline) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        "Savings added offline. Changes will sync automatically.",
                      ),
                    ),
                  );
                }

                if (milestone != null) {
                  await NotificationService.showNotification(
                    title: milestone['percentage'] == 100
                        ? '🏆 Goal Completed'
                        : '🎯 Goal Milestone',
                    body: milestone['message'],
                  );

                  if (!mounted) return;

                  showDialog(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: Text(
                        milestone['percentage'] == 100
                            ? '🏆 Goal Completed'
                            : '🎉 Milestone Reached',
                      ),
                      content: Text(milestone['message']),
                      actions: [
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          child: const Text('Awesome'),
                        ),
                      ],
                    ),
                  );
                }

                await loadGoals();
              },

              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  Widget buildMilestoneBadge({
    required String title,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(.12),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withOpacity(.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: color.withOpacity(.18),
            child: Icon(icon, color: color, size: 18),
          ),

          const SizedBox(width: 10),

          Text(
            title,
            style: TextStyle(color: color, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget buildInsightMetric({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(.08),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: color.withOpacity(.15),
            child: Icon(icon, color: color, size: 18),
          ),

          const SizedBox(height: 10),

          Text(
            value,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 4),

          Text(
            title,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget buildForecastMetric({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(.08),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: color.withOpacity(.15),
            child: Icon(icon, color: color, size: 18),
          ),

          const SizedBox(height: 10),

          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),

          const SizedBox(height: 4),

          Text(
            title,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
          ),
        ],
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final theme = Theme.of(context);

    final screenSize = MediaQuery.of(context).size;

    final screenHeight = screenSize.height;

    final sectionSpacing = screenHeight * .035;

    if (isLoading) {
      return const GoalLoadingSkeleton();
    }

    return Scaffold(
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
            loadGoals();
          }
        },
      ),

      body: RefreshIndicator(
        onRefresh: loadGoals,
        child: goals.isEmpty
            ? ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  SizedBox(height: 120),

                  GoalEmptyState(
                    icon: Icons.flag_outlined,
                    title: "No Financial Goals",
                    message:
                        "Create savings goals to track your progress and achieve your financial milestones.",
                  ),
                ],
              )
            : ListView(
                key: const PageStorageKey("goals"),
                padding: const EdgeInsets.all(16),
                children: [
                  FadeSlideAnimation(
                    child: Card(
                      elevation: 4,
                      shadowColor: Colors.black12,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(22),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "Financial Goals",
                                        style: theme.textTheme.titleLarge
                                            ?.copyWith(
                                              fontWeight: FontWeight.bold,
                                            ),
                                      ),

                                      const SyncStatusIcon(),

                                      const SizedBox(height: 6),

                                      Text(
                                        "Track your savings goals and progress",
                                        style: TextStyle(
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                IconButton(
                                  tooltip: "Archived Goals",
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            const ArchivedGoalsScreen(),
                                      ),
                                    ).then((_) {
                                      loadGoals();
                                    });
                                  },
                                  icon: const Icon(Icons.archive),
                                ),
                              ],
                            ),

                            const SizedBox(height: 22),

                            Text(
                              "${goalAnalytics?['total_goals'] ?? 0}",
                              style: const TextStyle(
                                fontSize: 34,
                                fontWeight: FontWeight.bold,
                              ),
                            ),

                            const SizedBox(height: 6),

                            Text(
                              "Total Goals",
                              style: TextStyle(color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  SizedBox(height: sectionSpacing),

                  Row(
                    children: [
                      Expanded(
                        child: GoalStatCard(
                          title: "Goals",
                          value: "${goalAnalytics?['total_goals'] ?? 0}",
                          icon: Icons.flag,
                          color: Colors.blue,
                        ),
                      ),

                      const SizedBox(width: 14),

                      Expanded(
                        child: GoalStatCard(
                          title: "Completed",
                          value: "${goalAnalytics?['completed_goals'] ?? 0}",
                          icon: Icons.emoji_events,
                          color: Colors.amber,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  Row(
                    children: [
                      Expanded(
                        child: GoalStatCard(
                          title: "Active",
                          value: "${goalAnalytics?['active_goals'] ?? 0}",
                          icon: Icons.track_changes,
                          color: Colors.orange,
                        ),
                      ),

                      const SizedBox(width: 14),

                      Expanded(
                        child: GoalStatCard(
                          title: "Success Rate",
                          value: "${goalAnalytics?['completion_rate'] ?? 0}%",
                          icon: Icons.trending_up,
                          color: Colors.purple,
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: sectionSpacing),
                  if (upcomingDeadlines.isNotEmpty)
                    Card(
                      elevation: 4,
                      shadowColor: Colors.black12,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(22),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(22),
                          gradient: LinearGradient(
                            colors: [
                              Colors.orange.shade500,
                              Colors.deepOrange.shade400,
                            ],
                          ),
                        ),

                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,

                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 24,
                                  backgroundColor: Colors.white24,
                                  child: const Icon(
                                    Icons.notifications_active,
                                    color: Colors.white,
                                  ),
                                ),

                                const SizedBox(width: 14),

                                const Expanded(
                                  child: Text(
                                    "Upcoming Deadlines",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 20),

                            ...upcomingDeadlines.map((goal) {
                              return Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.all(14),

                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(.15),
                                  borderRadius: BorderRadius.circular(14),
                                ),

                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 18,
                                      backgroundColor: Colors.white24,
                                      child: const Icon(
                                        Icons.flag_circle,
                                        color: Colors.white,
                                        size: 18,
                                      ),
                                    ),

                                    const SizedBox(width: 12),

                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            goal['title'],
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                          ),

                                          const SizedBox(height: 4),

                                          Text(
                                            "${goal['days_remaining'].ceil()} day(s) remaining",
                                            style: const TextStyle(
                                              color: Colors.white70,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),

                                    const Icon(
                                      Icons.chevron_right,
                                      color: Colors.white,
                                    ),
                                  ],
                                ),
                              );
                            }),
                          ],
                        ),
                      ),
                    ),

                  ...goals.map<Widget>((goal) {
                    final target =
                        double.tryParse(goal['target_amount'].toString()) ?? 0;

                    final saved =
                        double.tryParse(goal['saved_amount'].toString()) ?? 0;

                    final double percentage = target > 0
                        ? (saved / target).clamp(0.0, 1.0).toDouble()
                        : 0.0;

                    final Map<String, dynamic>? insight =
                        goalInsights[goal['id']] as Map<String, dynamic>?;

                    final insightDays =
                        (insight?['days_remaining'] as num?)?.ceil() ?? 0;

                    Color insightColor = Colors.green;

                    if (insight != null) {
                      switch (insight['status']) {
                        case 'urgent':
                          insightColor = Colors.red;
                          break;

                        case 'completed':
                          insightColor = Colors.green;
                          break;

                        default:
                          insightColor = Colors.blue;
                      }
                    }

                    final Map<String, dynamic>? forecast =
                        forecasts[goal['id']] as Map<String, dynamic>?;

                    Color forecastColor = Colors.blue;
                    IconData forecastIcon = Icons.trending_flat;

                    if (forecast != null) {
                      switch (forecast['forecast']) {
                        case 'ahead':
                          forecastColor = Colors.green;
                          forecastIcon = Icons.trending_up;
                          break;

                        case 'behind':
                          forecastColor = Colors.red;
                          forecastIcon = Icons.trending_down;
                          break;

                        case 'completed':
                          forecastColor = Colors.teal;
                          forecastIcon = Icons.emoji_events;
                          break;

                        case 'on_track':
                          forecastColor = Colors.blue;
                          forecastIcon = Icons.track_changes;
                          break;
                      }
                    }

                    return Card(
                      elevation: 4,
                      shadowColor: Colors.black12,
                      margin: const EdgeInsets.only(bottom: 24),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(22),

                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,

                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 24,
                                  backgroundColor: Colors.blue.withOpacity(.12),

                                  child: Icon(
                                    percentage >= 1
                                        ? Icons.emoji_events
                                        : Icons.flag,

                                    color: percentage >= 1
                                        ? Colors.amber
                                        : Colors.blue,
                                  ),
                                ),

                                const SizedBox(width: 14),

                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        goal['title'],
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium
                                            ?.copyWith(
                                              fontWeight: FontWeight.bold,
                                            ),
                                      ),

                                      const SizedBox(height: 6),

                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: percentage >= 1
                                              ? Colors.green.withOpacity(.15)
                                              : percentage >= .75
                                              ? Colors.orange.withOpacity(.15)
                                              : Colors.blue.withOpacity(.15),
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                        ),
                                        child: Text(
                                          percentage >= 1
                                              ? "Completed"
                                              : percentage >= .75
                                              ? "Almost There"
                                              : "In Progress",
                                          style: TextStyle(
                                            color: percentage >= 1
                                                ? Colors.green
                                                : percentage >= .75
                                                ? Colors.orange
                                                : Colors.blue,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                const SizedBox(height: 4),

                                Text(
                                  goal['target_date'] != null
                                      ? DateFormat('dd MMM yyyy').format(
                                          DateTime.parse(goal['target_date']),
                                        )
                                      : "No deadline",

                                  style: TextStyle(color: Colors.grey.shade600),
                                ),
                              ],
                            ),

                            const SizedBox(height: 22),

                            Text(
                              currency.format(saved),

                              style: const TextStyle(
                                fontSize: 30,
                                fontWeight: FontWeight.bold,
                              ),
                            ),

                            const SizedBox(height: 6),

                            Text(
                              "Saved of ${currency.format(target)} target",

                              style: TextStyle(color: Colors.grey.shade600),
                            ),

                            const SizedBox(height: 18),

                            TweenAnimationBuilder<double>(
                              duration: const Duration(milliseconds: 900),
                              tween: Tween(begin: 0, end: percentage),
                              builder: (_, value, __) {
                                return ClipRRect(
                                  borderRadius: BorderRadius.circular(20),

                                  child: LinearProgressIndicator(
                                    value: value,
                                    minHeight: 10,

                                    backgroundColor: Colors.grey.shade300,

                                    color: percentage >= 1
                                        ? Colors.green
                                        : percentage >= .75
                                        ? Colors.orange
                                        : Colors.blue,
                                  ),
                                );
                              },
                            ),

                            const SizedBox(height: 22),

                            Row(
                              children: [
                                Icon(
                                  Icons.lightbulb_outline,
                                  color: Colors.amber,
                                  size: 20,
                                ),

                                SizedBox(width: 8),

                                Text(
                                  "Smart Insight",
                                  style: Theme.of(context).textTheme.titleSmall
                                      ?.copyWith(fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),

                            const SizedBox(height: 12),

                            if (insight != null)
                              FadeSlideAnimation(
                                delay: 300,
                                child: Container(
                                  margin: const EdgeInsets.symmetric(
                                    vertical: 18,
                                  ),
                                  padding: const EdgeInsets.all(18),
                                  decoration: BoxDecoration(
                                    color: insightColor.withOpacity(.08),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: insightColor.withOpacity(.25),
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          CircleAvatar(
                                            radius: 20,
                                            backgroundColor: insightColor
                                                .withOpacity(.15),
                                            child: Icon(
                                              insight['status'] == 'completed'
                                                  ? Icons.emoji_events
                                                  : insight['status'] ==
                                                        'urgent'
                                                  ? Icons.warning_amber_rounded
                                                  : Icons.track_changes,
                                              color: insightColor,
                                            ),
                                          ),

                                          const SizedBox(width: 12),

                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              const Text(
                                                "Goal Insight",
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 16,
                                                ),
                                              ),

                                              Text(
                                                insight['status']
                                                    .toString()
                                                    .replaceAll('_', ' ')
                                                    .toUpperCase(),
                                                style: TextStyle(
                                                  color: insightColor,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),

                                      const SizedBox(height: 18),

                                      Row(
                                        children: [
                                          Expanded(
                                            child: buildInsightMetric(
                                              title: "Remaining",

                                              value: currency.format(
                                                (insight['remaining_amount']
                                                            as num?)
                                                        ?.toDouble() ??
                                                    0,
                                              ),
                                              icon:
                                                  Icons.account_balance_wallet,
                                              color: insightColor,
                                            ),
                                          ),

                                          const SizedBox(width: 12),

                                          Expanded(
                                            child: buildInsightMetric(
                                              title: "Days Left",
                                              value: "$insightDays",
                                              icon: Icons.calendar_today,
                                              color: insightColor,
                                            ),
                                          ),
                                        ],
                                      ),

                                      const SizedBox(height: 12),

                                      buildInsightMetric(
                                        title: "Monthly Needed",
                                        value: currency.format(
                                          (insight['monthly_needed'] as num?)
                                                  ?.toDouble() ??
                                              0,
                                        ),
                                        icon: Icons.savings,
                                        color: insightColor,
                                      ),

                                      const SizedBox(height: 16),

                                      Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.all(14),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(.05),
                                          borderRadius: BorderRadius.circular(
                                            14,
                                          ),
                                        ),
                                        child: Text(
                                          insight['message'] ?? '',
                                          style: const TextStyle(
                                            fontStyle: FontStyle.italic,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                            if (percentage >= 1.0)
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  buildMilestoneBadge(
                                    title: "Goal Completed",
                                    icon: Icons.emoji_events,
                                    color: Colors.amber,
                                  ),
                                  const SizedBox(height: 12),

                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton.icon(
                                      style: ElevatedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 14,
                                        ),
                                        backgroundColor: Theme.of(
                                          context,
                                        ).colorScheme.primary,
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                        ),
                                        elevation: 0,
                                      ),
                                      icon: const Icon(Icons.archive_outlined),
                                      label: const Text("Archive Goal"),
                                      onPressed: () async {
                                        final confirm = await showDialog<bool>(
                                          context: context,
                                          builder: (_) => AlertDialog(
                                            title: const Text('Archive Goal'),
                                            content: const Text(
                                              'This completed goal will be moved to your archive.',
                                            ),
                                            actions: [
                                              TextButton(
                                                onPressed: () => Navigator.pop(
                                                  context,
                                                  false,
                                                ),
                                                child: const Text('Cancel'),
                                              ),
                                              ElevatedButton(
                                                onPressed: () => Navigator.pop(
                                                  context,
                                                  true,
                                                ),
                                                child: const Text('Archive'),
                                              ),
                                            ],
                                          ),
                                        );

                                        if (confirm != true) return;

                                        final connectivity = context
                                            .read<ConnectivityProvider>();

                                        if (connectivity.isOnline) {
                                          await ApiService.archiveGoal(
                                            goal['id'],
                                          );

                                          // Update SQLite immediately
                                          await goalsRepository
                                              .archiveGoalOnline(goal['id']);
                                        } else {
                                          await goalsRepository
                                              .archiveGoalOffline(goal['id']);
                                        }

                                        await loadGoals();

                                        if (!mounted) return;

                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              connectivity.isOnline
                                                  ? "Goal archived successfully."
                                                  : "Goal archived offline. It will sync automatically.",
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              )
                            else if (percentage >= 0.75)
                              buildMilestoneBadge(
                                title: "75% Almost There",
                                icon: Icons.bolt,
                                color: Colors.orange,
                              )
                            else if (percentage >= 0.50)
                              buildMilestoneBadge(
                                title: "50% Progress",
                                icon: Icons.trending_up,
                                color: Colors.indigo,
                              )
                            else if (percentage >= 0.25)
                              buildMilestoneBadge(
                                title: "25% Saved",
                                icon: Icons.savings,
                                color: Colors.green,
                              )
                            else
                              const SizedBox(height: 14),

                            Align(
                              alignment: Alignment.centerRight,

                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 7,
                                ),

                                decoration: BoxDecoration(
                                  color: Colors.blue.withOpacity(.12),
                                  borderRadius: BorderRadius.circular(20),
                                ),

                                child: TweenAnimationBuilder<double>(
                                  duration: const Duration(milliseconds: 800),
                                  tween: Tween(begin: 0, end: percentage * 100),
                                  builder: (_, value, __) {
                                    return Text(
                                      "${value.toStringAsFixed(0)}%",
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),

                            const SizedBox(height: 22),

                            Row(
                              children: [
                                Icon(
                                  Icons.auto_graph,
                                  color: Colors.indigo,
                                  size: 20,
                                ),

                                SizedBox(width: 8),

                                Text(
                                  "Savings Forecast",
                                  style: Theme.of(context).textTheme.titleSmall
                                      ?.copyWith(fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),

                            const SizedBox(height: 20),

                            if (forecast != null)
                              FadeSlideAnimation(
                                delay: 450,
                                child: Container(
                                  margin: const EdgeInsets.only(top: 20),
                                  padding: const EdgeInsets.all(18),
                                  decoration: BoxDecoration(
                                    color: forecastColor.withOpacity(.08),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: forecastColor.withOpacity(.25),
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          CircleAvatar(
                                            radius: 20,
                                            backgroundColor: forecastColor
                                                .withOpacity(.15),
                                            child: Icon(
                                              forecastIcon,
                                              color: forecastColor,
                                            ),
                                          ),

                                          const SizedBox(width: 12),

                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              const Text(
                                                "Savings Forecast",
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 16,
                                                ),
                                              ),

                                              Text(
                                                forecast['forecast']
                                                    .toString()
                                                    .replaceAll('_', ' ')
                                                    .toUpperCase(),
                                                style: TextStyle(
                                                  color: forecastColor,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),

                                      const SizedBox(height: 18),

                                      Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.all(14),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(.05),
                                          borderRadius: BorderRadius.circular(
                                            14,
                                          ),
                                        ),
                                        child: Text(
                                          forecast['message'],
                                          style: const TextStyle(
                                            fontStyle: FontStyle.italic,
                                          ),
                                        ),
                                      ),

                                      const SizedBox(height: 18),

                                      Row(
                                        children: [
                                          Expanded(
                                            child: buildForecastMetric(
                                              title: "Completion",
                                              value:
                                                  (forecast['estimated_completion_date']
                                                      as String?) ??
                                                  "Unknown",
                                              icon: Icons.calendar_today,
                                              color: forecastColor,
                                            ),
                                          ),

                                          const SizedBox(width: 12),

                                          Expanded(
                                            child: buildForecastMetric(
                                              title: "Daily",
                                              value: currency.format(
                                                (forecast['recommended_daily_saving']
                                                            as num?)
                                                        ?.toDouble() ??
                                                    0,
                                              ),
                                              icon: Icons.savings,
                                              color: forecastColor,
                                            ),
                                          ),
                                        ],
                                      ),

                                      const SizedBox(height: 12),

                                      buildForecastMetric(
                                        title: "Monthly Saving",

                                        value: currency.format(
                                          (forecast['recommended_monthly_saving']
                                                      as num?)
                                                  ?.toDouble() ??
                                              0,
                                        ),

                                        icon: Icons.account_balance_wallet,

                                        color: forecastColor,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            const SizedBox(height: 10),

                            SizedBox(
                              width: double.infinity,

                              child: ElevatedButton.icon(
                                onPressed: percentage >= 1.0
                                    ? null
                                    : () {
                                        showAddSavingsDialog(goal['id']);
                                      },

                                style: ElevatedButton.styleFrom(
                                  minimumSize: const Size.fromHeight(52),
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),

                                  disabledBackgroundColor: Colors.green
                                      .withOpacity(.15),
                                  disabledForegroundColor: Colors.green,
                                ),

                                icon: const Icon(Icons.savings),

                                label: const Text('Add Savings'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ],
              ),
      ),
    );
  }
}
