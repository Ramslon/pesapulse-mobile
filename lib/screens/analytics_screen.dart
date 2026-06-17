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

  List<String> insights = [];

  bool isLoading = true;

  double totalSpending = 0;

  Map<String, double> categoryTotals = {};

  Map<int, double> monthlyTotals = {};

  int totalGoals = 0;
  int completedGoals = 0;
  int activeGoals = 0;
  double completionRate = 0;

  double healthScore = 0;
  String healthStatus = '';

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

      Map<int, double> monthlyData = {};

      for (var expense in data) {
        double amount = double.parse(expense['amount'].toString());

        String category = expense['category'];

        total += amount;

        DateTime date = DateTime.parse(expense['created_at']);

        int month = date.month;

        monthlyData[month] = (monthlyData[month] ?? 0) + amount;

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

        monthlyTotals = monthlyData;

        totalGoals = int.tryParse(goalAnalytics['total_goals'].toString()) ?? 0;

        completedGoals =
            int.tryParse(goalAnalytics['completed_goals'].toString()) ?? 0;

        activeGoals =
            int.tryParse(goalAnalytics['active_goals'].toString()) ?? 0;

        completionRate =
            double.tryParse(goalAnalytics['completion_rate'].toString()) ?? 0;

        calculateHealthScore();

        generateInsights();

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

  List<PieChartSectionData> getGoalSections() {
    return [
      PieChartSectionData(
        color: Colors.green,
        value: completedGoals.toDouble(),
        title: 'Completed\n$completedGoals',
        radius: 90,
        titleStyle: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),

      PieChartSectionData(
        color: Colors.orange,
        value: activeGoals.toDouble(),
        title: 'Active\n$activeGoals',
        radius: 90,
        titleStyle: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    ];
  }

  List<BarChartGroupData> getMonthlyBars() {
    return monthlyTotals.entries.map((entry) {
      return BarChartGroupData(
        x: entry.key,

        barRods: [
          BarChartRodData(
            toY: entry.value,
            width: 18,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      );
    }).toList();
  }

  void calculateHealthScore() {
    double score = 0;

    // Goal completion contributes up to 50 points
    score += completionRate * 0.5;

    // Active goals contribute up to 25 points
    if (totalGoals > 0) {
      score += ((totalGoals - activeGoals) / totalGoals) * 25;
    }

    // Budget discipline contributes up to 25 points
    if (totalSpending > 0) {
      score += 25;
    }

    healthScore = score.clamp(0, 100);

    if (healthScore >= 80) {
      healthStatus = 'Excellent';
    } else if (healthScore >= 60) {
      healthStatus = 'Good';
    } else if (healthScore >= 40) {
      healthStatus = 'Fair';
    } else {
      healthStatus = 'Needs Improvement';
    }
  }

  void generateInsights() {
    insights.clear();

    if (categoryTotals.isNotEmpty) {
      final highestCategory = categoryTotals.entries.reduce(
        (a, b) => a.value > b.value ? a : b,
      );

      insights.add(
        'Highest spending category: ${highestCategory.key} '
        '(KES ${highestCategory.value.toStringAsFixed(0)})',
      );
    }

    if (completionRate == 100) {
      insights.add('Excellent! All your financial goals have been completed.');
    } else if (completionRate >= 50) {
      insights.add('Good progress on your financial goals.');
    } else {
      insights.add(
        'Consider increasing savings contributions toward your goals.',
      );
    }

    if (healthScore >= 80) {
      insights.add('Your financial health is excellent.');
    } else {
      insights.add('There is room to improve your financial health score.');
    }
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

                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),

                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),

                    color: healthScore >= 80
                        ? Colors.green
                        : healthScore >= 60
                        ? Colors.orange
                        : Colors.red,
                  ),

                  child: Column(
                    children: [
                      const Text(
                        'Financial Health Score',
                        style: TextStyle(color: Colors.white, fontSize: 18),
                      ),

                      const SizedBox(height: 10),

                      Text(
                        '${healthScore.toStringAsFixed(0)}/100',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 5),

                      Text(
                        healthStatus,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
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
                const SizedBox(height: 40),

                const Text(
                  'Goal Status',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 20),

                SizedBox(
                  height: 250,
                  child: PieChart(
                    PieChartData(
                      sections: getGoalSections(),
                      centerSpaceRadius: 40,
                      sectionsSpace: 3,
                    ),
                  ),
                ),

                const SizedBox(height: 40),

                const Text(
                  'Monthly Spending Trend',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 20),

                SizedBox(
                  height: 300,

                  child: BarChart(
                    BarChartData(
                      borderData: FlBorderData(show: false),

                      titlesData: FlTitlesData(
                        leftTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: true),
                        ),

                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,

                            getTitlesWidget: (value, meta) {
                              const months = [
                                '',
                                'Jan',
                                'Feb',
                                'Mar',
                                'Apr',
                                'May',
                                'Jun',
                                'Jul',
                                'Aug',
                                'Sep',
                                'Oct',
                                'Nov',
                                'Dec',
                              ];

                              return Text(months[value.toInt()]);
                            },
                          ),
                        ),
                      ),

                      barGroups: getMonthlyBars(),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                Center(
                  child: Text(
                    '$completedGoals of $totalGoals goals completed',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                const SizedBox(height: 40),

                const Text(
                  'Smart Insights',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 20),

                ...insights.map(
                  (insight) => Card(
                    child: ListTile(
                      leading: const Icon(Icons.lightbulb, color: Colors.amber),
                      title: Text(insight),
                    ),
                  ),
                ),
              ],
            ),
          );
  }
}
