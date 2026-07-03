import 'package:flutter/material.dart';
import '../widgets/dashboard_card.dart';
import '../widgets/loading_widget.dart';
import '../services/api_services.dart';
import '../screens/add_expense_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool isLoading = true;

  int totalExpenses = 0;
  int totalCount = 0;
  int totalCategories = 0;

  @override
  void initState() {
    super.initState();
    loadDashboardData();
  }

  Future<void> loadDashboardData() async {
    try {
      final data = await ApiService.getDashboardSummary();

      setState(() {
        totalExpenses =
            double.tryParse(data['total_expenses'].toString())?.toInt() ?? 0;

        totalCount = int.tryParse(data['total_count'].toString()) ?? 0;

        totalCategories = int.tryParse(data['categories'].toString()) ?? 0;

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
  Widget build(BuildContext context) {
    if (isLoading) {
      return const LoadingWidget();
    }

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(20),

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
                  style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
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
                          Icon(Icons.insights, size: 16, color: Colors.green),

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
                  child: DashboardCard(
                    title: 'Expenses',
                    value: totalCount.toString(),
                    icon: Icons.account_balance_wallet,
                  ),
                ),

                const SizedBox(width: 15),

                Expanded(
                  child: DashboardCard(
                    title: 'Budget',
                    value: 'KES $totalExpenses',
                    icon: Icons.savings,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            Row(
              children: [
                Expanded(
                  child: DashboardCard(
                    title: 'Categories',
                    value: totalCategories.toString(),
                    icon: Icons.category,
                  ),
                ),

                const SizedBox(width: 15),

                Expanded(
                  child: DashboardCard(
                    title: 'Reports',
                    value: totalCount.toString(),
                    icon: Icons.bar_chart,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 30),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AddExpenseScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.add),
                label: const Text('Add Expense'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
