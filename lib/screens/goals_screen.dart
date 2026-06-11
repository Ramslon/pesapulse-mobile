import 'package:flutter/material.dart';
import '../services/api_services.dart';

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

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (goals.isEmpty) {
      return const Center(
        child: Text('No financial goals yet', style: TextStyle(fontSize: 18)),
      );
    }

    return RefreshIndicator(
      onRefresh: loadGoals,

      child: ListView.builder(
        padding: const EdgeInsets.all(16),

        itemCount: goals.length,

        itemBuilder: (context, index) {
          final goal = goals[index];

          final target = double.tryParse(goal['target_amount'].toString()) ?? 0;

          final saved = double.tryParse(goal['saved_amount'].toString()) ?? 0;

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
                  Text(
                    goal['title'],

                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 10),

                  Text(
                    'KES ${saved.toStringAsFixed(0)} / ${target.toStringAsFixed(0)}',
                  ),

                  const SizedBox(height: 10),

                  LinearProgressIndicator(value: percentage, minHeight: 10),

                  const SizedBox(height: 10),

                  Text('${(percentage * 100).toStringAsFixed(0)}% Complete'),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
