import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_services.dart';
import '../services/notification_service.dart';

import 'add_goals_screen.dart';
import 'archived_goals_screen.dart';

class GoalsScreen extends StatefulWidget {
  const GoalsScreen({super.key});

  @override
  State<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends State<GoalsScreen> {
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

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Financial Goals'),
        centerTitle: true,

        actions: [
          IconButton(
            tooltip: 'Archived Goals',
            icon: const Icon(Icons.archive),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ArchivedGoalsScreen()),
              ).then((_) {
                loadGoals();
              });
            },
          ),
        ],
      ),
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
                padding: const EdgeInsets.all(16),
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              children: [
                                const Text(
                                  'Goals',
                                  style: TextStyle(color: Colors.grey),
                                ),

                                Text(
                                  '${goalAnalytics?['total_goals'] ?? 0}',
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(width: 10),

                      Expanded(
                        child: Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              children: [
                                const Text(
                                  'Completed',
                                  style: TextStyle(color: Colors.grey),
                                ),

                                Text(
                                  '${goalAnalytics?['completed_goals'] ?? 0}',
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.trending_up),
                      title: const Text('Success Rate'),
                      trailing: Text(
                        '${goalAnalytics?['completion_rate'] ?? 0}%',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  if (upcomingDeadlines.isNotEmpty)
                    Card(
                      color: const Color(0xFFFFF3E0),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                        side: BorderSide(color: Colors.orange.shade300),
                      ),
                      margin: const EdgeInsets.only(bottom: 20),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.notifications_active,
                                  color: Colors.orange.shade700,
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  'Upcoming Goal Deadlines',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 17,
                                    color: Colors.orange.shade900,
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 15),

                            ...upcomingDeadlines.map((goal) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.flag_circle,
                                      size: 18,
                                      color: Colors.red.shade400,
                                    ),

                                    const SizedBox(width: 8),

                                    Expanded(
                                      child: Text(
                                        '${goal['title']} • ${goal['days_remaining'].ceil()} day(s) left',
                                        style: const TextStyle(
                                          color: Colors.black87,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
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
                      margin: const EdgeInsets.only(bottom: 15),

                      child: Padding(
                        padding: const EdgeInsets.all(16),

                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,

                          children: [
                            Row(
                              children: [
                                Icon(
                                  percentage >= 1.0
                                      ? Icons.emoji_events
                                      : Icons.flag,
                                  color: percentage >= 1.0
                                      ? Colors.amber
                                      : Colors.blue,
                                ),

                                const SizedBox(width: 10),

                                Expanded(
                                  child: Text(
                                    goal['title'],
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 6),

                            Row(
                              children: [
                                const Icon(
                                  Icons.calendar_today,
                                  size: 16,
                                  color: Colors.grey,
                                ),

                                const SizedBox(width: 6),

                                Text(
                                  goal['target_date'] != null
                                      ? DateFormat('dd MMM yyyy').format(
                                          DateTime.parse(goal['target_date']),
                                        )
                                      : 'No deadline',
                                  style: const TextStyle(color: Colors.grey),
                                ),
                              ],
                            ),

                            const SizedBox(height: 10),

                            Text(
                              '${currency.format(saved)} / ${currency.format(target)}',
                            ),

                            const SizedBox(height: 10),

                            LinearProgressIndicator(
                              value: percentage,
                              minHeight: 10,
                              borderRadius: BorderRadius.circular(10),
                              color: percentage >= 1.0
                                  ? Colors.green
                                  : percentage >= 0.75
                                  ? Colors.orange
                                  : Colors.blue,
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
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.orange.shade900,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.star, size: 18),
                                        SizedBox(width: 8),
                                        Flexible(
                                          child: Text(
                                            '🏆 Goal Completed',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  const SizedBox(height: 12),

                                  SizedBox(
                                    width: double.infinity,
                                    child: OutlinedButton.icon(
                                      icon: const Icon(Icons.archive),
                                      label: const Text('Archive Goal'),
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
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.orange.shade400,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.star, size: 18),
                                    SizedBox(width: 8),
                                    Flexible(
                                      child: Text(
                                        '75% Milestone',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            else if (percentage >= 0.50)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade400,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.star, size: 18),
                                    SizedBox(width: 8),
                                    Flexible(
                                      child: Text(
                                        '50% Milestone',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            else if (percentage >= 0.25)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.green.shade400,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.star, size: 18),
                                    SizedBox(width: 8),
                                    Flexible(
                                      child: Text(
                                        '25% Milestone',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            else
                              Text(
                                '${(percentage * 100).toStringAsFixed(0)}% Complete',
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
