import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:pesapulse_mobile/widgets/loading_widget.dart';

import '../services/api_services.dart';
import '../services/export_service.dart';
import '../services/report_history_service.dart';

import 'dart:io';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen>
    with AutomaticKeepAliveClientMixin {
  List expenses = [];

  List<String> insights = [];

  List<Map<String, dynamic>> reports = [];

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

  double budgetAmount = 0;
  double budgetSpent = 0;
  double budgetRemaining = 0;
  double budgetUsage = 0;

  String budgetStatus = '';
  String recommendation = '';
  String categoryAdvice = '';
  String topCategory = '';

  @override
  void initState() {
    super.initState();

    fetchAnalytics();
    loadReports();
  }

  Future<void> fetchAnalytics() async {
    try {
      final response = await ApiService.getExpenses();

      final goalAnalytics = await ApiService.getGoalAnalytics();

      final financialInsights = await ApiService.getFinancialInsights();

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

        budgetAmount =
            double.tryParse(financialInsights['budget'].toString()) ?? 0;

        budgetSpent =
            double.tryParse(financialInsights['spent'].toString()) ?? 0;

        budgetRemaining =
            double.tryParse(financialInsights['remaining'].toString()) ?? 0;

        budgetUsage =
            double.tryParse(financialInsights['usage_percentage'].toString()) ??
            0;

        budgetStatus = financialInsights['status'] ?? '';
        recommendation = financialInsights['recommendation'] ?? '';
        categoryAdvice = financialInsights['category_advice'] ?? '';
        topCategory = financialInsights['top_category'] ?? '';

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

  Future<void> shareExistingReport(String path) async {
    final file = File(path);

    if (await file.exists()) {
      await ExportService.shareFile(file);
    } else {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Report file no longer exists')),
      );
    }
  }

  Future<void> previewReport(Map<String, dynamic> report) async {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Report Details'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Name: ${report['name']}'),
              const SizedBox(height: 10),
              Text('Created: ${report['created_at']}'),
              const SizedBox(height: 10),
              Text(
                'Path: ${report['path']}',
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Future<void> loadReports() async {
    reports = await ReportHistoryService.getReports();

    if (!mounted) return;

    setState(() {});
  }

  Future<void> deleteReport(int index) async {
    final reportsList = await ReportHistoryService.getReports();

    reportsList.removeAt(index);

    await ReportHistoryService.saveReportsList(reportsList);

    await loadReports();
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

  Widget buildRecommendationCard() {
    Color cardColor;

    if (budgetStatus == 'overspent') {
      cardColor = Colors.red;
    } else if (budgetStatus == 'warning') {
      cardColor = Colors.orange;
    } else {
      cardColor = Colors.green;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),

      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          Row(
            children: [
              Icon(
                budgetStatus == 'overspent'
                    ? Icons.warning
                    : budgetStatus == 'warning'
                    ? Icons.error_outline
                    : Icons.check_circle,
                color: Colors.white,
              ),

              const SizedBox(width: 10),

              const Text(
                'Smart Recommendation',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          Text(
            recommendation,
            style: const TextStyle(color: Colors.white, fontSize: 16),
          ),

          const SizedBox(height: 15),

          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.pie_chart, color: Colors.white),

                const SizedBox(width: 10),

                Expanded(
                  child: Text(
                    'Top Spending Category: $topCategory',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          Text(categoryAdvice, style: const TextStyle(color: Colors.white70)),

          const SizedBox(height: 15),

          LinearProgressIndicator(
            value: (budgetUsage / 100).clamp(0.0, 1.0),
            minHeight: 10,
          ),

          const SizedBox(height: 10),

          Text(
            '${budgetUsage.toStringAsFixed(1)}% of budget used',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final colorScheme = theme.colorScheme;

    final screenHeight = MediaQuery.of(context).size.height;

    final sectionSpacing = screenHeight * .035;
    super.build(context);
    return isLoading
        ? const LoadingWidget()
        : RefreshIndicator(
            onRefresh: fetchAnalytics,
            child: SingleChildScrollView(
              key: const PageStorageKey("analytics"),
              padding: const EdgeInsets.all(20),

              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,

                children: [
                  Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(22),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Analytics Overview",
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          const SizedBox(height: 6),

                          Text(
                            "Track your spending and financial progress",
                            style: TextStyle(color: Colors.grey.shade600),
                          ),

                          const SizedBox(height: 22),

                          Text(
                            "KES ${totalSpending.toStringAsFixed(2)}",
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          const SizedBox(height: 6),

                          Text(
                            "Total Spending",
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    ),
                  ),

                  SizedBox(height: sectionSpacing),

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

                  SizedBox(height: sectionSpacing),

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

                        const Icon(
                          Icons.health_and_safety,
                          color: Colors.white,
                          size: 40,
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

                  const SizedBox(height: 20),

                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.picture_as_pdf),
                          label: const Text('Export PDF'),

                          onPressed: () async {
                            final file = await ExportService.exportExpensesPdf(
                              expenses,
                            );
                            await ReportHistoryService.saveReport(
                              name: file.path.split('/').last,
                              path: file.path,
                            );

                            await loadReports();

                            await ExportService.shareFile(file);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'PDF report exported successfully',
                                  ),
                                ),
                              );
                            }
                          },
                        ),
                      ),

                      const SizedBox(width: 12),

                      Expanded(
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.table_chart),
                          label: const Text('Export CSV'),

                          onPressed: () async {
                            final file = await ExportService.exportExpensesCsv(
                              expenses,
                            );

                            await ReportHistoryService.saveReport(
                              name: file.path.split('/').last,
                              path: file.path,
                            );
                            await loadReports();

                            await ExportService.shareFile(file);

                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'CSV report exported successfully',
                                  ),
                                ),
                              );
                            }
                          },
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  buildRecommendationCard(),

                  SizedBox(height: sectionSpacing),

                  Card(
                    elevation: 0,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 14,
                      ),
                      child: Text(
                        "Category Breakdown",
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
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
                  SizedBox(height: sectionSpacing * 1.2),

                  Card(
                    elevation: 0,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 14,
                      ),
                      child: Text(
                        "Goal Status",
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
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

                  SizedBox(height: sectionSpacing * 1.2),

                  Card(
                    elevation: 0,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 14,
                      ),
                      child: Text(
                        "Monthly Spending Trend",
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
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

                  SizedBox(height: sectionSpacing * 1.2),

                  Card(
                    elevation: 0,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 14,
                      ),
                      child: Text(
                        "Smart Insights",
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  ...insights.map(
                    (insight) => Card(
                      child: ListTile(
                        leading: const Icon(
                          Icons.lightbulb,
                          color: Colors.amber,
                        ),
                        title: Text(insight),
                      ),
                    ),
                  ),

                  SizedBox(height: sectionSpacing * 1.2),

                  Card(
                    elevation: 0,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 14,
                      ),
                      child: Text(
                        "Reports Center",
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  Text(
                    '${reports.length} Reports Generated',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),

                  const SizedBox(height: 15),

                  reports.isEmpty
                      ? const Card(
                          child: Padding(
                            padding: EdgeInsets.all(20),
                            child: Center(
                              child: Text('No reports generated yet'),
                            ),
                          ),
                        )
                      : Card(
                          child: Column(
                            children: reports.asMap().entries.map((entry) {
                              final index = entry.key;
                              final report = entry.value;
                              return ListTile(
                                leading: Icon(
                                  report['name']
                                          .toString()
                                          .toLowerCase()
                                          .endsWith('.pdf')
                                      ? Icons.picture_as_pdf
                                      : Icons.table_chart,
                                ),

                                title: Text(report['name']),

                                subtitle: Text(
                                  report['created_at'].toString().substring(
                                    0,
                                    10,
                                  ),
                                ),

                                onTap: () => previewReport(report),

                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.share),
                                      onPressed: () =>
                                          shareExistingReport(report['path']),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete),
                                      onPressed: () => deleteReport(index),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                        ),

                  ElevatedButton.icon(
                    onPressed: () async {
                      await ReportHistoryService.clearReports();

                      await loadReports();
                    },

                    icon: const Icon(Icons.delete),

                    label: const Text('Clear Report History'),
                  ),
                ],
              ),
            ),
          );
  }
}
