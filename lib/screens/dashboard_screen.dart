import 'package:flutter/material.dart';

import 'package:pesapulse_mobile/screens/expense_screen.dart';
import '../widgets/dashboard_card.dart';
import '../widgets/dashboard_loading_skeleton.dart';
import '../widgets/quick_action_card.dart';
import '../widgets/recent_expense_tile.dart';

import '../services/api_services.dart';
import '../screens/add_expense_screen.dart';
import '../screens/add_goals_screen.dart';
import '../screens/budget_page.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with AutomaticKeepAliveClientMixin {
  bool isLoading = true;

  int totalExpenses = 0;
  int totalCount = 0;
  int totalCategories = 0;

  List recentExpenses = [];
  double opacity = 0;

  @override
  void initState() {
    super.initState();
    loadDashboardData();

    Future.delayed(const Duration(milliseconds: 150), () {
      if (!mounted) return;

      setState(() {
        opacity = 1;
      });
    });
  }

  Future<void> loadDashboardData() async {
    try {
      final data = await ApiService.getDashboard();
      final summary = data['summary'];

      setState(() {
        totalExpenses =
            double.tryParse(summary['total_expenses'].toString())?.toInt() ?? 0;

        totalCount = int.tryParse(summary['total_count'].toString()) ?? 0;

        totalCategories = int.tryParse(summary['categories'].toString()) ?? 0;

        recentExpenses = List<Map<String, dynamic>>.from(
          data['recent_expenses'],
        );

        isLoading = false;
      });
    } catch (e) {
      print(e);

      setState(() {
        isLoading = false;
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  String getGreeting() {
    final hour = DateTime.now().hour;

    if (hour < 12) {
      return "Good Morning";
    } else if (hour < 17) {
      return "Good Afternoon";
    } else {
      return "Good Evening";
    }
  }

  String getFormattedDate() {
    final now = DateTime.now();

    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];

    return "${now.day} ${months[now.month - 1]}, ${now.year}";
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final cardHeight = MediaQuery.of(context).size.height * 0.22;
    if (isLoading) {
      return const DashboardLoadingSkeleton();
    }

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          await loadDashboardData();
        },

        child: SingleChildScrollView(
          key: const PageStorageKey("dashboard"),
          child: Padding(
            padding: const EdgeInsets.all(20),

            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 500),
              opacity: opacity,

              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,

                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "${getGreeting()} 👋",
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                          fontWeight: FontWeight.w500,
                        ),
                      ),

                      const SizedBox(height: 6),

                      const Text(
                        "Welcome Back",
                        style: TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 10),

                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),

                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(.12),
                              borderRadius: BorderRadius.circular(30),
                            ),

                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.insights,
                                  size: 16,
                                  color: Colors.green,
                                ),

                                SizedBox(width: 6),

                                Text(
                                  "Today's Overview",
                                  style: TextStyle(
                                    color: Colors.green,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const Spacer(),

                          Text(
                            getFormattedDate(),
                            style: const TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 30),

                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: cardHeight,
                          child: DashboardCard(
                            title: "Expenses",
                            subtitle: "Total Recorded",
                            value: totalCount.toString(),
                            icon: Icons.account_balance_wallet,
                            iconColor: Colors.green,
                          ),
                        ),
                      ),

                      const SizedBox(width: 15),

                      Expanded(
                        child: SizedBox(
                          height: cardHeight,
                          child: DashboardCard(
                            title: 'Budget',
                            subtitle: "Current Budget",
                            value: 'KES $totalExpenses',
                            icon: Icons.savings,
                            iconColor: Colors.blue,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: cardHeight,
                          child: DashboardCard(
                            title: 'Categories',
                            subtitle: "Expense Types",
                            value: totalCategories.toString(),
                            icon: Icons.category,
                            iconColor: Colors.orange,
                          ),
                        ),
                      ),

                      const SizedBox(width: 15),

                      Expanded(
                        child: SizedBox(
                          height: cardHeight,
                          child: DashboardCard(
                            title: 'Reports',
                            subtitle: "Generated",
                            value: totalCount.toString(),
                            icon: Icons.bar_chart,
                            iconColor: Colors.purple,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 30),

                  const Text(
                    "Quick Actions",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),

                  const SizedBox(height: 15),

                  Row(
                    children: [
                      QuickActionCard(
                        icon: Icons.add,
                        title: "Expense",
                        color: Colors.green,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const AddExpenseScreen(),
                            ),
                          );
                        },
                      ),

                      const SizedBox(width: 12),

                      QuickActionCard(
                        icon: Icons.account_balance_wallet,
                        title: "Budget",
                        color: Colors.blue,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const BudgetPage(),
                            ),
                          );
                        },
                      ),

                      const SizedBox(width: 12),

                      QuickActionCard(
                        icon: Icons.flag,
                        title: "Goal",
                        color: Colors.orange,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const AddGoalScreen(),
                            ),
                          );
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 30),

                  Row(
                    children: [
                      const Text(
                        "Recent Expenses",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const Spacer(),

                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const ExpenseScreen(),
                            ),
                          );
                        },
                        child: const Text("View All"),
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          if (recentExpenses.isEmpty)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 35),
                              child: Column(
                                children: const [
                                  Icon(
                                    Icons.receipt_long,
                                    size: 48,
                                    color: Colors.grey,
                                  ),

                                  SizedBox(height: 15),

                                  Text(
                                    "No expenses yet",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),

                                  SizedBox(height: 6),

                                  Text(
                                    "Start tracking your spending by adding your first expense.",
                                    textAlign: TextAlign.center,
                                    style: TextStyle(color: Colors.grey),
                                  ),
                                ],
                              ),
                            )
                          else
                            ...recentExpenses.map(
                              (expense) => Column(
                                children: [
                                  RecentExpenseTile(expense: expense),

                                  if (expense != recentExpenses.last)
                                    const Divider(),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
