import 'package:flutter/material.dart';
import '../services/api_services.dart';
import '../services/notification_service.dart';

import 'add_goals_screen.dart';

class GoalsScreen extends StatefulWidget {
  const GoalsScreen({super.key});

  @override
  State<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends State<GoalsScreen> {
  bool isLoading = true;

  List goals = [];

  List upcomingDeadlines = [];

  @override
  void initState() {
    super.initState();

    loadGoals();
    loadUpcomingDeadlines();
  }

  Future<void> loadGoals() async {
    try {
      final data = await ApiService.getGoals();

      setState(() {
        goals = data;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
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
                  if (upcomingDeadlines.isNotEmpty)
                    Card(
                      color: Colors.orange.shade50,
                      margin: const EdgeInsets.only(bottom: 20),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(
                                  Icons.notifications_active,
                                  color: Colors.orange,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'Upcoming Goal Deadlines',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 10),

                            ...upcomingDeadlines.map((deadline) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Text(
                                  '🎯 ${deadline['title']} - ${deadline['days_remaining']} day(s) left',
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

                            const SizedBox(height: 10),

                            Text(
                              'KES ${saved.toStringAsFixed(2)} / ${target.toStringAsFixed(0)}',
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

                            if (percentage >= 1.0)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.green,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Row(
                                  children: const [
                                    Icon(
                                      Icons.emoji_events,
                                      color: Colors.white,
                                    ),

                                    SizedBox(width: 10),

                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Goal Achieved',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                          ),

                                          Text(
                                            'Congratulations! You achieved this goal.',
                                            style: TextStyle(
                                              color: Colors.white,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
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
