import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:pesapulse_mobile/screens/add_goals_screen.dart';
import 'add_expense_screen.dart';
import 'login_screen.dart';
import 'register_screen.dart';
import 'budget_page.dart';
import 'package:pesapulse_mobile/widgets/sync_status_icon.dart';
import 'package:provider/provider.dart';
import '../providers/connectivity_provider.dart';
import '../widgets/analytics_loading_skeleton.dart';
import '../widgets/analytics_section_header.dart';
import '../widgets/fade_slide_animation.dart';
import '../widgets/empty_state_helper.dart';

import '../services/export_service.dart';
import '../services/report_history_service.dart';
import '../services/guest_dialog_service.dart';
import '../services/session_service.dart';
import '../repositories/analytics_repository.dart';

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

  bool isGuest = false;

  final AnalyticsRepository analyticsRepository = AnalyticsRepository();
  late ConnectivityProvider _network;

  @override
  void initState() {
    super.initState();
    loadSessionState();
    _network = context.read<ConnectivityProvider>();

    _network.addListener(_onConnectivityChanged);

    _fetchCachedAnalytics();

    loadReports();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshAnalytics();
    });
  }

  Future<void> loadSessionState() async {
    isGuest = await SessionService.isGuest();

    if (mounted) {
      setState(() {});
    }
  }

  void _onConnectivityChanged() {
    if (_network.isOnline) {
      _refreshAnalytics();
    }
  }

  @override
  void dispose() {
    _network.removeListener(_onConnectivityChanged);

    super.dispose();
  }

  Future<void> _fetchCachedAnalytics() async {
    try {
      final analytics = await analyticsRepository.getAnalytics();

      final response = analytics["expenses"];
      final goalAnalytics = analytics["goalAnalytics"];
      final financialInsights = analytics["financialInsights"];

      _applyAnalytics(response["data"] ?? [], goalAnalytics, financialInsights);
    } catch (_) {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _refreshAnalytics() async {
    try {
      final analytics = await analyticsRepository.getAnalytics();

      _applyAnalytics(
        analytics["expenses"]["data"] ?? [],
        analytics["goalAnalytics"],
        analytics["financialInsights"],
      );
    } catch (_) {}
  }

  Future<void> refreshAnalytics() async {
    if (!mounted) return;

    final network = context.read<ConnectivityProvider>();

    if (!network.isOnline) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("You're offline. Showing cached analytics."),
        ),
      );

      await _fetchCachedAnalytics();
      return;
    }

    await _refreshAnalytics();
  }

  void _applyAnalytics(
    List data,
    Map<String, dynamic> goalAnalytics,
    Map<String, dynamic> financialInsights,
  ) {
    double total = 0;

    final Map<String, double> categories = {};

    final Map<int, double> monthlyData = {};

    for (final expense in data) {
      final amount = double.tryParse(expense["amount"].toString()) ?? 0;

      final category = expense["category"] ?? "Other";

      total += amount;

      final date = DateTime.parse(expense["created_at"]);

      monthlyData[date.month] = (monthlyData[date.month] ?? 0) + amount;

      categories[category] = (categories[category] ?? 0) + amount;
    }

    setState(() {
      expenses = data;

      totalSpending = total;

      categoryTotals = categories;

      monthlyTotals = monthlyData;

      totalGoals = int.tryParse(goalAnalytics["total_goals"].toString()) ?? 0;

      completedGoals =
          int.tryParse(goalAnalytics["completed_goals"].toString()) ?? 0;

      activeGoals = int.tryParse(goalAnalytics["active_goals"].toString()) ?? 0;

      completionRate =
          double.tryParse(goalAnalytics["completion_rate"].toString()) ?? 0;

      budgetAmount =
          double.tryParse(financialInsights["budget"].toString()) ?? 0;

      budgetSpent = double.tryParse(financialInsights["spent"].toString()) ?? 0;

      budgetRemaining =
          double.tryParse(financialInsights["remaining"].toString()) ?? 0;

      budgetUsage =
          double.tryParse(financialInsights["usage_percentage"].toString()) ??
          0;

      budgetStatus = financialInsights["status"] ?? "";

      recommendation = financialInsights["recommendation"] ?? "";

      categoryAdvice = financialInsights["category_advice"] ?? "";

      topCategory = financialInsights["top_category"] ?? "";

      categoryTotals.clear();

      if (financialInsights["category_breakdown"] != null) {
        for (final item in financialInsights["category_breakdown"]) {
          categoryTotals[item["category"]] = (item["total"] as num).toDouble();
        }
      }

      calculateHealthScore();

      generateInsights();

      isLoading = false;
    });
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

  Widget buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: color.withOpacity(.12),
              child: Icon(icon, color: color, size: 26),
            ),

            const SizedBox(height: 16),

            Text(
              value,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 6),

            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color getRecommendationColor() {
    switch (budgetStatus.toLowerCase()) {
      case "healthy":
        return Colors.green;

      case "warning":
        return Colors.orange;

      case "overspent":
        return Colors.deepOrange;

      case "critical":
        return Colors.red;

      default:
        return Theme.of(context).colorScheme.primary;
    }
  }

  IconData getRecommendationIcon() {
    switch (budgetStatus) {
      case 'critical':
        return Icons.warning_rounded;

      case 'overspent':
        return Icons.error_outline;

      case 'warning':
        return Icons.info_outline;

      default:
        return Icons.check_circle;
    }
  }

  Widget buildRecommendationCard() {
    final cardColor = getRecommendationColor();

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
              CircleAvatar(
                radius: 20,
                backgroundColor: Colors.white24,
                child: Icon(getRecommendationIcon(), color: Colors.white),
              ),

              const SizedBox(width: 14),

              const Expanded(
                child: Text(
                  "Smart Recommendation",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              budgetStatus.toUpperCase(),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
          ),

          const SizedBox(height: 10),

          Text(
            recommendation,
            style: const TextStyle(color: Colors.white, fontSize: 16),
          ),

          const SizedBox(height: 15),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(.15),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: Colors.white24,
                  child: const Icon(Icons.pie_chart, color: Colors.white),
                ),

                const SizedBox(width: 14),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Top Spending Category",
                        style: TextStyle(color: Colors.white70, fontSize: 13),
                      ),

                      const SizedBox(height: 4),

                      Text(
                        topCategory,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          Container(
            margin: const EdgeInsets.only(top: 14),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(.10),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.tips_and_updates, color: Colors.white),

                const SizedBox(width: 12),

                Expanded(
                  child: Text(
                    categoryAdvice,
                    style: const TextStyle(color: Colors.white, height: 1.4),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 15),

          TweenAnimationBuilder<double>(
            duration: const Duration(milliseconds: 900),
            tween: Tween(begin: 0, end: (budgetUsage / 100).clamp(0.0, 1.0)),
            builder: (context, value, child) {
              return ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: LinearProgressIndicator(
                  value: value,
                  minHeight: 10,
                  backgroundColor: Colors.white24,
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              );
            },
          ),
          const SizedBox(height: 20),

          TweenAnimationBuilder<double>(
            duration: const Duration(milliseconds: 900),
            tween: Tween(begin: 0, end: budgetUsage),
            builder: (context, value, child) {
              return RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: "${value.toStringAsFixed(1)}%",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const TextSpan(
                      text: " of budget used",
                      style: TextStyle(color: Colors.white70, fontSize: 15),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Color getFinancialHealthColor() {
    switch (healthStatus.toLowerCase()) {
      case "excellent":
        return Colors.green;

      case "good":
        return Colors.lightGreen;

      case "fair":
        return Colors.orange;

      case "poor":
        return Colors.deepOrange;

      case "critical":
        return Colors.red;

      default:
        return Theme.of(context).colorScheme.primary;
    }
  }

  IconData getFinancialHealthIcon() {
    switch (healthStatus.toLowerCase()) {
      case "excellent":
        return Icons.sentiment_very_satisfied;

      case "good":
        return Icons.sentiment_satisfied;

      case "fair":
        return Icons.sentiment_neutral;

      case "poor":
        return Icons.sentiment_dissatisfied;

      case "critical":
        return Icons.warning_rounded;

      default:
        return Icons.favorite;
    }
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final theme = Theme.of(context);

    final screenHeight = MediaQuery.of(context).size.height;

    final sectionSpacing = screenHeight * .035;

    final screenSize = MediaQuery.of(context).size;

    final isLandscape = screenSize.width > screenSize.height;

    final chartHeight = isLandscape
        ? screenSize.height * .55
        : screenSize.height * .32;

    const double cardSpacing = 24;
    const double internalSpacing = 16;

    if (isLoading) {
      return const AnalyticsLoadingSkeleton();
    }

    final hasNoData = expenses.isEmpty && totalGoals == 0 && reports.isEmpty;

    if (hasNoData) {
      return buildEmptyState(
        context,
        EmptyStateType.analytics,
        isGuest: isGuest, // guest awareness
        // Override the default "Get Started" action to show your custom dialog
        showCreateBudgetDialog: () {
          showGeneralDialog(
            context: context,
            barrierDismissible: true,
            barrierLabel: "Get Started",
            transitionDuration: const Duration(milliseconds: 400),
            pageBuilder: (context, animation, secondaryAnimation) {
              return Center(
                child: AlertDialog(
                  title: const Text("Get Started"),
                  content: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Expense option
                        ListTile(
                          leading: CircleAvatar(
                            radius: 20,
                            backgroundColor: Colors.green.shade100,
                            child: const Icon(
                              Icons.receipt_long,
                              color: Colors.green,
                            ),
                          ),
                          title: const Text("Add Expense"),
                          subtitle: const Text(
                            "Track your spending and daily costs",
                          ),
                          trailing: const Icon(
                            Icons.arrow_forward_ios,
                            size: 18,
                          ),
                          onTap: () {
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const AddExpenseScreen(),
                              ),
                            );
                          },
                        ),
                        const Divider(),

                        // Goal option
                        ListTile(
                          leading: CircleAvatar(
                            radius: 20,
                            backgroundColor: Colors.orange.shade100,
                            child: const Icon(Icons.flag, color: Colors.orange),
                          ),
                          title: const Text("Add Goal"),
                          subtitle: const Text(
                            "Save towards your financial goals",
                          ),
                          trailing: const Icon(
                            Icons.arrow_forward_ios,
                            size: 18,
                          ),
                          onTap: () {
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const AddGoalScreen(),
                              ),
                            );
                          },
                        ),
                        const Divider(),

                        // Budget option
                        ListTile(
                          leading: CircleAvatar(
                            radius: 20,
                            backgroundColor: Colors.blue.shade100,
                            child: const Icon(
                              Icons.account_balance_wallet,
                              color: Colors.blue,
                            ),
                          ),
                          title: const Text("Add Budget"),
                          subtitle: Text(
                            isGuest
                                ? "Create an account to manage budgets"
                                : "Plan and manage your monthly budget",
                          ),
                          trailing: const Icon(
                            Icons.arrow_forward_ios,
                            size: 18,
                          ),
                          enabled: !isGuest,
                          onTap: isGuest
                              ? null
                              : () {
                                  Navigator.pop(context);
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const BudgetPage(),
                                    ),
                                  );
                                },
                        ),

                        // Guest account options
                        if (isGuest) ...[
                          const SizedBox(height: 20),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              "Account Options",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.grey.shade700,
                              ),
                            ),
                          ),
                          const Divider(),

                          ListTile(
                            leading: CircleAvatar(
                              radius: 20,
                              backgroundColor: Colors.orange.shade500,
                              child: const Icon(
                                Icons.person_add_alt_1,
                                color: Colors.white,
                              ),
                            ),
                            title: const Text("Create Account"),
                            subtitle: const Text(
                              "Sync your data across devices",
                            ),
                            trailing: const Icon(
                              Icons.arrow_forward_ios,
                              size: 18,
                            ),
                            onTap: () {
                              Navigator.pop(context);
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const RegisterScreen(),
                                ),
                              );
                            },
                          ),
                          const Divider(),
                          ListTile(
                            leading: CircleAvatar(
                              radius: 20,
                              backgroundColor: Colors.blue.shade100,
                              child: const Icon(
                                Icons.login,
                                color: Colors.blue,
                              ),
                            ),
                            title: const Text("Sign In"),
                            subtitle: const Text("Already have an account?"),
                            trailing: const Icon(
                              Icons.arrow_forward_ios,
                              size: 18,
                            ),
                            onTap: () {
                              Navigator.pop(context);
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const LoginScreen(),
                                ),
                              );
                            },
                          ),
                        ],
                      ],
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text("Close"),
                    ),
                  ],
                ),
              );
            },
            transitionBuilder: (context, animation, secondaryAnimation, child) {
              final curved = CurvedAnimation(
                parent: animation,
                curve: Curves.easeOut,
              );
              return FadeTransition(
                opacity: curved,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.2),
                    end: Offset.zero,
                  ).animate(curved),
                  child: child,
                ),
              );
            },
          );
        },
      );
    }

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: refreshAnalytics,
        child: SingleChildScrollView(
          key: const PageStorageKey("analytics"),

          padding: const EdgeInsets.all(20),

          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,

            children: [
              TweenAnimationBuilder<double>(
                duration: const Duration(milliseconds: 500),
                tween: Tween(begin: .95, end: 1),

                builder: (_, value, child) {
                  return Transform.scale(scale: value, child: child);
                },

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
                        Text(
                          "Analytics Overview",
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SyncStatusIcon(),

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
              ),

              SizedBox(height: sectionSpacing),

              Row(
                children: [
                  Expanded(
                    child: buildStatCard(
                      'Goals',
                      totalGoals.toString(),
                      Icons.flag,
                      Colors.indigo,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: buildStatCard(
                      'Completed',
                      completedGoals.toString(),
                      Icons.emoji_events,
                      Colors.green,
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
                      Colors.orange,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: buildStatCard(
                      'Rate',
                      '${completionRate.toStringAsFixed(0)}%',
                      Icons.trending_up,
                      Colors.blue,
                    ),
                  ),
                ],
              ),

              SizedBox(height: sectionSpacing),

              FadeSlideAnimation(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(22),

                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),

                    color: getFinancialHealthColor(),
                  ),

                  child: Column(
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 22,
                            backgroundColor: Colors.white.withOpacity(.2),
                            child: Icon(
                              getFinancialHealthIcon(),
                              color: Colors.white,
                              size: 40,
                            ),
                          ),

                          const SizedBox(width: 12),

                          const Expanded(
                            child: Text(
                              "Financial Health",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      TweenAnimationBuilder<double>(
                        duration: const Duration(milliseconds: 900),
                        tween: Tween(begin: 0, end: healthScore),
                        builder: (context, value, child) {
                          return Text(
                            '${value.toStringAsFixed(0)}/100',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 42,
                              fontWeight: FontWeight.bold,
                            ),
                          );
                        },
                      ),

                      const SizedBox(height: 5),

                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(.18),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          healthStatus,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),

                      const SizedBox(height: cardSpacing),

                      Text(
                        recommendation,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          height: 1.4,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: cardSpacing),
              if (isGuest)
                Card(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () async {
                      await GuestDialogService.requireAccount(context);
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: Colors.orange.shade100,
                            child: const Icon(
                              Icons.picture_as_pdf,
                              color: Colors.orange,
                            ),
                          ),
                          const SizedBox(width: 14),

                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: const [
                                Text(
                                  "Export Reports",
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  "Create an account to export PDF and CSV reports.",
                                ),
                              ],
                            ),
                          ),

                          const Icon(Icons.arrow_forward_ios, size: 18),
                        ],
                      ),
                    ),
                  ),
                )
              else
                FadeSlideAnimation(
                  delay: 400,
                  child: Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.picture_as_pdf),
                          label: const Text('Export PDF'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                          ),

                          onPressed: () async {
                            await GuestDialogService.requireAccount(context);
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
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.teal,
                            foregroundColor: Colors.white,
                          ),

                          onPressed: () async {
                            await GuestDialogService.requireAccount(context);
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
                ),

              SizedBox(height: (screenSize.height * .02).clamp(16.0, 24.0)),

              FadeSlideAnimation(delay: 100, child: buildRecommendationCard()),

              SizedBox(height: sectionSpacing),

              const AnalyticsSectionHeader(
                icon: Icons.pie_chart,
                title: "Category Breakdown",
              ),

              SizedBox(height: (screenSize.height * .02).clamp(16.0, 24.0)),

              categoryTotals.isEmpty
                  ? buildEmptyState(
                      context,
                      EmptyStateType.categories,
                      isGuest: isGuest, // optional, if you want guest awareness
                    )
                  : Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: Padding(
                        padding: EdgeInsets.all(
                          (screenSize.width * .045).clamp(16.0, 24.0),
                        ),
                        child: SizedBox(
                          height: chartHeight,
                          child: PieChart(
                            PieChartData(
                              sections: getSections(),
                              centerSpaceRadius: chartHeight * .15,
                              sectionsSpace: 4,
                            ),
                          ),
                        ),
                      ),
                    ),
              SizedBox(height: sectionSpacing * 1.2),

              const AnalyticsSectionHeader(
                icon: Icons.flag,
                title: "Goal Status",
              ),
              SizedBox(height: (screenSize.height * .02).clamp(16.0, 24.0)),

              FadeSlideAnimation(
                delay: 200,

                child: Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(
                      (screenSize.width * .045).clamp(16.0, 24.0),
                    ),
                    child: SizedBox(
                      height: chartHeight,
                      child: PieChart(
                        PieChartData(
                          sections: getGoalSections(),
                          centerSpaceRadius: chartHeight * .15,
                          sectionsSpace: 4,
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              SizedBox(height: sectionSpacing * 1.2),

              const AnalyticsSectionHeader(
                icon: Icons.show_chart,
                title: "Monthly Spending Trend",
              ),

              const SizedBox(height: cardSpacing),

              FadeSlideAnimation(
                delay: 300,

                child: Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(
                      (screenSize.width * .045).clamp(16.0, 24.0),
                    ),
                    child: SizedBox(
                      height: chartHeight,
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
                  ),
                ),
              ),
              SizedBox(height: (screenSize.height * .02).clamp(16.0, 24.0)),

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

              const AnalyticsSectionHeader(
                icon: Icons.lightbulb,
                title: "Smart Insights",
              ),

              SizedBox(height: (screenSize.height * .02).clamp(16.0, 24.0)),

              FadeSlideAnimation(
                delay: 350,
                child: Column(
                  children: [
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
                  ],
                ),
              ),

              SizedBox(height: sectionSpacing * 1.2),

              const AnalyticsSectionHeader(
                icon: Icons.description,
                title: "Reports Center",
              ),

              const SizedBox(height: 10),

              Text(
                '${reports.length} Reports Generated',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: internalSpacing),

              reports.isEmpty
                  ? Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: Padding(
                        padding: EdgeInsets.all(22),
                        child: Center(child: Text('No reports generated yet')),
                      ),
                    )
                  : Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: Column(
                        children: reports.asMap().entries.map((entry) {
                          final index = entry.key;
                          final report = entry.value;
                          return ListTile(
                            leading: Icon(
                              report['name'].toString().toLowerCase().endsWith(
                                    '.pdf',
                                  )
                                  ? Icons.picture_as_pdf
                                  : Icons.table_chart,
                            ),

                            title: Text(report['name']),

                            subtitle: Text(
                              report['created_at'].toString().substring(0, 10),
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
      ),
    );
  }
}
