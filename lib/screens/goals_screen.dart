import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_services.dart';
import '../services/notification_service.dart';

import '../widgets/goal_section_header.dart';
import '../widgets/goal_loading_skeleton.dart';
import '../widgets/goal_stat_card.dart';
import '../widgets/goal_empty_state.dart';
import '../widgets/fade_slide_animation.dart';

import 'add_goals_screen.dart';
import 'archived_goals_screen.dart';

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

  @override
  void initState() {
    super.initState();

    loadGoals();
    loadUpcomingDeadlines();
    loadGoalsAnalytics();
  }

  Future<void> loadGoals() async {
    try {
      final data = await ApiService.getGoals();
      Map<int, dynamic> loadedForecasts = {};

      for (final goal in data) {
        final forecast = await ApiService.getGoalForecast(goal['id']);

        loadedForecasts[goal['id']] = forecast;
      }

      setState(() {
        goals = data;
        forecasts = loadedForecasts;
        isLoading = false;
      });
      await loadGoalInsights();
    } catch (e) {
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
      final data = await ApiService.getGoalAnalytics();

      setState(() {
        goalAnalytics = data;
        isLoading = false;
      });
      await loadGoalsAnalytics();
    } catch (e) {
      setState(() {
        isLoading = false;
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Future<void> loadGoalInsights() async {
    try {
      final Map<int, dynamic> insightsMap = {};

      for (final goal in goals) {
        final insight = await ApiService.getGoalInsights(goal['id']);

        insightsMap[goal['id']] = insight;
      }

      setState(() {
        goalInsights = insightsMap;
      });
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  Future<void> loadUpcomingDeadlines() async {
    try {
      final data = await ApiService.getUpcomingGoalDeadlines();

      for (final goal in data) {
        final days = int.tryParse(goal['days_remaining'].toString()) ?? 0;

        if (days <= 3) {
          await NotificationService.showNotification(
            title: '🎯 Goal Deadline Approaching',
            body: '${goal['title']} is due in $days day(s)',
          );
        }
      }

      setState(() {
        upcomingDeadlines = data;
      });
    } catch (e) {
      debugPrint(e.toString());
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

                final response = await ApiService.updateGoalProgress(
                  goalId,
                  amount,
                );

                final milestone = response['milestone'];

                if (!mounted) return;

                Navigator.pop(context);

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

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final theme = Theme.of(context);

    final screenSize = MediaQuery.of(context).size;

    final screenHeight = screenSize.height;

    final sectionSpacing = screenHeight * .035;

    const double cardSpacing = 24;

    const double internalSpacing = 16;

    if (isLoading) {
      return const GoalLoadingSkeleton();
    }

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddGoalScreen()),
          );

          if (result == true) {
            loadGoals();
          }
        },
        child: const Icon(Icons.add),
      ),

      body: RefreshIndicator(
        onRefresh: loadGoals,
        child: goals.isEmpty
            ? ListView(
                children: const [
                  SizedBox(height: 300),
                  Center(
                    child: Text(
                      'No financial goals yet',
                      style: TextStyle(fontSize: 18),
                    ),
                  ),
                ],
              )
            : ListView(
                key: const PageStorageKey("goals"),
                padding: const EdgeInsets.all(16),
                children: [
                  FadeSlideAnimation(
                    child: Card(
                      elevation: 2,
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
                          color: Colors.green,
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
                      elevation: 2,
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

                  ...goals.map((goal) {
                    final target =
                        double.tryParse(goal['target_amount'].toString()) ?? 0;

                    final saved =
                        double.tryParse(goal['saved_amount'].toString()) ?? 0;

                    final double percentage = target > 0
                        ? (saved / target).clamp(0.0, 1.0).toDouble()
                        : 0.0;

                    final insight = goalInsights[goal['id']];

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

                    final forecast = forecasts[goal['id']];

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
                      elevation: 2,
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

                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
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
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 10,
                                                    vertical: 4,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: percentage >= 1
                                                    ? Colors.green.withOpacity(
                                                        .15,
                                                      )
                                                    : percentage >= .75
                                                    ? Colors.orange.withOpacity(
                                                        .15,
                                                      )
                                                    : Colors.blue.withOpacity(
                                                        .15,
                                                      ),
                                                borderRadius:
                                                    BorderRadius.circular(20),
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
                                                DateTime.parse(
                                                  goal['target_date'],
                                                ),
                                              )
                                            : "No deadline",

                                        style: TextStyle(
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                    ],
                                  ),
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

                            if (insight != null)
                              Container(
                                margin: const EdgeInsets.only(
                                  top: 12,
                                  bottom: 12,
                                ),

                                padding: const EdgeInsets.all(12),

                                decoration: BoxDecoration(
                                  color: insightColor.withOpacity(0.1),

                                  borderRadius: BorderRadius.circular(12),

                                  border: Border.all(color: insightColor),
                                ),

                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,

                                  children: [
                                    Row(
                                      children: [
                                        Icon(
                                          insight['status'] == 'completed'
                                              ? Icons.emoji_events
                                              : insight['status'] == 'urgent'
                                              ? Icons.warning
                                              : Icons.track_changes,
                                          color: insightColor,
                                        ),

                                        const SizedBox(width: 8),

                                        Text(
                                          insight['status']
                                              .toString()
                                              .toUpperCase(),
                                          style: TextStyle(
                                            color: insightColor,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),

                                    const SizedBox(height: 8),

                                    Text(
                                      'Remaining: ${currency.format(insight['remaining_amount'])}',
                                    ),

                                    Text(
                                      'Days Left: ${insight['days_remaining'].ceil()}',
                                    ),

                                    Text(
                                      'Monthly Savings Needed: ${currency.format(insight['monthly_needed'])}',
                                    ),

                                    const SizedBox(height: 6),

                                    Text(
                                      insight['message'] ?? '',
                                      style: const TextStyle(
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                  ],
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

                                        await ApiService.archiveGoal(
                                          goal['id'],
                                        );

                                        if (!mounted) return;

                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'Goal archived successfully',
                                            ),
                                          ),
                                        );

                                        loadGoals();
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

                                child: Text(
                                  "${(percentage * 100).toStringAsFixed(0)}%",
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),

                            if (forecast != null)
                              Card(
                                margin: const EdgeInsets.only(top: 12),
                                color: forecastColor.withOpacity(0.12),
                                elevation: 0,
                                child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(
                                            forecastIcon,
                                            color: forecastColor,
                                          ),

                                          const SizedBox(width: 8),

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

                                      const SizedBox(height: 8),

                                      Text(forecast['message']),

                                      const SizedBox(height: 10),

                                      Row(
                                        children: [
                                          const Icon(
                                            Icons.calendar_today,
                                            size: 16,
                                          ),

                                          const SizedBox(width: 6),

                                          Expanded(
                                            child: Text(
                                              forecast['estimated_completion_date'] ??
                                                  'Completion date unavailable',
                                            ),
                                          ),
                                        ],
                                      ),

                                      const SizedBox(height: 6),

                                      Row(
                                        children: [
                                          const Icon(Icons.savings, size: 16),

                                          const SizedBox(width: 6),

                                          Expanded(
                                            child: Text(
                                              '${currency.format(forecast['recommended_daily_saving'])}/day',
                                            ),
                                          ),
                                        ],
                                      ),

                                      const SizedBox(height: 4),

                                      Row(
                                        children: [
                                          const Icon(
                                            Icons.account_balance_wallet,
                                            size: 16,
                                          ),

                                          const SizedBox(width: 6),

                                          Expanded(
                                            child: Text(
                                              '${currency.format(forecast['recommended_monthly_saving'])}/month',
                                            ),
                                          ),
                                        ],
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
