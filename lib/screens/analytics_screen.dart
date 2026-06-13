import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:pesapulse_mobile/widgets/loading_widget.dart';

import '../services/api_services.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  List expenses = [];

  bool isLoading = true;

  double totalSpending = 0;

  Map<String, double> categoryTotals = {};

  int totalGoals = 0;
  int completedGoals = 0;
  int activeGoals = 0;
  double completionRate = 0;

  @override
  void initState() {
    super.initState();

    fetchAnalytics();
  }

  Future<void> fetchAnalytics() async {
    try {
      final response = await ApiService.getExpenses();

      final goalAnalytics = await ApiService.getGoalAnalytics();

      final List data = response['data'] ?? [];

      double total = 0;

      Map<String, double> categories = {};

      for (var expense in data) {
        double amount = double.parse(expense['amount'].toString());

        String category = expense['category'];

        total += amount;

        if (categories.containsKey(category)) {
          categories[category] = categories[category]! + amount;
        } else {
          categories[category] = amount;
        }
      }

      setState(() {
        expenses = data;

        totalSpending = total;

        categoryTotals = categories;

        totalGoals = int.tryParse(goalAnalytics['total_goals'].toString()) ?? 0;

        completedGoals =
            int.tryParse(goalAnalytics['completed_goals'].toString()) ?? 0;

        activeGoals =
            int.tryParse(goalAnalytics['active_goals'].toString()) ?? 0;

        completionRate =
            double.tryParse(goalAnalytics['completion_rate'].toString()) ?? 0;

        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });

      debugPrint('Analytics Error: $e');
    }
  }

  List<PieChartSectionData> getSections() {
    final List<Color> colors = [
      Colors.green,
      Colors.blue,
      Colors.orange,
      Colors.purple,
      Colors.red,
      Colors.teal,
    ];

    int index = 0;

    return categoryTotals.entries.map((entry) {
      final section = PieChartSectionData(
        color: colors[index % colors.length],
        value: entry.value,

        title: '${entry.key}\nKES ${entry.value.toStringAsFixed(0)}',

        radius: 100,

        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );

      index++;

      return section;
    }).toList();
  }

  Widget buildStatCard(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),

      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
      ),

      child: Column(
        children: [
          Icon(icon, size: 30),

          const SizedBox(height: 10),

          Text(
            value,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 5),

          Text(title),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return isLoading
        ? const LoadingWidget()
        : SingleChildScrollView(
            padding: const EdgeInsets.all(20),

            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,

              children: [
                Container(
                  width: double.infinity,

                  padding: const EdgeInsets.all(20),

                  decoration: BoxDecoration(
                    color: Colors.green,

                    borderRadius: BorderRadius.circular(20),
                  ),

                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,

                    children: [
                      const Text(
                        'Total Spending',

                        style: TextStyle(color: Colors.white70, fontSize: 16),
                      ),

                      const SizedBox(height: 10),

                      Text(
                        'KES ${totalSpending.toStringAsFixed(2)}',

                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 30),

                Row(
                  children: [
                    Expanded(
                      child: buildStatCard(
                        'Goals',
                        totalGoals.toString(),
                        Icons.flag,
                      ),
                    ),

                    const SizedBox(width: 12),

                    Expanded(
                      child: buildStatCard(
                        'Completed',
                        completedGoals.toString(),
                        Icons.emoji_events,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      child: buildStatCard(
                        'Active',
                        activeGoals.toString(),
                        Icons.track_changes,
                      ),
                    ),

                    const SizedBox(width: 12),

                    Expanded(
                      child: buildStatCard(
                        'Rate',
                        '${completionRate.toStringAsFixed(0)}%',
                        Icons.trending_up,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 30),

                const Text(
                  'Category Breakdown',

                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 20),

                SizedBox(
                  height: 300,

                  child: PieChart(
                    PieChartData(
                      sections: getSections(),

                      centerSpaceRadius: 40,

                      sectionsSpace: 3,
                    ),
                  ),
                ),
              ],
            ),
          );
  }
}
