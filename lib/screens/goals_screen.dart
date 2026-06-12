import 'package:flutter/material.dart';
import '../services/api_services.dart';

import 'add_goals_screen.dart';

class GoalsScreen extends StatefulWidget {
  const GoalsScreen({super.key});

  @override
  State<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends State<GoalsScreen> {
  bool isLoading = true;

  List goals = [];

  @override
  void initState() {
    super.initState();

    loadGoals();
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

                await ApiService.updateGoalProgress(goalId, amount);

                if (!mounted) return;

                Navigator.pop(context);

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
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: goals.length,

                itemBuilder: (context, index) {
                  final goal = goals[index];

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
                          ),

                          if (percentage >= 1.0)
                            const Padding(
                              padding: EdgeInsets.only(top: 10),
                              child: Text(
                                '🎉 Congratulations! You achieved this goal.',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),

                          const SizedBox(height: 10),

                          percentage >= 1.0
                              ? Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),

                                  decoration: BoxDecoration(
                                    color: Colors.green,
                                    borderRadius: BorderRadius.circular(10),
                                  ),

                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,

                                    children: [
                                      Icon(
                                        Icons.check_circle,
                                        color: Colors.white,
                                      ),

                                      SizedBox(width: 8),

                                      Text(
                                        'Goal Achieved',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              : Text(
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
                },
              ),
      ),
    );
  }
}
